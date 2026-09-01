import 'package:flutter/material.dart';

/// Pantalla de cierre del dia. Contenido real (que productos se vendieron
/// y cuales no) pendiente en su propio issue.
class CierreDiaScreen extends StatelessWidget {
  const CierreDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cierre del dia')),
      // El AppBar ya trae la flecha de regreso automatica al haber
      // llegado aqui con pushNamed; cubre tanto el boton en pantalla
      // como el boton fisico/gesto de retroceso del dispositivo.
      body: const Center(
        child: Text('Cierre del dia (placeholder)'),
      ),
    );
  }
}