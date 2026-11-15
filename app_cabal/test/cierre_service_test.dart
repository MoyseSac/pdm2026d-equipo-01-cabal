import 'dart:io';

import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/cierre_service.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cola = Producto(id: 'cola', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'pan', nombre: 'Pan dulce', precio: 2.5);
const _leche = Producto(id: 'leche', nombre: 'Leche', precio: 9);

final _hoy = DateTime(2026, 10, 26);

void main() {
  late Directory carpeta;
  late CierreService servicio;
  late ProductoService productos;
  late VentaService ventas;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_cierre_service_');
    await databaseFactory.setDatabasesPath(carpeta.path);
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase('${carpeta.path}/cabal.db');

    servicio = CierreService();
    productos = ProductoService();
    ventas = VentaService();

    await productos.crearProducto(_cola);
    await productos.crearProducto(_pan);
    await productos.crearProducto(_leche);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
  });

  Future<void> vender(
    String id,
    DateTime fecha,
    List<(Producto, int, double)> lineas,
  ) {
    return ventas.registrarVenta(
      Venta(
        id: id,
        fechaHora: fecha,
        detalles: [
          for (final (producto, cantidad, precio) in lineas)
            DetalleVenta(
              producto: producto,
              cantidad: cantidad,
              precioAlMomento: precio,
            ),
        ],
      ),
    );
  }

  Future<int> contar(String tabla) async {
    final db = await DatabaseService.instance.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tabla'),
        ) ??
        0;
  }

  test(
    'actividad semanal incluye siete dias locales y suma centavos sin duplicar ventas',
    () async {
      final primero = DateTime(_hoy.year, _hoy.month, _hoy.day - 6);
      await vender(
        'fuera',
        DateTime(primero.year, primero.month, primero.day - 1, 23, 59),
        [(_cola, 1, 100)],
      );
      await vender('primero', primero, [(_pan, 2, 2.5)]);
      await vender('ayer', DateTime(_hoy.year, _hoy.month, _hoy.day - 1, 12), [
        (_leche, 5, 9),
      ]);
      await vender('hoy', DateTime(_hoy.year, _hoy.month, _hoy.day, 23, 59), [
        (_cola, 1, 0.1),
        (_pan, 1, 0.2),
      ]);
      await vender('manana', DateTime(_hoy.year, _hoy.month, _hoy.day + 1), [
        (_cola, 1, 200),
      ]);
      final dias = await servicio.actividadSemana(_hoy);
      expect(dias, hasLength(7));
      expect(dias.first.dia, primero);
      expect(dias.first.centavos, 500);
      expect(dias[1].ventas, 0);
      expect(dias[1].centavos, 0);
      expect(dias[5].centavos, 4500);
      expect(dias.last.dia, _hoy);
      expect(dias.last.ventas, 1);
      expect(dias.last.centavos, 30);
      expect(dias.last.total, 0.3);
    },
  );

  group('calcularDia', () {
    test('solo cuenta las ventas de ese dia, con sus limites', () async {
      await vender('ayer_final', DateTime(2026, 10, 25, 23, 59, 59), [
        (_cola, 1, 10.5),
      ]);
      await vender('hoy_inicio', DateTime(2026, 10, 26), [(_cola, 1, 10.5)]);
      await vender('hoy_final', DateTime(2026, 10, 26, 23, 59, 59), [
        (_cola, 1, 10.5),
      ]);
      await vender('manana_inicio', DateTime(2026, 10, 27), [(_cola, 1, 10.5)]);

      final cierre = await servicio.calcularDia(_hoy);

      expect(cierre.numeroVentas, 2);
      expect(cierre.total, 21.0);
      expect(cierre.productos.single.unidades, 2);
    });

    test('acepta cualquier hora del dia como referencia', () async {
      await vender('v1', DateTime(2026, 10, 26, 8), [(_cola, 1, 10.5)]);

      final cierre = await servicio.calcularDia(DateTime(2026, 10, 26, 18, 45));

      expect(cierre.numeroVentas, 1);
      expect(cierre.dia, DateTime(2026, 10, 26));
    });

    test('un producto en dos ventas suma en una sola fila', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [
        (_cola, 2, 10.5),
        (_pan, 1, 2.5),
      ]);
      await vender('v2', DateTime(2026, 10, 26, 15), [(_cola, 3, 10.5)]);

      final cierre = await servicio.calcularDia(_hoy);

      expect(cierre.numeroVentas, 2);
      expect(cierre.total, 55.0);
      final cola = cierre.productos.firstWhere((p) => p.productoId == 'cola');
      expect(cola.unidades, 5);
      expect(cola.subtotal, 52.5);
      expect(
        cierre.productos.where((p) => p.productoId == 'cola'),
        hasLength(1),
      );
    });

    test('los vendidos van de mayor a menor monto, no de unidades', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [
        (_cola, 1, 10.5),
        (_pan, 5, 2.5),
      ]);

      final cierre = await servicio.calcularDia(_hoy);

      // El pan salio mas veces (5), pero la cola dejo mas dinero.
      expect(cierre.productos.map((p) => p.productoId), ['pan', 'cola']);
    });

    test('el total en SQL coincide con totalDe: 0.10 + 0.20 + 0.30', () async {
      const a = Producto(id: 'a', nombre: 'A', precio: 0.10);
      const b = Producto(id: 'b', nombre: 'B', precio: 0.20);
      const c = Producto(id: 'c', nombre: 'C', precio: 0.30);
      for (final p in [a, b, c]) {
        await productos.crearProducto(p);
      }
      await vender('v1', DateTime(2026, 10, 26, 9), [
        (a, 1, 0.10),
        (b, 1, 0.20),
        (c, 1, 0.30),
      ]);

      final cierre = await servicio.calcularDia(_hoy);
      final esperado = totalDe([
        const DetalleVenta(producto: a, cantidad: 1, precioAlMomento: 0.10),
        const DetalleVenta(producto: b, cantidad: 1, precioAlMomento: 0.20),
        const DetalleVenta(producto: c, cantidad: 1, precioAlMomento: 0.30),
      ]);

      expect(cierre.total, esperado);
      expect(cierre.total, 0.60);
    });

    test('muchas unidades con centavos no acumulan error', () async {
      const barato = Producto(id: 'b', nombre: 'Barato', precio: 0.10);
      await productos.crearProducto(barato);
      for (var i = 0; i < 30; i++) {
        await vender('v$i', DateTime(2026, 10, 26, 9, i), [(barato, 1, 0.10)]);
      }

      final cierre = await servicio.calcularDia(_hoy);

      // Sumar 0.1 treinta veces como double da 3.0000000000000018.
      expect(cierre.total, 3.0);
      expect(cierre.productos.single.subtotal, 3.0);
    });

    test('usa el precio al momento y no el precio actual', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_pan, 2, 2.0)]);

      final cierre = await servicio.calcularDia(_hoy);

      // El catalogo tiene el pan a 2.50, la venta lo guardo a 2.00.
      expect(cierre.total, 4.0);
      expect(cierre.productos.single.subtotal, 4.0);
    });

    test('vendido hoy y archivado o borrado despues sigue vendido', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [
        (_pan, 2, 2.5),
        (_leche, 1, 9),
      ]);
      await productos.archivarProducto(_pan);
      await productos.eliminarProducto(_leche);

      final cierre = await servicio.calcularDia(_hoy);

      expect(cierre.productos.map((p) => p.nombre), ['Leche', 'Pan dulce']);
      expect(cierre.total, 14.0);
    });

    test('un dia sin ventas: cero ventas y sin productos', () async {
      final cierre = await servicio.calcularDia(_hoy);

      expect(cierre.numeroVentas, 0);
      expect(cierre.total, 0);
      expect(cierre.productos, isEmpty);
      expect(cierre.guardado, isFalse);
    });

    test('calcular no guarda nada', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_cola, 1, 10.5)]);

      await servicio.calcularDia(_hoy);

      expect(await contar('cierre'), 0);
      expect(await contar('cierre_producto'), 0);
    });
  });

  group('cerrarDia', () {
    test('guarda el cierre y se puede volver a leer igual', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [
        (_cola, 2, 10.5),
        (_pan, 1, 2.5),
      ]);
      final cerradoEn = DateTime(2026, 10, 26, 20, 15);

      final cerrado = await servicio.cerrarDia(_hoy, cerradoEn: cerradoEn);
      final leido = await servicio.obtenerCierre(_hoy);

      expect(cerrado.guardado, isTrue);
      expect(leido, isNotNull);
      expect(leido!.id, cerrado.id);
      expect(leido.dia, DateTime(2026, 10, 26));
      expect(leido.cerradoEn, cerradoEn);
      expect(leido.numeroVentas, 1);
      expect(leido.total, 23.5);
      expect(leido.productos.map((p) => (p.productoId, p.unidades)), [
        ('cola', 2),
        ('pan', 1),
      ]);
    });

    test('guarda el dinero en centavos enteros', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_cola, 1, 10.5)]);

      await servicio.cerrarDia(_hoy);

      final db = await DatabaseService.instance.database;
      final cierre = (await db.query('cierre')).single;
      expect(cierre['dia'], '2026-10-26');
      expect(cierre['total_centavos'], 1050);
      final cola = (await db.query(
        'cierre_producto',
        where: "producto_id = 'cola'",
      )).single;
      expect(cola['subtotal_centavos'], 1050);
    });

    test('cerrar dos veces deja un solo cierre con la foto nueva', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_cola, 1, 10.5)]);
      await servicio.cerrarDia(_hoy, cerradoEn: DateTime(2026, 10, 26, 18));

      await vender('v2', DateTime(2026, 10, 26, 19), [(_pan, 4, 2.5)]);
      await servicio.cerrarDia(_hoy, cerradoEn: DateTime(2026, 10, 26, 21));

      expect(await contar('cierre'), 1);
      // Cola y pan, una sola vez cada uno: la foto vieja se reemplazo.
      expect(await contar('cierre_producto'), 2);
      final leido = (await servicio.obtenerCierre(_hoy))!;
      expect(leido.numeroVentas, 2);
      expect(leido.total, 20.5);
      expect(leido.cerradoEn, DateTime(2026, 10, 26, 21));
    });

    test('cerrar otro dia no toca el cierre de un dia anterior', () async {
      await vender('ayer', DateTime(2026, 10, 25, 9), [(_cola, 1, 10.5)]);
      await vender('hoy', DateTime(2026, 10, 26, 9), [(_pan, 1, 2.5)]);

      await servicio.cerrarDia(DateTime(2026, 10, 25));
      await servicio.cerrarDia(_hoy);

      expect(await contar('cierre'), 2);
      expect(
        (await servicio.obtenerCierre(DateTime(2026, 10, 25)))!.total,
        10.5,
      );
      expect((await servicio.obtenerCierre(_hoy))!.total, 2.5);
    });

    test('no deja cerrar un dia sin ventas', () async {
      await expectLater(
        servicio.cerrarDia(_hoy),
        throwsA(isA<CierreSinVentasException>()),
      );

      expect(await contar('cierre'), 0);
    });

    test('editar el precio despues no cambia el cierre guardado', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_pan, 2, 2.5)]);
      await servicio.cerrarDia(_hoy);

      await productos.actualizarProducto(
        const Producto(id: 'pan', nombre: 'Pan integral', precio: 99),
      );

      final leido = (await servicio.obtenerCierre(_hoy))!;
      expect(leido.total, 5.0);
      expect(leido.productos.single.nombre, 'Pan dulce');
      expect(leido.productos.single.subtotal, 5.0);
    });

    test('archivar o borrar despues no cambia el cierre guardado', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_pan, 1, 2.5)]);
      await servicio.cerrarDia(_hoy);

      await productos.archivarProducto(_pan);
      await productos.eliminarProducto(_leche);
      await productos.archivarProducto(_cola);

      final leido = (await servicio.obtenerCierre(_hoy))!;
      expect(leido.productos.map((p) => p.productoId), ['pan']);
    });
  });

  group('obtenerCierre', () {
    test('devuelve null si ese dia no se ha cerrado', () async {
      await vender('v1', DateTime(2026, 10, 26, 9), [(_cola, 1, 10.5)]);

      expect(await servicio.obtenerCierre(_hoy), isNull);
    });
  });
}
