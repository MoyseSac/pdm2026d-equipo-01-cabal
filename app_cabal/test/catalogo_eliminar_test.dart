import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);
const _agua = Producto(id: 'p3', nombre: 'Agua pura', precio: 8);
const _chicle = Producto(id: 'p4', nombre: 'Chicle', precio: 0.1);
const _aceite = Producto(id: 'p5', nombre: 'Aceite', precio: 19.99);

/// Servicio en memoria con borrado lógico, igual que el real: eliminar solo
/// marca el producto y restaurar lo vuelve a mostrar.
class _FakeProductoService extends ProductoService {
  _FakeProductoService(List<Producto> productos) : _productos = [...productos];

  final List<Producto> _productos;
  final Set<String> eliminados = {};
  bool fallarEliminar = false;
  bool fallarRestaurar = false;

  @override
  Future<List<Producto>> obtenerProductos() async =>
      _productos.where((p) => !eliminados.contains(p.id)).toList();

  @override
  Future<void> eliminarProducto(Producto producto) async {
    if (fallarEliminar) throw Exception('fallo simulado al borrar');
    eliminados.add(producto.id);
  }

  @override
  Future<void> restaurarProducto(Producto producto) async {
    if (fallarRestaurar) throw Exception('fallo simulado al restaurar');
    eliminados.remove(producto.id);
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
  group('deslizar para eliminar', () {
    testWidgets('deslizar una fila la quita de la lista', (tester) async {
      final servicio = _FakeProductoService([_cola, _pan, _agua]);
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');

      expect(find.text('Pan dulce'), findsNothing);
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Agua pura'), findsOneWidget);
      expect(find.text('Producto eliminado'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);
    });

    testWidgets('el producto se borra en la base antes de salir de la lista', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola, _pan]);
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Coca Cola');

      expect(servicio.eliminados, {'p1'});
    });

    testWidgets('ya no hay botón de papelera ni diálogo de confirmación', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      expect(find.byTooltip('Eliminar producto'), findsNothing);
      expect(find.byType(GridView), findsNothing);

      await _deslizar(tester, 'Coca Cola');

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('al borrar una fila las demás conservan su lugar y datos', (
      tester,
    ) async {
      final servicio = _FakeProductoService([
        _cola,
        _pan,
        _agua,
        _chicle,
        _aceite,
      ]);
      await _abrir(tester, servicio);

      // Se borra la fila 2 de 5.
      await _deslizar(tester, 'Pan dulce');

      expect(find.text('Pan dulce'), findsNothing);
      for (final p in [_cola, _agua, _chicle, _aceite]) {
        expect(find.text(p.nombre), findsOneWidget);
      }
      expect(find.text('Q10.50'), findsOneWidget);
      expect(find.text('Q8.00'), findsOneWidget);
      expect(find.text('Q0.10'), findsOneWidget);
      expect(find.text('Q19.99'), findsOneWidget);
    });

    testWidgets('cada fila usa el id del producto como key, no el índice', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan, _agua]));

      final llaves = tester
          .widgetList<Dismissible>(find.byType(Dismissible))
          .map((d) => d.key)
          .toList();

      expect(llaves, [
        const ValueKey('p1'),
        const ValueKey('p2'),
        const ValueKey('p3'),
      ]);
    });

    testWidgets('al borrar todos los productos aparece el estado vacío', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      await _deslizar(tester, 'Coca Cola');
      await _deslizar(tester, 'Pan dulce');

      expect(find.text('Catálogo vacío'), findsOneWidget);
      expect(find.text('Agregar primer producto'), findsOneWidget);
    });
  });

  group('deshacer', () {
    testWidgets('Deshacer devuelve la fila con los mismos datos', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola, _pan, _agua]);
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');
      expect(find.text('Pan dulce'), findsNothing);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(find.text('Pan dulce'), findsOneWidget);
      expect(find.text('Q2.50'), findsOneWidget);
      expect(servicio.eliminados, isEmpty);
      // La fila restaurada conserva su id.
      expect(
        tester
            .widgetList<Dismissible>(find.byType(Dismissible))
            .map((d) => d.key),
        contains(const ValueKey('p2')),
      );
    });

    testWidgets('Deshacer tras borrar todos vuelve a mostrar el producto', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola]);
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Coca Cola');
      expect(find.text('Catálogo vacío'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(find.text('Catálogo vacío'), findsNothing);
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Q10.50'), findsOneWidget);
    });

    testWidgets('si falla la restauración se avisa y la fila sigue oculta', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola, _pan]);
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');
      servicio.fallarRestaurar = true;
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo restaurar el producto. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Pan dulce'), findsNothing);
      expect(servicio.eliminados, {'p2'});
    });
  });

  group('si el borrado falla', () {
    testWidgets('la fila vuelve y aparece el mensaje de error', (tester) async {
      final servicio = _FakeProductoService([_cola, _pan, _agua])
        ..fallarEliminar = true;
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');

      expect(find.text('Pan dulce'), findsOneWidget);
      expect(find.text('Q2.50'), findsOneWidget);
      expect(
        find.text('No se pudo eliminar el producto. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Producto eliminado'), findsNothing);
      expect(find.text('Deshacer'), findsNothing);
      expect(servicio.eliminados, isEmpty);
    });

    testWidgets('después de corregir el fallo se puede borrar la fila', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola, _pan])
        ..fallarEliminar = true;
      await _abrir(tester, servicio);

      await _deslizar(tester, 'Pan dulce');
      expect(find.text('Pan dulce'), findsOneWidget);

      servicio.fallarEliminar = false;
      await _deslizar(tester, 'Pan dulce');

      expect(find.text('Pan dulce'), findsNothing);
      expect(servicio.eliminados, {'p2'});
    });
  });

  group('estados del catálogo', () {
    testWidgets('con productos muestra nombre y precio en quetzales', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Q10.50'), findsOneWidget);
      expect(find.text('Pan dulce'), findsOneWidget);
      expect(find.text('Q2.50'), findsOneWidget);
    });

    testWidgets('sin productos muestra el estado vacío', (tester) async {
      await _abrir(tester, _FakeProductoService([]));

      expect(find.text('Catálogo vacío'), findsOneWidget);
    });
  });
}
