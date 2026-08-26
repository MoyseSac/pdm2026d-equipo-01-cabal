import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Pantalla de confirmacion de venta. Segun el diagrama (#4), desde aqui
/// se vuelve al catalogo, no se sigue apilando la navegacion (la venta
/// registrada, agregar-producto, y registrar-venta ya cumplieron su
/// proposito), por eso se usa pushNamedAndRemoveUntil para limpiar la
/// pila hasta el catalogo.
class ConfirmacionVentaScreen extends StatelessWidget {
  const ConfirmacionVentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venta confirmada')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.catalogo,
              (route) => route.settings.name == AppRoutes.catalogo ||
                  route.isFirst,
            );
          },
          child: const Text('Volver al catalogo (placeholder)'),
        ),
      ),
    );
  }
}