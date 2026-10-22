import 'dart:io';

import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);
const _agua = Producto(id: 'p3', nombre: 'Agua pura', precio: 8);
const _fantasma = Producto(id: 'no-existe', nombre: 'Fantasma', precio: 1);

DetalleVenta _detalle(Producto p, int cantidad, [double? precio]) =>
    DetalleVenta(
      producto: p,
      cantidad: cantidad,
      precioAlMomento: precio ?? p.precio,
    );

Venta _venta(String id, List<DetalleVenta> detalles, [DateTime? fecha]) =>
    Venta(
      id: id,
      fechaHora: fecha ?? DateTime(2026, 10, 15, 9, 30, 15),
      detalles: detalles,
    );

void main() {
  late Directory carpeta;
  late VentaService ventas;
  late ProductoService productos;

  Future<List<Map<String, Object?>>> filas(String tabla) async {
    final db = await DatabaseService.instance.database;
    return db.query(tabla);
  }

  // Carpeta propia para no compartir cabal.db con otros archivos de test,
  // que se ejecutan en paralelo.
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_venta_service_');
    await databaseFactory.setDatabasesPath(carpeta.path);
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase('${carpeta.path}/cabal.db');

    ventas = VentaService();
    productos = ProductoService();
    await productos.crearProducto(_cola);
    await productos.crearProducto(_pan);
    await productos.crearProducto(_agua);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  group('guardado de una venta con varios productos', () {
    test('guarda la venta y un detalle por producto', () async {
      await ventas.registrarVenta(
        _venta('v1', [
          _detalle(_cola, 2),
          _detalle(_pan, 3),
          _detalle(_agua, 1),
        ]),
      );

      final filasVenta = await filas('venta');
      expect(filasVenta, hasLength(1));
      expect(filasVenta.first['id'], 'v1');
      expect(filasVenta.first['fecha_hora'], '2026-10-15T09:30:15.000');

      final db = await DatabaseService.instance.database;
      final detalles = await db.query('detalle_venta', orderBy: 'producto_id');
      expect(detalles, hasLength(3));
      expect(
        detalles.map((d) => d['venta_id']).toSet(),
        {'v1'},
        reason: 'todos los detalles pertenecen a la venta',
      );
      expect(detalles[0]['producto_id'], 'p1');
      expect(detalles[0]['cantidad'], 2);
      expect(detalles[0]['precio_al_momento'], 10.5);
      expect(detalles[1]['producto_id'], 'p2');
      expect(detalles[1]['cantidad'], 3);
      expect(detalles[1]['precio_al_momento'], 2.5);
      expect(detalles[2]['producto_id'], 'p3');
      expect(detalles[2]['cantidad'], 1);
      expect(detalles[2]['precio_al_momento'], 8.0);
    });

    test('varias ventas se guardan sin mezclar sus detalles', () async {
      await ventas.registrarVenta(_venta('v1', [_detalle(_cola, 1)]));
      await ventas.registrarVenta(
        _venta('v2', [_detalle(_cola, 4), _detalle(_pan, 2)]),
      );

      expect(await filas('venta'), hasLength(2));
      expect(await filas('detalle_venta'), hasLength(3));

      final v1 = await ventas.obtenerVenta('v1');
      final v2 = await ventas.obtenerVenta('v2');
      expect(v1!.detalles, hasLength(1));
      expect(v1.detalles.first.cantidad, 1);
      expect(v2!.detalles, hasLength(2));
    });
  });

  group('precio al momento de la venta', () {
    test('se conserva aunque cambie el precio en el catálogo', () async {
      await ventas.registrarVenta(_venta('v1', [_detalle(_cola, 2)]));

      await productos.actualizarProducto(_cola.copyWith(precio: 15));

      final venta = await ventas.obtenerVenta('v1');
      final detalle = venta!.detalles.single;
      expect(detalle.precioAlMomento, 10.5);
      expect(
        detalle.producto.precio,
        15.0,
        reason: 'el producto refleja el precio actual del catálogo',
      );

      final db = await DatabaseService.instance.database;
      final guardado = await db.query('detalle_venta');
      expect(guardado.single['precio_al_momento'], 10.5);
    });

    test(
      'una venta nueva usa el precio vigente y la anterior no cambia',
      () async {
        await ventas.registrarVenta(_venta('v1', [_detalle(_cola, 1)]));

        final nueva = _cola.copyWith(precio: 12);
        await productos.actualizarProducto(nueva);
        await ventas.registrarVenta(_venta('v2', [_detalle(nueva, 1)]));

        final v1 = await ventas.obtenerVenta('v1');
        final v2 = await ventas.obtenerVenta('v2');
        expect(v1!.detalles.single.precioAlMomento, 10.5);
        expect(v2!.detalles.single.precioAlMomento, 12.0);
      },
    );
  });

  group('un guardado fallido no deja datos incompletos', () {
    test('producto inexistente: no queda venta ni detalles', () async {
      final venta = _venta('v1', [_detalle(_cola, 1), _detalle(_fantasma, 1)]);

      await expectLater(ventas.registrarVenta(venta), throwsA(anything));

      expect(await filas('venta'), isEmpty);
      expect(await filas('detalle_venta'), isEmpty);
    });

    test('producto repetido en la venta: se revierte todo', () async {
      final venta = _venta('v1', [
        _detalle(_cola, 1),
        _detalle(_pan, 1),
        _detalle(_cola, 2),
      ]);

      await expectLater(ventas.registrarVenta(venta), throwsA(anything));

      expect(await filas('venta'), isEmpty);
      expect(await filas('detalle_venta'), isEmpty);
    });

    test('id de venta repetido: la venta original queda intacta', () async {
      await ventas.registrarVenta(_venta('v1', [_detalle(_cola, 2)]));

      await expectLater(
        ventas.registrarVenta(_venta('v1', [_detalle(_pan, 5)])),
        throwsA(anything),
      );

      expect(await filas('venta'), hasLength(1));
      final detalles = await filas('detalle_venta');
      expect(detalles, hasLength(1));
      expect(detalles.single['producto_id'], 'p1');
      expect(detalles.single['cantidad'], 2);
    });

    test('un fallo no impide registrar la siguiente venta', () async {
      await expectLater(
        ventas.registrarVenta(_venta('v1', [_detalle(_fantasma, 1)])),
        throwsA(anything),
      );

      await ventas.registrarVenta(_venta('v2', [_detalle(_cola, 1)]));

      expect(await filas('venta'), hasLength(1));
      expect(await ventas.obtenerVenta('v2'), isNotNull);
    });
  });

  group('recuperación de ventas', () {
    test('obtenerVenta devuelve la venta completa', () async {
      final fecha = DateTime(2026, 10, 15, 18, 45, 5);
      await ventas.registrarVenta(
        _venta('v1', [_detalle(_cola, 2), _detalle(_pan, 3)], fecha),
      );

      final venta = await ventas.obtenerVenta('v1');

      expect(venta, isNotNull);
      expect(venta!.id, 'v1');
      expect(venta.fechaHora, fecha);
      expect(venta.detalles, hasLength(2));

      final cola = venta.detalles.firstWhere((d) => d.producto.id == 'p1');
      expect(cola.producto.nombre, 'Coca Cola');
      expect(cola.cantidad, 2);
      expect(cola.precioAlMomento, 10.5);
    });

    test('obtenerVenta devuelve null si la venta no existe', () async {
      expect(await ventas.obtenerVenta('inexistente'), isNull);
    });

    test('la venta se recupera tras cerrar y reabrir la base', () async {
      await ventas.registrarVenta(
        _venta('v1', [_detalle(_cola, 2), _detalle(_pan, 3)]),
      );

      await DatabaseService.instance.close();

      final venta = await VentaService().obtenerVenta('v1');
      expect(venta, isNotNull);
      expect(venta!.detalles, hasLength(2));
      expect(venta.detalles.fold<int>(0, (suma, d) => suma + d.cantidad), 5);
    });
  });
}
