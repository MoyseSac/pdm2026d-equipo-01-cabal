import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/agregar_producto_screen.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);

/// Servicio en memoria: actualizar reemplaza el producto con el mismo id,
/// igual que el UPDATE ... WHERE id = ? del servicio real.
class _FakeProductoService extends ProductoService {
  _FakeProductoService(List<Producto> productos) : _productos = [...productos];

  final List<Producto> _productos;
  final List<Producto> actualizados = [];
  final Set<String> eliminados = {};

  @override
  Future<List<Producto>> obtenerProductos() async =>
      _productos.where((p) => !eliminados.contains(p.id)).toList();

  @override
  Future<void> actualizarProducto(Producto producto) async {
    actualizados.add(producto);
    final indice = _productos.indexWhere((p) => p.id == producto.id);
    _productos[indice] = producto;
  }

  @override
  Future<void> eliminarProducto(Producto producto) async {
    eliminados.add(producto.id);
  }
}

Future<void> _abrir(WidgetTester tester, _FakeProductoService servicio) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [productoServiceProvider.overrideWithValue(servicio)],
      child: MaterialApp(
        home: const CatalogoScreen(),
        routes: {
          AppRoutes.editarProducto: (context) => AgregarProductoScreen(
            producto: ModalRoute.of(context)!.settings.arguments as Producto,
          ),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _icono(String nombre) => find.descendant(
  of: find.ancestor(of: find.text(nombre), matching: find.byType(ListTile)),
  matching: find.byTooltip('Editar producto'),
);

Future<void> _abrirEdicionConIcono(WidgetTester tester, String nombre) async {
  await tester.tap(_icono(nombre));
  await tester.pumpAndSettle();
}

void main() {
  group('Editar producto desde el catalogo', () {
    testWidgets('cada producto muestra su icono de editar', (tester) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      expect(find.byTooltip('Editar producto'), findsNWidgets(2));
    });

    testWidgets('tocar el icono abre el formulario con los valores actuales', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      await _abrirEdicionConIcono(tester, 'Coca Cola');

      expect(find.text('Editar producto'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Coca Cola'), findsOneWidget);
      // El precio llega siempre con 2 decimales.
      expect(find.widgetWithText(TextFormField, '10.50'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('guardar actualiza la fila, conserva el id y avisa', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola, _pan]);
      await _abrir(tester, servicio);

      await _abrirEdicionConIcono(tester, 'Coca Cola');
      await tester.enterText(find.byType(TextFormField).at(0), 'Coca Cola 3L');
      await tester.enterText(find.byType(TextFormField).at(1), '18.75');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(servicio.actualizados.single.id, 'p1');
      expect(find.text('Coca Cola 3L'), findsOneWidget);
      expect(find.text('Q18.75'), findsOneWidget);
      expect(find.text('Coca Cola'), findsNothing);
      expect(find.text('Producto actualizado'), findsOneWidget);
    });

    testWidgets('con datos invalidos no guarda y se queda en el formulario', (
      tester,
    ) async {
      final servicio = _FakeProductoService([_cola]);
      await _abrir(tester, servicio);

      await _abrirEdicionConIcono(tester, 'Coca Cola');
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el nombre del producto.'), findsOneWidget);
      expect(servicio.actualizados, isEmpty);
      expect(find.text('Editar producto'), findsOneWidget);
    });

    testWidgets('volver sin guardar no cambia nada ni avisa', (tester) async {
      final servicio = _FakeProductoService([_cola]);
      await _abrir(tester, servicio);

      await _abrirEdicionConIcono(tester, 'Coca Cola');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(servicio.actualizados, isEmpty);
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Producto actualizado'), findsNothing);
    });

    testWidgets('mantener presionada la fila tambien abre la edicion', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola, _pan]));

      await tester.longPress(find.text('Pan dulce'));
      await tester.pumpAndSettle();

      expect(find.text('Editar producto'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Pan dulce'), findsOneWidget);
    });

    testWidgets('tocar la fila sigue abriendo la hoja de cantidad', (
      tester,
    ) async {
      await _abrir(tester, _FakeProductoService([_cola]));

      await tester.tap(find.text('Coca Cola'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AgregarProductoScreen), findsNothing);
    });

    testWidgets('deslizar la fila sigue borrando el producto', (tester) async {
      final servicio = _FakeProductoService([_cola, _pan]);
      await _abrir(tester, servicio);

      await tester.drag(find.text('Coca Cola'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(servicio.eliminados, {'p1'});
      expect(find.text('Coca Cola'), findsNothing);
      expect(find.text('Producto eliminado'), findsOneWidget);
    });
  });
}
