import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_cabal/app.dart';

void main() {
  testWidgets('La app carga y muestra el nombre Cabal', (WidgetTester tester) async {
    await tester.pumpWidget(const CabalApp());

    expect(find.text('Cabal'), findsOneWidget);
  });
}