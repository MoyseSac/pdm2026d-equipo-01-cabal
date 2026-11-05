import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Pantalla de entrada. Cabal no tiene usuario ni contrasena: esta pantalla
/// solo da paso a la app. Por ahora permite avanzar con un boton para poder
/// probar el flujo de navegacion.
class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrada')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Se usa pushReplacementNamed porque la entrada no debe
            // quedar en la pila de navegacion: al presionar retroceso
            // desde el inicio, no queremos volver a ella.
            Navigator.of(context).pushReplacementNamed(AppRoutes.inicio);
          },
          child: const Text('Ingresar (placeholder)'),
        ),
      ),
    );
  }
}
