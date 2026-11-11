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
import 'package:app_cabal/widgets/transicion_venta.dart';
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
          await _mostrar(
            tester,
            find.widgetWithIcon(IconButton, Icons.delete_outline),
          );
          expect(
            find.widgetWithIcon(IconButton, Icons.delete_outline).hitTestable(),
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
  testWidgets('dos productos completos caben junto al resumen en teléfono', (
    tester,
  ) async {
    final container = await _abrir(tester);
    final venta = container.read(ventaProvider.notifier);
    venta.limpiar();
    venta.agregarProducto(
      const Producto(id: 'cafe', nombre: 'Café molido', precio: 15),
      2,
    );
    venta.agregarProducto(
      const Producto(id: 'pan', nombre: 'Pan dulce', precio: 2.5),
      1,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(2));
    for (final card in find.byType(Card).evaluate()) {
      expect(
        tester.getSize(find.byWidget(card.widget)).height,
        lessThanOrEqualTo(144),
      );
    }
    expect(
      tester.getBottomLeft(find.byType(Card).last).dy,
      lessThan(tester.getTopLeft(find.text('Total')).dy),
    );
    expect(find.text('Q30.00'), findsOneWidget);
    expect(find.text('Q32.50'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Confirmar venta').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'subtotal baja con etiqueta si el importe es largo y el texto aumenta',
    (tester) async {
      final container = await _abrir(
        tester,
        size: const Size(320, 568),
        escala: 2,
      );
      container.read(ventaProvider.notifier).limpiar();
      container
          .read(ventaProvider.notifier)
          .agregarProducto(
            const Producto(id: 'p', nombre: 'Chocolate', precio: 9999999.99),
            1,
          );
      await tester.pumpAndSettle();
      await _mostrar(tester, find.textContaining('Subtotal:'));
      expect(find.textContaining('Subtotal:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'transición retira acciones anteriores del toque y la accesibilidad',
    (tester) async {
      final semantics = tester.ensureSemantics();

      var anteriores = 0;
      var actuales = 0;
      Widget vista(bool nueva) => MaterialApp(
        home: Scaffold(
          body: TransicionVenta(
            child: ElevatedButton(
              key: ValueKey(nueva),
              onPressed: () {
                if (nueva) {
                  actuales++;
                } else {
                  anteriores++;
                }
              },
              child: Text(nueva ? 'Acción actual' : 'Acción anterior'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(vista(false));
      await tester.pumpWidget(vista(true));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Acción anterior').hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('Acción anterior'), findsNothing);
      await tester.tap(find.text('Acción actual'));
      expect(anteriores, 0);
      expect(actuales, 1);
      await tester.pumpAndSettle();
      expect(find.text('Acción anterior'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'movimiento reducido muestra el nuevo importe sin esperar una animación',
    (tester) async {
      await _abrir(tester, reducirMovimiento: true);
      await _mostrar(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), '3');
      await tester.pump();
      await tester.pump();
      expect(find.text('Q3,703.50'), findsOneWidget);
      expect(find.text('Q2,469.00'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edición rápida conserva foco y termina con el total correcto', (
    tester,
  ) async {
    await _abrir(tester);
    await _mostrar(tester, find.byType(TextField));
    for (final cantidad in ['3', '4', '5']) {
      await tester.enterText(find.byType(TextField), cantidad);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '5',
    );
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(find.text('Q6,172.50'), findsOneWidget);
    expect(find.text('Q4,938.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controles anuncian el producto al que pertenecen', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _abrir(tester);
    await _mostrar(tester, find.byType(TextField));
    expect(
      find.bySemanticsLabel('Aumentar cantidad de ${_producto.nombre}'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Cantidad de Chocolate artesanal')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
