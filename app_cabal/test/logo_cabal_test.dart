import 'package:app_cabal/widgets/logo_cabal.dart';
import 'package:app_cabal/widgets/palabra_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

Finder get _lienzoDelLogo => find.descendant(
  of: find.byType(LogoCabal),
  matching: find.byType(CustomPaint),
);

void main() {
  group('LogoCabal', () {
    testWidgets('completo dibuja el anillo y el visto', (tester) async {
      await tester.pumpWidget(_envolver(const LogoCabal.completo()));

      expect(
        tester.renderObject(_lienzoDelLogo),
        paints
          ..path()
          ..path(),
      );
    });

    testWidgets('con progreso 0 no dibuja nada', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const LogoCabal(
            anillo: AlwaysStoppedAnimation(0),
            visto: AlwaysStoppedAnimation(0),
          ),
        ),
      );

      // paintsNothing no sirve aqui: el escalado del lienzo cuenta como pintar.
      expect(tester.renderObject(_lienzoDelLogo), isNot(paints..path()));
    });

    testWidgets('el visto aparece cuando el anillo ya esta dibujado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          const LogoCabal(
            anillo: AlwaysStoppedAnimation(1),
            visto: AlwaysStoppedAnimation(0),
          ),
        ),
      );

      // Solo el anillo: un unico trazo.
      expect(tester.renderObject(_lienzoDelLogo), paints..path());
      expect(
        tester.renderObject(_lienzoDelLogo),
        isNot(
          paints
            ..path()
            ..path(),
        ),
      );
    });
  });

  group('PalabraCabal', () {
    List<double> opacidades(WidgetTester tester) => tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(PalabraCabal),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity)
        .toList();

    testWidgets('completa muestra las cinco letras visibles', (tester) async {
      await tester.pumpWidget(_envolver(const PalabraCabal.completa()));

      for (final letra in ['C', 'A', 'B', 'A', 'L']) {
        expect(find.text(letra), findsWidgets);
      }
      expect(opacidades(tester), [1.0, 1.0, 1.0, 1.0, 1.0]);
    });

    testWidgets('con progreso 0 todas las letras estan ocultas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(const PalabraCabal(animacion: AlwaysStoppedAnimation(0))),
      );

      expect(opacidades(tester), [0.0, 0.0, 0.0, 0.0, 0.0]);
    });

    testWidgets('las letras aparecen una despues de otra', (tester) async {
      // Con los tiempos por defecto la C ocupa 0.42-0.64 y la L 0.70-0.92:
      // en 0.60 la C ya va casi completa y la L todavia no empieza.
      await tester.pumpWidget(
        _envolver(const PalabraCabal(animacion: AlwaysStoppedAnimation(0.6))),
      );

      final o = opacidades(tester);
      expect(o.first, greaterThan(o.last));
      expect(o.last, 0.0);
    });

    testWidgets('se anuncia como Cabal y no letra por letra', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(_envolver(const PalabraCabal.completa()));

      expect(find.bySemanticsLabel('Cabal'), findsOneWidget);
      expect(find.bySemanticsLabel('C'), findsNothing);
      semantica.dispose();
    });
  });
}
