import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/screens/entrada_screen.dart';
import 'package:app_cabal/widgets/logo_cabal.dart';
import 'package:app_cabal/widgets/palabra_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// La pantalla de entrada no lee providers ni base de datos, asi que se prueba
// con un MaterialApp minimo cuyo "inicio" es un texto. Eso deja claro que lo
// que se verifica es la animacion y la navegacion, no la pantalla de inicio.
const _textoInicio = 'inicio de prueba';

Widget _app({bool sinAnimaciones = false}) => MaterialApp(
  initialRoute: AppRoutes.entrada,
  routes: {
    AppRoutes.entrada: (_) => const EntradaScreen(),
    AppRoutes.inicio: (_) => const Scaffold(body: Text(_textoInicio)),
  },
  builder: (context, hijo) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: sinAnimaciones),
    child: hijo!,
  ),
);

List<double> _opacidadesDeLasLetras(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.descendant(
        of: find.byType(PalabraCabal),
        matching: find.byType(Opacity),
      ),
    )
    .map((o) => o.opacity)
    .toList();

void main() {
  testWidgets('muestra el logo y la palabra, sin AppBar ni boton', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.byType(LogoCabal), findsOneWidget);
    expect(find.byType(PalabraCabal), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('Ingresar (placeholder)'), findsNothing);
  });

  testWidgets('las letras aparecen poco a poco y la ultima va al final', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(_opacidadesDeLasLetras(tester), [0.0, 0.0, 0.0, 0.0, 0.0]);

    // A 1100 ms (0.55 de la linea de tiempo) la C ya va avanzada y la L
    // (que empieza en 0.68) todavia no.
    await tester.pump(const Duration(milliseconds: 1100));
    final mitad = _opacidadesDeLasLetras(tester);
    expect(mitad.first, greaterThan(0));
    expect(mitad.first, greaterThan(mitad.last));
    expect(mitad.last, 0.0);

    // A 1800 ms (0.90) ya estan las cinco.
    await tester.pump(const Duration(milliseconds: 700));
    expect(_opacidadesDeLasLetras(tester), [1.0, 1.0, 1.0, 1.0, 1.0]);
  });

  testWidgets('pasa sola a inicio a los 2 segundos, sin tocar nada', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byType(EntradaScreen), findsOneWidget);
    expect(find.text(_textoInicio), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text(_textoInicio), findsOneWidget);
    expect(find.byType(EntradaScreen), findsNothing);
  });

  testWidgets('desde inicio no se puede volver a la entrada', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(_textoInicio), findsOneWidget);
    final navegador = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navegador.canPop(), isFalse);
  });

  testWidgets('tocar la pantalla salta la animacion y pasa a inicio', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EntradaScreen), findsOneWidget);

    await tester.tap(find.byType(EntradaScreen));
    await tester.pumpAndSettle();

    expect(find.text(_textoInicio), findsOneWidget);
  });

  testWidgets('con animaciones desactivadas muestra todo y pasa tras 300 ms', (
    tester,
  ) async {
    await tester.pumpWidget(_app(sinAnimaciones: true));

    // Desde el primer cuadro esta la palabra completa, sin haber animado.
    expect(_opacidadesDeLasLetras(tester), [1.0, 1.0, 1.0, 1.0, 1.0]);
    expect(find.byType(EntradaScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(EntradaScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text(_textoInicio), findsOneWidget);
  });
}
