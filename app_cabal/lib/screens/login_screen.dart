import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Pantalla de login. Contenido pendiente (ver issue #2): por ahora solo
/// permite avanzar a la app para poder probar el flujo de navegacion.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Se usa pushReplacementNamed porque el login no debe
            // quedar en la pila de navegacion: al presionar retroceso
            // desde el inicio, no queremos volver al login.
            Navigator.of(context).pushReplacementNamed(AppRoutes.inicio);
          },
          child: const Text('Ingresar (placeholder)'),
        ),
      ),
    );
  }
}
