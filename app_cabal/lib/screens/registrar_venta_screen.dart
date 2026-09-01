import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Pantalla de registrar venta. Contenido real (seleccion de producto,
/// monto) pendiente en su propio issue.
class RegistrarVentaScreen extends StatelessWidget {
  const RegistrarVentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // "Confirma venta" -> avanza a confirmacion. Se usa push
            // normal (no replace) para que el boton de retroceso del
            // dispositivo pueda regresar si el usuario se equivoca.
            Navigator.of(context).pushNamed(AppRoutes.confirmacionVenta);
          },
          child: const Text('Confirmar venta (placeholder)'),
        ),
      ),
    );
  }
}