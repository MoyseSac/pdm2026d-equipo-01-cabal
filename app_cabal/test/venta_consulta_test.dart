import 'dart:io';

import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/providers/ventas_registradas_provider.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);
const _agua = Producto(id: 'p3', nombre: 'Agua pura', precio: 8);

DetalleVenta _detalle(Producto p, int cantidad) => DetalleVenta(
      producto: p,
      cantidad: cantidad,
      precioAlMomento: p.precio,
    );

Venta _venta(String id, DateTime fecha, List<DetalleVenta> detalles) =>
    Venta(id: id, fechaHora: fecha, detalles: detalles);

void main() {
  late Directory carpeta;
  late VentaService ventas;
  late ProductoService productos;

  // Carpeta propia para no compartir cabal.db con otros archivos de test,
  // que se ejecutan en paralelo.
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_consulta_');
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

  group('obtenerVentas', () {
    test('sin ventas devuelve una lista vacía', () async {
      expect(await ventas.obtenerVentas(), isEmpty);
    });

    test('devuelve las ventas de la más reciente a la más antigua', () async {
      // Se guardan en desorden a propósito.
      await ventas.registrarVenta(
        _venta('v2', DateTime(2026, 10, 15, 10, 0), [_detalle(_pan, 1)]),
      );
      await ventas.registrarVenta(
        _venta('v3', DateTime(2026, 10, 16, 8, 30), [_detalle(_agua, 1)]),
      );
      await ventas.registrarVenta(
        _venta('v1', DateTime(2026, 10, 14, 18, 45), [_detalle(_cola, 1)]),
      );

      final lista = await ventas.obtenerVentas();

      expect(lista.map((v) => v.id), ['v3', 'v2', 'v1']);
    });

    test('cada venta trae su fecha, productos, cantidades y precios',
        () async {
      final fecha = DateTime(2026, 10, 15, 21, 5, 30);
      await ventas.registrarVenta(_venta('v1', fecha, [
        _detalle(_cola, 2),
        _detalle(_pan, 3),
        _detalle(_agua, 1),
      ]));

      final venta = (await ventas.obtenerVentas()).single;

      expect(venta.id, 'v1');
      expect(venta.fechaHora, fecha);
      expect(venta.detalles, hasLength(3));

      DetalleVenta de(String id) =>
          venta.detalles.firstWhere((d) => d.producto.id == id);
      expect(de('p1').producto.nombre, 'Coca Cola');
      expect(de('p1').cantidad, 2);
      expect(de('p1').precioAlMomento, 10.5);
      expect(de('p2').producto.nombre, 'Pan dulce');
      expect(de('p2').cantidad, 3);
      expect(de('p2').precioAlMomento, 2.5);
      expect(de('p3').producto.nombre, 'Agua pura');
      expect(de('p3').cantidad, 1);
      expect(de('p3').precioAlMomento, 8.0);
      expect(totalDe(venta.detalles), 36.5);
    });

    test('los detalles de cada venta no se mezclan con los de otra',
        () async {
      await ventas.registrarVenta(
        _venta('v1', DateTime(2026, 10, 15, 9), [_detalle(_cola, 1)]),
      );
      await ventas.registrarVenta(
        _venta('v2', DateTime(2026, 10, 15, 10), [
          _detalle(_cola, 4),
          _detalle(_pan, 2),
        ]),
      );

      final lista = await ventas.obtenerVentas();
      final v1 = lista.firstWhere((v) => v.id == 'v1');
      final v2 = lista.firstWhere((v) => v.id == 'v2');

      expect(v1.detalles, hasLength(1));
      expect(v1.detalles.single.cantidad, 1);
      expect(v2.detalles, hasLength(2));
      expect(totalDe(v1.detalles), 10.5);
      expect(totalDe(v2.detalles), 47.0);
    });

    test('conserva el precio de la venta aunque cambie el del catálogo',
        () async {
      await ventas.registrarVenta(
        _venta('v1', DateTime(2026, 10, 15, 9), [_detalle(_cola, 2)]),
      );

      await productos.actualizarProducto(_cola.copyWith(precio: 15));

      final detalle = (await ventas.obtenerVentas()).single.detalles.single;
      expect(detalle.precioAlMomento, 10.5);
      expect(totalDe([detalle]), 21.0);
    });

    test('coincide con lo guardado por obtenerVenta', () async {
      await ventas.registrarVenta(_venta(
        'v1',
        DateTime(2026, 10, 15, 9),
        [_detalle(_cola, 2), _detalle(_pan, 3)],
      ));

      final deLista = (await ventas.obtenerVentas()).single;
      final individual = await ventas.obtenerVenta('v1');

      expect(deLista.id, individual!.id);
      expect(deLista.fechaHora, individual.fechaHora);
      expect(deLista.detalles.length, individual.detalles.length);
      expect(totalDe(deLista.detalles), totalDe(individual.detalles));
    });

    test('las ventas siguen disponibles tras cerrar y reabrir la base',
        () async {
      await ventas.registrarVenta(
        _venta('v1', DateTime(2026, 10, 15, 9), [_detalle(_cola, 2)]),
      );
      await ventas.registrarVenta(
        _venta('v2', DateTime(2026, 10, 15, 10), [_detalle(_pan, 3)]),
      );

      await DatabaseService.instance.close();

      final lista = await VentaService().obtenerVentas();
      expect(lista.map((v) => v.id), ['v2', 'v1']);
      expect(totalDe(lista.first.detalles), 7.5);
      expect(totalDe(lista.last.detalles), 21.0);
    });
  });

  group('con Riverpod', () {
    test('ventasRegistradasProvider lee lo que registra ventaProvider',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(ventasRegistradasProvider.future), isEmpty);

      final notifier = container.read(ventaProvider.notifier);
      notifier.agregarProducto(_cola, 2);
      notifier.agregarProducto(_pan, 3);
      expect(await notifier.confirmarVenta(), isTrue);

      container.invalidate(ventasRegistradasProvider);
      final lista = await container.read(ventasRegistradasProvider.future);

      expect(lista, hasLength(1));
      expect(lista.single.detalles, hasLength(2));
      expect(totalDe(lista.single.detalles), 28.5);
    });

    test('varias ventas se consultan de la más reciente a la más antigua',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(ventaProvider.notifier);

      notifier.agregarProducto(_cola, 1);
      await notifier.confirmarVenta();
      // El id y la fecha salen del reloj; se deja avanzar entre ventas.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      notifier.agregarProducto(_pan, 2);
      await notifier.confirmarVenta();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      notifier.agregarProducto(_agua, 3);
      await notifier.confirmarVenta();

      final lista = await container.read(ventasRegistradasProvider.future);

      expect(lista.map((v) => totalDe(v.detalles)), [24.0, 5.0, 10.5]);
      expect(
        lista.first.fechaHora.isAfter(lista.last.fechaHora),
        isTrue,
      );
    });
  });
}
