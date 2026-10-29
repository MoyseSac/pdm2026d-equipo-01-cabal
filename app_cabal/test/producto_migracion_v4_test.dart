import 'dart:io';

import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Esquema tal como lo dejaba la version 3: sin archivado_en y sin indice
/// unico, asi que un telefono podia tener nombres repetidos.
Future<void> _crearBaseV3(String ruta) async {
  final db = await databaseFactory.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE producto (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            eliminado_en TEXT,
            imagen TEXT,
            icono TEXT
          )
        ''');
        await db.execute(
          'CREATE TABLE venta (id TEXT PRIMARY KEY, fecha_hora TEXT NOT NULL)',
        );
        await db.execute('''
          CREATE TABLE detalle_venta (
            venta_id TEXT NOT NULL,
            producto_id TEXT NOT NULL,
            nombre_producto TEXT,
            cantidad INTEGER NOT NULL,
            precio_al_momento REAL NOT NULL,
            PRIMARY KEY (venta_id, producto_id)
          )
        ''');
      },
    ),
  );
  await db.insert('producto', {
    'id': 'p1',
    'nombre': 'Coca Cola',
    'precio': 10.5,
    'icono': 'bebida',
  });
  await db.insert('producto', {'id': 'p2', 'nombre': 'Pan', 'precio': 2.5});
  await db.insert('producto', {'id': 'p3', 'nombre': 'pan', 'precio': 3.0});
  await db.insert('producto', {'id': 'p4', 'nombre': 'PAN', 'precio': 4.0});
  await db.insert('producto', {
    'id': 'p5',
    'nombre': 'Leche',
    'precio': 9.0,
    'eliminado_en': '2026-10-01T10:00:00.000',
  });
  await db.insert('producto', {'id': 'p6', 'nombre': 'Leche', 'precio': 9.5});
  await db.insert('venta', {'id': 'v1', 'fecha_hora': '2026-10-15T09:30:00'});
  await db.insert('detalle_venta', {
    'venta_id': 'v1',
    'producto_id': 'p1',
    'nombre_producto': 'Coca Cola',
    'cantidad': 2,
    'precio_al_momento': 10.5,
  });
  await db.close();
}

void main() {
  late Directory carpeta;
  late String ruta;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_migracion_v4_');
    await databaseFactory.setDatabasesPath(carpeta.path);
    ruta = '${carpeta.path}/cabal.db';
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase(ruta);
    await _crearBaseV3(ruta);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  test('abrir una base v3 la sube a la version 4', () async {
    final db = await DatabaseService.instance.database;

    expect(await db.getVersion(), 4);
  });

  test('los productos y sus datos siguen despues de migrar', () async {
    final productos = await ProductoService().obtenerProductos();

    final cola = productos.firstWhere((p) => p.id == 'p1');
    expect(cola.nombre, 'Coca Cola');
    expect(cola.precio, 10.5);
    expect(cola.icono, 'bebida');
    expect(productos.map((p) => p.id), containsAll(['p1', 'p2', 'p3', 'p4']));
  });

  test('las ventas existentes no se tocan', () async {
    final servicio = ProductoService();

    expect(await servicio.ventasDeProducto('p1'), 1);
    final db = await DatabaseService.instance.database;
    final venta = await db.query('venta');
    expect(venta.single['id'], 'v1');
  });

  test('la columna archivado_en existe y nadie queda archivado', () async {
    final db = await DatabaseService.instance.database;

    final columnas = (await db.rawQuery(
      'PRAGMA table_info(producto)',
    )).map((c) => c['name']);
    expect(columnas, contains('archivado_en'));
    expect(await ProductoService().obtenerArchivados(), isEmpty);
  });

  test('los nombres repetidos se renombran en vez de fallar', () async {
    final nombres = (await ProductoService().obtenerProductos())
        .where((p) => const ['p2', 'p3', 'p4'].contains(p.id))
        .map((p) => p.nombre);

    expect(nombres, unorderedEquals(['Pan', 'pan (2)', 'PAN (3)']));
  });

  test('un producto borrado no cuenta como repetido', () async {
    final db = await DatabaseService.instance.database;

    final leches = await db.query('producto', where: "nombre = 'Leche'");
    expect(leches, hasLength(2));
  });

  test('despues de migrar ya no se puede repetir un nombre', () async {
    await expectLater(
      ProductoService().crearProducto(
        const Producto(id: 'p9', nombre: 'coca cola', precio: 1),
      ),
      throwsA(isA<NombreRepetidoException>()),
    );
  });

  test('el indice unico existe', () async {
    final db = await DatabaseService.instance.database;

    final indices = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name = 'idx_producto_nombre'",
    );
    expect(indices, hasLength(1));
  });
}
