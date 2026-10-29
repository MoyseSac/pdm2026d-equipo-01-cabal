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

void main() {
  late Directory carpeta;
  late ProductoService productos;
  late VentaService ventas;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = Directory.systemTemp.createTempSync('cabal_restaurar_');
    await databaseFactory.setDatabasesPath(carpeta.path);
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase('${carpeta.path}/cabal.db');
    productos = ProductoService();
    ventas = VentaService();
    await productos.crearProducto(_cola);
    await productos.crearProducto(_pan);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    carpeta.deleteSync(recursive: true);
  });

  test('borrar y restaurar devuelve el mismo producto al catálogo', () async {
    await productos.eliminarProducto(_cola);
    expect((await productos.obtenerProductos()).map((p) => p.id), ['p2']);

    await productos.restaurarProducto(_cola);

    final catalogo = await productos.obtenerProductos();
    expect(catalogo.map((p) => p.id), ['p1', 'p2']);
    final restaurado = catalogo.firstWhere((p) => p.id == 'p1');
    expect(restaurado.nombre, 'Coca Cola');
    expect(restaurado.precio, 10.5);
  });

  test(
    'lo borrado sigue borrado y lo restaurado sigue ahí al reabrir',
    () async {
      await productos.eliminarProducto(_cola);
      await productos.eliminarProducto(_pan);
      await productos.restaurarProducto(_pan);

      await DatabaseService.instance.close();

      expect((await ProductoService().obtenerProductos()).map((p) => p.id), [
        'p2',
      ]);
    },
  );

  test('restaurar un producto con ventas no cambia el historial', () async {
    await ventas.registrarVenta(
      Venta(
        id: 'v1',
        fechaHora: DateTime(2026, 10, 15, 9, 30),
        detalles: const [
          DetalleVenta(producto: _cola, cantidad: 2, precioAlMomento: 10.5),
        ],
      ),
    );
    final antes = await ventas.obtenerVentas();

    await productos.eliminarProducto(_cola);
    await productos.restaurarProducto(_cola);

    final despues = await ventas.obtenerVentas();
    expect(despues, hasLength(1));
    expect(despues.first.detalles.first.producto.nombre, 'Coca Cola');
    expect(despues.first.detalles.first.cantidad, 2);
    expect(despues.first.detalles.first.precioAlMomento, 10.5);
    expect(despues.first.id, antes.first.id);
  });
}
