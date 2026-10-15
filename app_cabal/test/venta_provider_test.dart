import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _VentaServiceQueFalla extends VentaService {
  @override
  Future<void> registrarVenta(Venta venta) async {
    throw Exception('fallo simulado');
  }
}

void main() {
  const cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.50);
  const pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.50);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.instance.close();
    await deleteDatabase('${await getDatabasesPath()}/cabal.db');

    final productos = ProductoService();
    await productos.crearProducto(cola);
    await productos.crearProducto(pan);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
  });

  test('agrega productos, fusiona repetidos y calcula el total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    notifier.agregarProducto(cola, 2);
    notifier.agregarProducto(pan, 3);
    notifier.agregarProducto(cola, 1);

    final state = container.read(ventaProvider);
    expect(state.detalles.length, 2);
    expect(state.detalles.first.cantidad, 3);
    expect(state.total, 39.0);
  });

  test('el total no arrastra errores de decimales', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    notifier.agregarProducto(
      const Producto(id: 'a', nombre: 'A', precio: 0.10),
      1,
    );
    notifier.agregarProducto(
      const Producto(id: 'b', nombre: 'B', precio: 0.20),
      1,
    );
    notifier.agregarProducto(
      const Producto(id: 'c', nombre: 'C', precio: 0.30),
      1,
    );

    expect(container.read(ventaProvider).total, 0.60);
  });

  test('rechaza cantidad invalida', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    expect(notifier.agregarProducto(cola, 0), isFalse);

    final state = container.read(ventaProvider);
    expect(state.estado, EstadoRegistroVenta.error);
    expect(state.mensajeError, mensajeCantidadInvalida);
    expect(state.detalles, isEmpty);
  });

  test('no guarda una venta vacia', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ok = await container.read(ventaProvider.notifier).confirmarVenta();

    expect(ok, isFalse);
    expect(
      container.read(ventaProvider).mensajeError,
      mensajeVentaSinProductos,
    );
  });

  test('guarda la venta y persiste tras cerrar y reabrir la base', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    notifier.agregarProducto(cola, 2);
    notifier.agregarProducto(pan, 3);
    final ok = await notifier.confirmarVenta();

    final state = container.read(ventaProvider);
    expect(ok, isTrue);
    expect(state.estado, EstadoRegistroVenta.exito);
    expect(state.detalles, isEmpty);
    expect(totalDe(state.ventaConfirmada!.detalles), 28.5);

    await DatabaseService.instance.close();
    final guardada =
        await VentaService().obtenerVenta(state.ventaConfirmada!.id);

    expect(guardada, isNotNull);
    expect(guardada!.detalles.length, 2);
    expect(totalDe(guardada.detalles), 28.5);
  });

  test('doble toque en confirmar registra una sola venta', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    notifier.agregarProducto(cola, 1);
    final resultados = await Future.wait([
      notifier.confirmarVenta(),
      notifier.confirmarVenta(),
    ]);

    expect(resultados.where((r) => r).length, 1);
    final db = await DatabaseService.instance.database;
    expect(await db.query('venta'), hasLength(1));
  });

  test('si falla el guardado conserva la venta y muestra el error', () async {
    final container = ProviderContainer(
      overrides: [
        ventaServiceProvider.overrideWithValue(_VentaServiceQueFalla()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(ventaProvider.notifier);

    notifier.agregarProducto(cola, 2);
    final ok = await notifier.confirmarVenta();

    final state = container.read(ventaProvider);
    expect(ok, isFalse);
    expect(state.estado, EstadoRegistroVenta.error);
    expect(state.mensajeError, mensajeErrorGuardado);
    expect(state.detalles.length, 1);
    expect(state.guardando, isFalse);
  });
}
