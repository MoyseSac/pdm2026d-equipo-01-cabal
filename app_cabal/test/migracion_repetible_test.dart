import 'dart:io';

import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Crea una base con un `user_version` menor al que le corresponde a sus
/// columnas, como la que deja una compilacion intermedia instalada antes de
/// subir la version.
Future<void> _crearBase(
  String ruta, {
  required int version,
  List<String> columnasProducto = const [],
  bool conNombreEnDetalle = false,
  bool conIndiceUnico = false,
}) async {
  final db = await databaseFactory.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (db, _) async {
        final extras = columnasProducto.map((c) => ', $c TEXT').join();
        await db.execute(
          'CREATE TABLE producto (id TEXT PRIMARY KEY, '
          'nombre TEXT NOT NULL, precio REAL NOT NULL$extras)',
        );
        await db.execute(
          'CREATE TABLE venta (id TEXT PRIMARY KEY, fecha_hora TEXT NOT NULL)',
        );
        final nombre = conNombreEnDetalle ? 'nombre_producto TEXT,' : '';
        await db.execute('''
          CREATE TABLE detalle_venta (
            venta_id TEXT NOT NULL,
            producto_id TEXT NOT NULL,
            $nombre
            cantidad INTEGER NOT NULL,
            precio_al_momento REAL NOT NULL,
            PRIMARY KEY (venta_id, producto_id)
          )
        ''');
        if (conIndiceUnico) {
          await db.execute(
            'CREATE UNIQUE INDEX idx_producto_nombre '
            'ON producto(nombre COLLATE NOCASE) WHERE eliminado_en IS NULL',
          );
        }
      },
    ),
  );
  await db.insert('producto', {
    'id': 'p1',
    'nombre': 'Coca Cola',
    'precio': 10.5,
  });
  await db.insert('producto', {'id': 'p2', 'nombre': 'Pan', 'precio': 2.5});
  await db.insert('venta', {'id': 'v1', 'fecha_hora': '2026-10-15T09:30:00'});
  await db.insert('detalle_venta', {
    'venta_id': 'v1',
    'producto_id': 'p1',
    'cantidad': 2,
    'precio_al_momento': 10.5,
  });
  await db.close();
}

Future<Set<String>> _columnas(String tabla) async {
  final db = await DatabaseService.instance.database;
  final filas = await db.rawQuery('PRAGMA table_info($tabla)');
  return filas.map((f) => f['name'] as String).toSet();
}

void main() {
  late Directory carpeta;
  late String ruta;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_migracion_repetible_');
    await databaseFactory.setDatabasesPath(carpeta.path);
    ruta = '${carpeta.path}/cabal.db';
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase(ruta);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  test('una base v3 que ya tiene archivado_en abre sin error', () async {
    await _crearBase(
      ruta,
      version: 3,
      columnasProducto: ['eliminado_en', 'imagen', 'icono', 'archivado_en'],
      conNombreEnDetalle: true,
    );

    final db = await DatabaseService.instance.database;

    expect(await db.getVersion(), 5);
    expect(await _columnas('producto'), contains('archivado_en'));
  });

  test('la base con columnas repetidas conserva sus datos', () async {
    await _crearBase(
      ruta,
      version: 3,
      columnasProducto: ['eliminado_en', 'imagen', 'icono', 'archivado_en'],
      conNombreEnDetalle: true,
    );

    final productos = await ProductoService().obtenerProductos();

    expect(productos.map((p) => p.id), unorderedEquals(['p1', 'p2']));
    expect(await ProductoService().ventasDeProducto('p1'), 1);
  });

  test(
    'una base v1 que ya tiene las columnas de la v2 y la v3 migra',
    () async {
      await _crearBase(
        ruta,
        version: 1,
        columnasProducto: ['eliminado_en', 'imagen', 'icono'],
        conNombreEnDetalle: true,
      );

      final db = await DatabaseService.instance.database;

      expect(await db.getVersion(), 5);
      expect(await _columnas('detalle_venta'), contains('nombre_producto'));
      expect(await _columnas('producto'), contains('archivado_en'));
    },
  );

  test('una base v3 que ya tiene el indice unico migra', () async {
    await _crearBase(
      ruta,
      version: 3,
      columnasProducto: ['eliminado_en', 'imagen', 'icono'],
      conNombreEnDetalle: true,
      conIndiceUnico: true,
    );

    final db = await DatabaseService.instance.database;

    expect(await db.getVersion(), 5);
    final indices = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name = 'idx_producto_nombre'",
    );
    expect(indices, hasLength(1));
  });

  test('una base v1 normal sigue migrando completa', () async {
    await _crearBase(ruta, version: 1);

    final db = await DatabaseService.instance.database;

    expect(await db.getVersion(), 5);
    expect(
      await _columnas('producto'),
      containsAll(['eliminado_en', 'imagen', 'icono', 'archivado_en']),
    );
    expect(await _columnas('detalle_venta'), contains('nombre_producto'));
    final detalle = await db.query('detalle_venta');
    expect(detalle.single['nombre_producto'], 'Coca Cola');
  });

  test('un nombre historico que ya existia no se pisa al migrar', () async {
    await _crearBase(
      ruta,
      version: 1,
      columnasProducto: ['eliminado_en'],
      conNombreEnDetalle: true,
    );
    final antes = await databaseFactory.openDatabase(ruta);
    await antes.update('detalle_venta', {'nombre_producto': 'Nombre viejo'});
    await antes.close();

    final db = await DatabaseService.instance.database;

    final detalle = await db.query('detalle_venta');
    expect(detalle.single['nombre_producto'], 'Nombre viejo');
  });
}
