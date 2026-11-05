import 'package:app_cabal/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La app carga y muestra la pantalla de entrada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CabalApp()));

    expect(find.widgetWithText(AppBar, 'Entrada'), findsOneWidget);
    expect(find.text('Ingresar (placeholder)'), findsOneWidget);
  });
}
