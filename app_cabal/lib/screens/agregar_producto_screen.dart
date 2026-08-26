import 'package:flutter/material.dart';

/// Pantalla de agregar/editar producto. Contenido real (formulario nombre
/// y precio) pendiente en su propio issue.
class AgregarProductoScreen extends StatelessWidget {
  const AgregarProductoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: Center(
        child: ElevatedButton(
          // "Guarda producto" -> regresa al catalogo (pop), tal como
          // esta definido en el diagrama de navegacion (#4).
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Guardar (placeholder)'),
        ),
      ),
    );
  }
}