import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Pantalla de login. Contenido pendiente (ver issue #2): por ahora solo
/// permite avanzar al catalogo para poder probar el flujo de navegacion.
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
            // desde el catalogo, no queremos volver al login.
            Navigator.of(context).pushReplacementNamed(AppRoutes.catalogo);
          },
          child: const Text('Ingresar (placeholder)'),
        ),
      ),
    );
  }
}