import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);

/// Servicio en memoria: la cola ya se vendio en 3 ventas, el pan en ninguna.
class _FakeProductoService extends ProductoService {
  final Set<String> eliminados = {};
  final Set<String> archivados = {};

  @override
  Future<List<Producto>> obtenerProductos() async => [_cola, _pan]
      .where((p) => !eliminados.contains(p.id) && !archivados.contains(p.id))
      .toList();

  @override
  Future<List<Producto>> obtenerArchivados() async =>
      [_cola, _pan].where((p) => archivados.contains(p.id)).toList();

  @override
  Future<int> ventasDeProducto(String productoId) async =>
      productoId == 'p1' ? 3 : 0;

  @override
  Future<void> eliminarProducto(Producto producto) async {
    eliminados.add(producto.id);
  }

  @override
  Future<void> archivarProducto(Producto producto) async {
    archivados.add(producto.id);
  }

  @override
  Future<void> desarchivarProducto(Producto producto) async {
    archivados.remove(producto.id);
  }
}

Future<void> _abrir(WidgetTester tester, _FakeProductoService servicio) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [productoServiceProvider.overrideWithValue(servicio)],
      child: const MaterialApp(home: CatalogoScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _deslizar(WidgetTester tester, String nombre) async {
  await tester.drag(find.text(nombre), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('Borrar un producto que ya se vendio', () {
    testWidgets('no se borra: avisa y el producto sigue en la lista', (
      tester,
    ) async {
      final servicio = _FakeProductoService();
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Coca Cola');

      expect(find.text('No se puede borrar'), findsOneWidget);
      expect(find.textContaining('aparece en 3 ventas'), findsOneWidget);
      expect(servicio.eliminados, isEmpty);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Coca Cola'), findsOneWidget);
    });

    testWidgets('Archivar lo quita del catalogo sin borrarlo', (tester) async {
      final servicio = _FakeProductoService();
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Coca Cola');
      await tester.tap(find.text('Archivar'));
      await tester.pumpAndSettle();

      expect(servicio.archivados, {'p1'});
      expect(servicio.eliminados, isEmpty);
      expect(find.text('Coca Cola'), findsNothing);
      expect(find.text('Producto archivado'), findsOneWidget);
    });

    testWidgets('un producto sin ventas se borra como siempre', (tester) async {
      final servicio = _FakeProductoService();
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');

      expect(find.text('No se puede borrar'), findsNothing);
      expect(servicio.eliminados, {'p2'});
      expect(find.text('Producto eliminado'), findsOneWidget);
    });
  });

  testWidgets('los archivados se ven aparte y se pueden restaurar', (
    tester,
  ) async {
    final servicio = _FakeProductoService()..archivados.add('p1');
    await _abrir(tester, servicio);
    expect(find.text('Coca Cola'), findsNothing);

    await tester.tap(find.byTooltip('Archivados'));
    await tester.pumpAndSettle();
    expect(find.text('Coca Cola'), findsOneWidget);

    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(servicio.archivados, isEmpty);
  });
}
