import 'package:app_cabal/app.dart';
import 'package:app_cabal/screens/entrada_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La app carga y muestra la pantalla de entrada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CabalApp()));

    expect(find.byType(EntradaScreen), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Ingresar (placeholder)'), findsNothing);
  });
}
