import 'package:flutter/material.dart';

class CabalApp extends StatelessWidget {
  const CabalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabal',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Cabal'),
        ),
      ),
    );
  }
}