import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/catalogo_provider.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/screens/confirmacion_venta_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:app_cabal/widgets/fila_catalogo_animada.dart';
import 'package:app_cabal/widgets/logo_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const chicles = Producto(
  id: 'c',
  nombre: 'Chicles',
  precio: 0.5,
  icono: 'golosinas',
);
const pan = Producto(id: 'p', nombre: 'Pan francés', precio: 1, icono: 'pan');

class _Productos extends ProductoService {
  final datos = [chicles];
  @override
  Future<List<Producto>> obtenerProductos() async => [...datos];
  @override
  Future<int> ventasDeProducto(String id) async => 0;
  @override
  Future<void> eliminarProducto(Producto p) async =>
      datos.removeWhere((item) => item.id == p.id);
  @override
  Future<void> restaurarProducto(Producto p) async => datos.add(p);
}

Finder fila(String id) => find.ancestor(
  of: find.byKey(ValueKey(id)),
  matching: find.byType(FilaCatalogoAnimada),
);
double factor(WidgetTester tester, String id) => tester
    .widget<SizeTransition>(
      find
          .descendant(of: fila(id), matching: find.byType(SizeTransition))
          .first,
    )
    .sizeFactor
    .value;
void main() {
  testWidgets(
    'la confirmación dibuja la marca una vez y no bloquea Nueva venta',
    (tester) async {
      const app = ProviderScope(
        child: MaterialApp(home: ConfirmacionVentaScreen()),
      );
      await tester.pumpWidget(app);
      expect(tester.widget<LogoCabal>(find.byType(LogoCabal)).visto.value, 0);
      expect(find.text('Nueva venta').hitTestable(), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      final marca = tester.widget<LogoCabal>(find.byType(LogoCabal));
      expect(marca.anillo.value, greaterThan(0));
      expect(marca.visto.value, lessThan(1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app);
      await tester.pump();
      expect(tester.widget<LogoCabal>(find.byType(LogoCabal)).visto.value, 1);
    },
  );
  testWidgets('movimiento reducido muestra la marca completa inmediatamente', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ConfirmacionVentaScreen())),
    );
    final marca = tester.widget<LogoCabal>(find.byType(LogoCabal));
    expect(marca.anillo.value, 1);
    expect(marca.visto.value, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets(
    'solo el producto nuevo anima entrada; recargar y buscar no la repiten',
    (tester) async {
      final servicio = _Productos();
      final container = ProviderContainer(
        overrides: [productoServiceProvider.overrideWithValue(servicio)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: temaCabal, home: const CatalogoScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(factor(tester, 'c'), 1);
      servicio.datos.add(pan);
      container.invalidate(catalogoProductosProvider);
      await container.read(catalogoProductosProvider.future);
      await tester.pump();
      expect(factor(tester, 'p'), lessThan(1));
      expect(factor(tester, 'c'), 1);
      await tester.pumpAndSettle();
      expect(factor(tester, 'p'), 1);
      container.invalidate(catalogoProductosProvider);
      await container.read(catalogoProductosProvider.future);
      await tester.pump();
      expect(factor(tester, 'p'), 1);
      await tester.enterText(find.byType(TextField), 'Chicles');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(factor(tester, 'p'), 1);
    },
  );
  testWidgets('eliminar desde menú anima la fila y Deshacer la recupera', (
    tester,
  ) async {
    final servicio = _Productos()..datos.add(pan);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productoServiceProvider.overrideWithValue(servicio)],
        child: MaterialApp(theme: temaCabal, home: const CatalogoScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('p')),
        matching: find.byTooltip('Opciones de producto'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar producto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(factor(tester, 'p'), lessThan(1));
    expect(factor(tester, 'c'), 1);
    await tester.pumpAndSettle();
    expect(find.text('Pan francés'), findsNothing);
    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    await tester.pump();
    expect(factor(tester, 'p'), lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('Pan francés'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final deslizar in [true, false]) {
    testWidgets('eliminar y restaurar sin movimiento: deslizar=$deslizar', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final servicio = _Productos()..datos.add(pan);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productoServiceProvider.overrideWithValue(servicio)],
          child: MaterialApp(theme: temaCabal, home: const CatalogoScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (deslizar) {
        await tester.drag(find.text('Pan francés'), const Offset(-500, 0));
      } else {
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('p')),
            matching: find.byTooltip('Opciones de producto'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eliminar producto'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Pan francés'), findsNothing);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(factor(tester, 'p'), 1);
      expect(tester.takeException(), isNull);
    });
  }
}
