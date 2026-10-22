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

Venta _venta(String id, List<Producto> productos) => Venta(
  id: id,
  fechaHora: DateTime(2026, 10, 15, 9, 30),
  detalles: [
    for (final p in productos)
      DetalleVenta(producto: p, cantidad: 2, precioAlMomento: p.precio),
  ],
);

void main() {
  late Directory carpeta;
  late ProductoService productos;
  late VentaService ventas;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_historial_');
    await databaseFactory.setDatabasesPath(carpeta.path);
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase('${carpeta.path}/cabal.db');
    productos = ProductoService();
    ventas = VentaService();
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  group('eliminar un producto', () {
    test(
      'con ventas: sale del catálogo y la venta conserva el detalle',
      () async {
        await productos.crearProducto(_cola);
        await productos.crearProducto(_pan);
        await ventas.registrarVenta(_venta('v1', [_cola, _pan]));

        await productos.eliminarProducto(_cola);

        final catalogo = await productos.obtenerProductos();
        expect(catalogo.map((p) => p.id), ['p2']);

        final lista = await ventas.obtenerVentas();
        final detalle = lista.first.detalles.firstWhere(
          (d) => d.producto.id == 'p1',
        );
        expect(detalle.producto.nombre, 'Coca Cola');
        expect(detalle.cantidad, 2);
        expect(detalle.precioAlMomento, 10.5);

        final una = await ventas.obtenerVenta('v1');
        expect(
          una!.detalles.map((d) => d.producto.nombre),
          contains('Coca Cola'),
        );
      },
    );

    test('sin ventas: sale del catálogo', () async {
      await productos.crearProducto(_cola);
      await productos.eliminarProducto(_cola);
      expect(await productos.obtenerProductos(), isEmpty);
    });
  });

  test('renombrar un producto no cambia el nombre en ventas pasadas', () async {
    await productos.crearProducto(_cola);
    await ventas.registrarVenta(_venta('v1', [_cola]));

    await productos.actualizarProducto(
      const Producto(id: 'p1', nombre: 'Cola Zero', precio: 10.5),
    );

    final lista = await ventas.obtenerVentas();
    expect(lista.first.detalles.first.producto.nombre, 'Coca Cola');
    final una = await ventas.obtenerVenta('v1');
    expect(una!.detalles.first.producto.nombre, 'Coca Cola');
  });

  test('migración v1 a v2 conserva datos y rellena el nombre', () async {
    final ruta = '${carpeta.path}/cabal.db';
    final v1 = await openDatabase(
      ruta,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE producto (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, precio REAL NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE venta (id TEXT PRIMARY KEY, fecha_hora TEXT NOT NULL)',
        );
        await db.execute('''
          CREATE TABLE detalle_venta (
            venta_id TEXT NOT NULL, producto_id TEXT NOT NULL,
            cantidad INTEGER NOT NULL, precio_al_momento REAL NOT NULL,
            PRIMARY KEY (venta_id, producto_id),
            FOREIGN KEY (venta_id) REFERENCES venta(id),
            FOREIGN KEY (producto_id) REFERENCES producto(id))
        ''');
      },
    );
    await v1.insert('producto', {
      'id': 'p1',
      'nombre': 'Coca Cola',
      'precio': 10.5,
    });
    await v1.insert('venta', {
      'id': 'v1',
      'fecha_hora': '2026-10-15T09:30:00.000',
    });
    await v1.insert('detalle_venta', {
      'venta_id': 'v1',
      'producto_id': 'p1',
      'cantidad': 2,
      'precio_al_momento': 10.5,
    });
    await v1.close();

    expect((await productos.obtenerProductos()).map((p) => p.nombre), [
      'Coca Cola',
    ]);
    final lista = await ventas.obtenerVentas();
    expect(lista, hasLength(1));
    expect(lista.first.detalles.first.producto.nombre, 'Coca Cola');

    final db = await DatabaseService.instance.database;
    final fila = (await db.query('detalle_venta')).first;
    expect(fila['nombre_producto'], 'Coca Cola');
  });
}
