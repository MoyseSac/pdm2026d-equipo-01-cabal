import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:app_cabal/widgets/cantidad_producto_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const producto = Producto(
  id: 'c',
  nombre: 'Chorizo criollo artesanal de presentación familiar',
  precio: 12.5,
  icono: 'embutidos',
);
Future<List<int?>> abrir(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double escala = 1,
  bool reducir = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reducir);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final resultados = <int?>[];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: temaCabal,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultados.add(
                  await mostrarCantidadProducto(
                    context,
                    producto,
                    yaEnVenta: 2,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return resultados;
}

Finder campo() => find.descendant(
  of: find.byType(CantidadProductoSheet),
  matching: find.byType(TextField),
);
Finder agregar() => find.descendant(
  of: find.byType(CantidadProductoSheet),
  matching: find.byType(FilledButton),
);
void main() {
  testWidgets('permite escribir cien unidades y confirma esa cantidad', (
    tester,
  ) async {
    final resultados = await abrir(tester);
    await tester.enterText(campo(), '100');
    await tester.pumpAndSettle();
    expect(find.text('Agregar a la venta · Q1,250.00'), findsOneWidget);
    await tester.tap(agregar());
    await tester.pumpAndSettle();
    expect(resultados, [100]);
  });
  testWidgets('cantidades rápidas fijan el valor y muestran selección', (
    tester,
  ) async {
    await abrir(tester);
    await tester.ensureVisible(find.byTooltip('Elegir 25 unidades'));
    await tester.tap(find.byTooltip('Elegir 25 unidades'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(campo()).controller!.text, '25');
    expect(find.text('Agregar a la venta · Q312.50'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '25')).selected,
      isTrue,
    );
  });
  testWidgets(
    'vacío y cero deshabilitan confirmar; decimales no cambian a enteros',
    (tester) async {
      await abrir(tester);
      for (final texto in ['', '0']) {
        await tester.enterText(campo(), texto);
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(agregar()).onPressed, isNull);
        expect(find.text('Ingresa un entero mayor que cero.'), findsOneWidget);
      }
      await tester.enterText(campo(), '12');
      await tester.pumpAndSettle();
      await tester.enterText(campo(), '1.5');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(campo()).controller!.text, '12');
    },
  );
  testWidgets('varios toques sin esperar animaciones no pierden incrementos', (
    tester,
  ) async {
    await abrir(tester);
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byTooltip('Agregar una unidad'));
    }
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(campo()).controller!.text, '10');
    expect(find.text('Agregar a la venta · Q125.00'), findsOneWidget);
  });
  for (final size in [const Size(320, 568), const Size(667, 375)]) {
    testWidgets('cantidad editable con teclado y texto doble en $size', (
      tester,
    ) async {
      await abrir(tester, size: size, escala: 2, reducir: true);
      await tester.ensureVisible(campo());
      await tester.pumpAndSettle();
      await tester.enterText(campo(), '100');
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: campo(), matching: find.byType(EditableText)),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.ensureVisible(campo());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(agregar());
      await tester.pumpAndSettle();
      expect(agregar().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
