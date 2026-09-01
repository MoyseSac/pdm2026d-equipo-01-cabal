import 'package:flutter/material.dart';

/// Estado vacio del catalogo. Es un widget separado (no una pantalla con
/// ruta propia) porque conceptualmente es un estado de CatalogoScreen, no
/// un destino distinto de navegacion. Contenido visual pendiente: esto
/// solo cubre el esqueleto de navegacion (issue actual), el diseno final
/// se hace en el issue de contenido de catalogo.
class CatalogoVacioWidget extends StatelessWidget {
  final VoidCallback onAgregarProducto;

  const CatalogoVacioWidget({super.key, required this.onAgregarProducto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Catalogo vacio (placeholder)'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onAgregarProducto,
            child: const Text('Agregar producto'),
          ),
        ],
      ),
    );
  }
}