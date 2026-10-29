import 'dart:io';

import 'package:app_cabal/models/imagen_producto.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Esquema tal como lo dejaba la version 2, antes de imagen e icono.
Future<void> _crearBaseV2(String ruta) async {
  final db = await databaseFactory.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE producto (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            eliminado_en TEXT
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
  });
  await db.insert('producto', {'id': 'p2', 'nombre': 'Pan', 'precio': 2.5});
  await db.close();
}

void main() {
  late Directory carpeta;
  late String ruta;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_imagen_');
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

  test('una base v2 pasa a v3 sin perder productos y sin imagen', () async {
    await _crearBaseV2(ruta);

    final productos = await ProductoService().obtenerProductos();

    expect(productos.map((p) => p.nombre), ['Coca Cola', 'Pan']);
    expect(productos.first.precio, 10.5);
    expect(productos.map((p) => p.imagen), [null, null]);
    expect(productos.map((p) => p.icono), [null, null]);
    final db = await DatabaseService.instance.database;
    expect(await db.getVersion(), 3);
  });

  test('tras migrar se puede guardar un icono en un producto viejo', () async {
    await _crearBaseV2(ruta);
    final servicio = ProductoService();
    final cola = (await servicio.obtenerProductos()).first;

    await servicio.actualizarProducto(
      cola.copyWith(imagenProducto: const IconoElegido('bebida')),
    );
    await DatabaseService.instance.close();

    final releido = (await ProductoService().obtenerProductos()).first;
    expect(releido.icono, 'bebida');
    expect(releido.imagen, isNull);
  });

  test('cambiar de foto a icono deja la columna imagen en null', () async {
    final servicio = ProductoService();
    await servicio.crearProducto(
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'a.jpg'),
    );

    final leche = (await servicio.obtenerProductos()).single;
    await servicio.actualizarProducto(
      leche.copyWith(imagenProducto: const IconoElegido('lacteos')),
    );
    await DatabaseService.instance.close();

    final releido = (await ProductoService().obtenerProductos()).single;
    expect(releido.imagen, isNull);
    expect(releido.icono, 'lacteos');
  });

  test('borrar un producto conserva su foto para poder restaurarlo', () async {
    final servicio = ProductoService();
    const leche = Producto(
      id: 'p1',
      nombre: 'Leche',
      precio: 9,
      imagen: 'a.jpg',
    );
    await servicio.crearProducto(leche);

    await servicio.eliminarProducto(leche);
    await servicio.restaurarProducto(leche);

    expect((await servicio.obtenerProductos()).single.imagen, 'a.jpg');
  });

  group('copyWith', () {
    const conFoto = Producto(id: 'p1', nombre: 'A', precio: 1, imagen: 'a.jpg');

    test('sin imagenProducto conserva la foto', () {
      final editado = conFoto.copyWith(nombre: 'B');
      expect(editado.imagen, 'a.jpg');
      expect(editado.icono, isNull);
    });

    test('SinImagen limpia foto e icono', () {
      final limpio = conFoto.copyWith(imagenProducto: const SinImagen());
      expect(limpio.imagen, isNull);
      expect(limpio.icono, isNull);
    });
  });
}
