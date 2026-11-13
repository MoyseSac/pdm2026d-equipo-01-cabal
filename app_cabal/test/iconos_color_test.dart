import 'package:app_cabal/constants/iconos_producto.dart';
import 'package:app_cabal/models/imagen_producto.dart';
import 'package:app_cabal/screens/agregar_producto_screen.dart';
import 'package:app_cabal/services/imagen_producto_service.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:app_cabal/widgets/producto_imagen_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('todas las categorías cargan sus dibujos locales', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final clave in iconosProducto.keys)
                  ProductoImagenWidget(imagen: IconoElegido(clave)),
                const ProductoImagenWidget(imagen: IconoElegido('desconocido')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold));
      for (final categoria in iconosProducto.values) {
        await precacheImage(AssetImage(categoria.asset), context);
      }
    });
    await tester.pumpAndSettle();
    for (final categoria in iconosProducto.values) {
      expect(find.image(AssetImage(categoria.asset)), findsOneWidget);
    }
    expect(find.byIcon(iconoProductoGenerico), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (size, escala) in [
    (const Size(375, 667), 1.0),
    (const Size(667, 375), 2.0),
  ]) {
    testWidgets('selector permite elegir al final en $size con texto $escala', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: temaCabal,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: AgregarProductoScreen(
              imagenes: ImagenProductoService(),
              onGuardar: (_) async {},
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Usar icono'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar icono'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Papelería'),
        100,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Papelería'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Papelería'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(
        find.image(AssetImage(iconosProducto['papeleria']!.asset)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
