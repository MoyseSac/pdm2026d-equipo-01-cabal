import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/catalogo_provider.dart';
import 'package:app_cabal/providers/cierre_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/providers/ventas_registradas_provider.dart';
import 'package:app_cabal/screens/confirmacion_venta_screen.dart';
import 'package:app_cabal/screens/home_shell.dart';
import 'package:app_cabal/screens/registrar_venta_screen.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _producto = Producto(
  id: 'p',
  nombre: 'Chocolate artesanal con almendras y leche en presentación familiar',
  precio: 1234.5,
);

Future<ProviderContainer> _abrir(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double escala = 1,
  bool reducirMovimiento = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reducirMovimiento);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final container = ProviderContainer(
    overrides: [
      catalogoProductosProvider.overrideWith((ref) async => [_producto]),
      ventasRegistradasProvider.overrideWith((ref) async => []),
      cierreHoyProvider.overrideWith(
        (ref) async => throw Exception('sin cierre de prueba'),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(ventaProvider.notifier).agregarProducto(_producto, 2);
  container.read(tabProvider.notifier).seleccionar(Pestana.vender);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: temaCabal,
        home: const HomeShell(),
        routes: {
          AppRoutes.confirmacionVenta: (_) => const ConfirmacionVentaScreen(),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _scroll() => find
    .descendant(
      of: find.byType(RegistrarVentaScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _mostrar(
  WidgetTester tester,
  Finder finder, {
  double desplazamiento = 180,
}) async {
  await tester.scrollUntilVisible(
    finder,
    desplazamiento,
    scrollable: _scroll(),
    maxScrolls: 80,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(640, 360),
    const Size(800, 1024),
  ]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets(
        'venta legible y acciones accesibles en $size a escala $escala',
        (tester) async {
          await _abrir(tester, size: size, escala: escala);
          expect(tester.takeException(), isNull);
          await _mostrar(tester, find.widgetWithText(TextButton, 'Quitar'));
          expect(
            find.widgetWithText(TextButton, 'Quitar').hitTestable(),
            findsOneWidget,
          );
          await _mostrar(
            tester,
            find.widgetWithText(ElevatedButton, 'Confirmar venta'),
          );
          expect(
            find
                .widgetWithText(ElevatedButton, 'Confirmar venta')
                .hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('teclado y error permiten desplazar hasta corregir y confirmar', (
    tester,
  ) async {
    final container = await _abrir(
      tester,
      size: const Size(320, 568),
      escala: 2,
    );
    await _mostrar(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '0');
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _mostrar(
      tester,
      find.widgetWithText(ElevatedButton, 'Confirmar venta'),
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Confirmar venta'),
          )
          .onPressed,
      isNull,
    );
    await _mostrar(tester, find.byType(TextField), desplazamiento: -180);
    await tester.enterText(find.byType(TextField), '3');
    await tester.pumpAndSettle();
    expect(container.read(ventaProvider).total, 3703.5);
    await _mostrar(
      tester,
      find.widgetWithText(ElevatedButton, 'Confirmar venta'),
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Confirmar venta'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista larga permite alcanzar el último producto y el resumen', (
    tester,
  ) async {
    final container = await _abrir(tester);
    for (var i = 0; i < 30; i++) {
      container
          .read(ventaProvider.notifier)
          .agregarProducto(
            Producto(id: '$i', nombre: 'Producto $i', precio: 2),
            1,
          );
    }
    await tester.pumpAndSettle();
    await _mostrar(tester, find.text('Producto 29'));
    expect(find.text('Producto 29').hitTestable(), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Confirmar venta').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cantidad inválida conserva texto y error al salir y regresar en lista larga',
    (tester) async {
      final container = await _abrir(tester);
      for (var i = 0; i < 30; i++) {
        container
            .read(ventaProvider.notifier)
            .agregarProducto(
              Producto(id: '$i', nombre: 'Producto $i', precio: 2),
              1,
            );
      }
      await tester.pumpAndSettle();
      await _mostrar(tester, find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, '0');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _mostrar(tester, find.text('Producto 29'));
      await _mostrar(tester, find.text(_producto.nombre), desplazamiento: -180);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '0',
      );
      expect(find.text('La cantidad debe ser mayor que cero.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
