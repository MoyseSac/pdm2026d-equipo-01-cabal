import 'dart:io';

import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan', precio: 2.5);

void main() {
  late Directory carpeta;
  late String ruta;
  late ProductoService servicio;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_reglas_');
    await databaseFactory.setDatabasesPath(carpeta.path);
    ruta = '${carpeta.path}/cabal.db';
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase(ruta);
    servicio = ProductoService();
    await servicio.crearProducto(_cola);
    await servicio.crearProducto(_pan);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  Future<void> venderCola() async {
    final db = await DatabaseService.instance.database;
    await db.insert('venta', {
      'id': 'v1',
      'fecha_hora': DateTime(2026, 10, 15).toIso8601String(),
    });
    await db.insert('detalle_venta', {
      'venta_id': 'v1',
      'producto_id': 'p1',
      'nombre_producto': 'Coca Cola',
      'cantidad': 2,
      'precio_al_momento': 10.5,
    });
  }

  group('producto en uso', () {
    test('sin ventas, ventasDeProducto es 0', () async {
      expect(await servicio.ventasDeProducto('p1'), 0);
    });

    test('con ventas, ventasDeProducto cuenta en cuantas aparece', () async {
      await venderCola();

      expect(await servicio.ventasDeProducto('p1'), 1);
      expect(await servicio.ventasDeProducto('p2'), 0);
    });
  });

  group('archivar', () {
    test(
      'un producto archivado sale del catalogo y aparece en archivados',
      () async {
        await servicio.archivarProducto(_cola);

        expect((await servicio.obtenerProductos()).map((p) => p.id), ['p2']);
        expect((await servicio.obtenerArchivados()).map((p) => p.id), ['p1']);
      },
    );

    test('desarchivar lo devuelve al catalogo con el mismo id', () async {
      await servicio.archivarProducto(_cola);
      await servicio.desarchivarProducto(_cola);

      expect((await servicio.obtenerProductos()).map((p) => p.id), [
        'p1',
        'p2',
      ]);
      expect(await servicio.obtenerArchivados(), isEmpty);
    });

    test('archivar conserva las ventas del producto', () async {
      await venderCola();
      await servicio.archivarProducto(_cola);

      expect(await servicio.ventasDeProducto('p1'), 1);
    });
  });

  group('nombre repetido', () {
    test('crear con un nombre existente da un mensaje humano', () async {
      await expectLater(
        servicio.crearProducto(
          const Producto(id: 'p3', nombre: 'Pan', precio: 1),
        ),
        throwsA(
          isA<NombreRepetidoException>().having(
            (e) => e.toString(),
            'mensaje',
            'Ya tienes un producto con ese nombre.',
          ),
        ),
      );
    });

    test('no distingue mayusculas', () async {
      await expectLater(
        servicio.crearProducto(
          const Producto(id: 'p3', nombre: 'pAN', precio: 1),
        ),
        throwsA(isA<NombreRepetidoException>()),
      );
    });

    test('editar un producto con el nombre de otro tambien avisa', () async {
      await expectLater(
        servicio.actualizarProducto(_pan.copyWith(nombre: 'Coca Cola')),
        throwsA(isA<NombreRepetidoException>()),
      );
    });

    test('guardar un producto con su propio nombre no es repetido', () async {
      await servicio.actualizarProducto(_pan.copyWith(precio: 3));

      expect((await servicio.obtenerProductos()).last.precio, 3);
    });

    test('el nombre de un producto borrado se puede reutilizar', () async {
      await servicio.eliminarProducto(_pan);

      await servicio.crearProducto(
        const Producto(id: 'p3', nombre: 'Pan', precio: 1),
      );

      expect((await servicio.obtenerProductos()).map((p) => p.id), [
        'p1',
        'p3',
      ]);
    });
  });
}
