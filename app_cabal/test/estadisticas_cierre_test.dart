import 'package:app_cabal/models/actividad_ventas.dart';
import 'package:app_cabal/models/cierre.dart';
import 'package:app_cabal/providers/cierre_provider.dart';
import 'package:app_cabal/widgets/estadisticas_cierre.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final hoy = DateTime(2026, 11, 13);
Future<void> abrir(
  WidgetTester tester, {
  double ayer = 50,
  double total = 100,
  int ventas = 4,
  Size size = const Size(375, 812),
  double escala = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final dias = List.generate(
    7,
    (i) => ActividadVentasDia(
      dia: DateTime(2026, 11, 7 + i),
      ventas: i == 5 ? 2 : 0,
      centavos: i == 5 ? (ayer * 100).round() : 0,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [actividadSemanaProvider.overrideWith((ref) async => dias)],
      child: MaterialApp(
        theme: temaCabal,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EstadisticasCierre(
                cierre: Cierre(
                  dia: hoy,
                  numeroVentas: ventas,
                  total: total,
                  productos: const [],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('compara con ayer, calcula promedio y permite consultar un día', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('+100.0%'), findsOneWidget);
    expect(find.text('Q50.00 más en ventas'), findsOneWidget);
    expect(find.text('Q25.00'), findsOneWidget);
    expect(find.text('Hoy en curso · Ayer completo'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('actividad_dia_5')));
    await tester.tap(find.byKey(const ValueKey('actividad_dia_5')));
    await tester.pumpAndSettle();
    expect(find.text('Q50.00'), findsOneWidget);
    expect(find.text('2 ventas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ayer sin ventas no produce porcentaje infinito', (tester) async {
    await abrir(tester, ayer: 0);
    expect(find.text('Sin base porcentual'), findsOneWidget);
    expect(find.text('Q100.00 más en ventas'), findsOneWidget);
    expect(find.textContaining('Infinity'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('la caída se expresa también en texto', (tester) async {
    await abrir(tester, ayer: 200);
    expect(find.text('-50.0%'), findsOneWidget);
    expect(find.text('Q100.00 menos en ventas'), findsOneWidget);
  });
  for (final size in [const Size(320, 568), const Size(667, 375)]) {
    testWidgets('sin ventas y con texto doble en $size no desborda', (
      tester,
    ) async {
      await abrir(tester, ayer: 0, total: 0, ventas: 0, size: size, escala: 2);
      await tester.ensureVisible(find.byKey(const ValueKey('actividad_dia_6')));
      await tester.pumpAndSettle();
      expect(find.text('Sin base porcentual'), findsOneWidget);
      expect(find.text('Q0.00'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }
}
