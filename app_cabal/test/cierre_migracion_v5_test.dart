import 'dart:io';

import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Esquema tal como lo dejaba la version 4: con archivado_en y el indice
/// unico de nombres, pero sin las tablas del cierre.
Future<void> _crearBaseV4(String ruta, {bool conTablasCierre = false}) async {
  final db = await databaseFactory.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: 4,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE producto (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            eliminado_en TEXT,
            imagen TEXT,
            icono TEXT,
            archivado_en TEXT
          )
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_producto_nombre
          ON producto(nombre COLLATE NOCASE)
          WHERE eliminado_en IS NULL
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
        if (conTablasCierre) {
          // Como la deja una compilacion intermedia: tablas ya creadas pero
          // user_version todavia en 4.
          await db.execute(
            'CREATE TABLE cierre (id TEXT PRIMARY KEY, dia TEXT NOT NULL, '
            'cerrado_en TEXT NOT NULL, numero_ventas INTEGER NOT NULL, '
            'total_centavos INTEGER NOT NULL)',
          );
          await db.execute('CREATE UNIQUE INDEX idx_cierre_dia ON cierre(dia)');
        }
      },
    ),
  );
  await db.insert('producto', {
    'id': 'p1',
    'nombre': 'Coca Cola',
    'precio': 10.5,
    'icono': 'bebida',
  });
  await db.insert('producto', {
    'id': 'p2',
    'nombre': 'Pan',
    'precio': 2.5,
    'archivado_en': '2026-10-01T10:00:00.000',
  });
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

Future<List<String>> _tablas() async {
  final db = await DatabaseService.instance.database;
  final filas = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );
  return filas.map((f) => f['name'] as String).toList();
}

Future<List<String>> _columnas(String tabla) async {
  final db = await DatabaseService.instance.database;
  final filas = await db.rawQuery('PRAGMA table_info($tabla)');
  return filas.map((c) => c['name'] as String).toList();
}

Future<List<Map<String, Object?>>> _indiceCierreDia() async {
  final db = await DatabaseService.instance.database;
  return db.rawQuery(
    "SELECT name, sql FROM sqlite_master WHERE type = 'index' "
    "AND name = 'idx_cierre_dia'",
  );
}

void main() {
  late Directory carpeta;
  late String ruta;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_migracion_v5_');
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

  group('base v4 con datos que pasa a v5', () {
    setUp(() => _crearBaseV4(ruta));

    test('sube a la version 5', () async {
      final db = await DatabaseService.instance.database;

      expect(await db.getVersion(), 5);
    });

    test('los productos, las ventas y sus detalles siguen', () async {
      final db = await DatabaseService.instance.database;

      final productos = await db.query('producto', orderBy: 'id');
      expect(productos.map((p) => p['nombre']), ['Coca Cola', 'Pan']);
      expect(productos.first['precio'], 10.5);
      expect(productos.last['archivado_en'], '2026-10-01T10:00:00.000');

      final ventas = await db.query('venta');
      expect(ventas.single['id'], 'v1');

      final detalle = await db.query('detalle_venta');
      expect(detalle.single['cantidad'], 2);
      expect(detalle.single['precio_al_momento'], 10.5);
    });

    test('el servicio de productos sigue leyendo el catalogo', () async {
      final productos = await ProductoService().obtenerProductos();

      expect(productos.map((p) => p.id), ['p1']);
      expect(await ProductoService().ventasDeProducto('p1'), 1);
    });

    test('existen las tablas del cierre, vacias', () async {
      final db = await DatabaseService.instance.database;

      expect(await _tablas(), containsAll(['cierre', 'cierre_producto']));
      expect(await db.query('cierre'), isEmpty);
      expect(await db.query('cierre_producto'), isEmpty);
    });

    test('las columnas guardan el dinero en centavos enteros', () async {
      expect(
        await _columnas('cierre'),
        containsAll([
          'id',
          'dia',
          'cerrado_en',
          'numero_ventas',
          'total_centavos',
        ]),
      );
      expect(
        await _columnas('cierre_producto'),
        containsAll([
          'cierre_id',
          'producto_id',
          'nombre_producto',
          'unidades',
          'subtotal_centavos',
        ]),
      );
    });

    test('existe el indice unico por dia y no deja repetir un dia', () async {
      final db = await DatabaseService.instance.database;

      final indice = await _indiceCierreDia();
      expect(indice, hasLength(1));
      expect(indice.single['sql'] as String, contains('UNIQUE'));

      Future<void> insertar(String id) => db.insert('cierre', {
        'id': id,
        'dia': '2026-11-05',
        'cerrado_en': '2026-11-05T20:00:00.000',
        'numero_ventas': 0,
        'total_centavos': 0,
      });

      await insertar('c1');
      await expectLater(insertar('c2'), throwsA(isA<DatabaseException>()));
    });

    test('borrar un cierre borra sus filas de producto', () async {
      final db = await DatabaseService.instance.database;
      await db.insert('cierre', {
        'id': 'c1',
        'dia': '2026-11-05',
        'cerrado_en': '2026-11-05T20:00:00.000',
        'numero_ventas': 1,
        'total_centavos': 2100,
      });
      await db.insert('cierre_producto', {
        'cierre_id': 'c1',
        'producto_id': 'p1',
        'nombre_producto': 'Coca Cola',
        'unidades': 2,
        'subtotal_centavos': 2100,
      });

      await db.delete('cierre', where: 'id = ?', whereArgs: ['c1']);

      expect(await db.query('cierre_producto'), isEmpty);
    });

    test('un producto del cierre no necesita existir en el catalogo', () async {
      final db = await DatabaseService.instance.database;
      await db.insert('cierre', {
        'id': 'c1',
        'dia': '2026-11-05',
        'cerrado_en': '2026-11-05T20:00:00.000',
        'numero_ventas': 0,
        'total_centavos': 0,
      });

      await db.insert('cierre_producto', {
        'cierre_id': 'c1',
        'producto_id': 'borrado-hace-tiempo',
        'nombre_producto': 'Galleta',
        'unidades': 1,
        'subtotal_centavos': 0,
      });

      expect(await db.query('cierre_producto'), hasLength(1));
    });
  });

  test('una base v4 que ya trae la tabla cierre migra sin fallar', () async {
    await _crearBaseV4(ruta, conTablasCierre: true);

    final db = await DatabaseService.instance.database;

    expect(await db.getVersion(), 5);
    expect(await _tablas(), contains('cierre_producto'));
    expect(await _indiceCierreDia(), hasLength(1));
  });

  group('instalacion nueva', () {
    test('crea la base en la version 5 con las tablas del cierre', () async {
      final db = await DatabaseService.instance.database;

      expect(await db.getVersion(), 5);
      expect(
        await _tablas(),
        containsAll([
          'producto',
          'venta',
          'detalle_venta',
          'cierre',
          'cierre_producto',
        ]),
      );
      expect(await _indiceCierreDia(), hasLength(1));
    });

    test('el catalogo funciona en una instalacion nueva', () async {
      final servicio = ProductoService();
      await servicio.crearProducto(
        const Producto(id: 'p1', nombre: 'Pan', precio: 2.5),
      );

      expect((await servicio.obtenerProductos()).single.nombre, 'Pan');
    });
  });
}
