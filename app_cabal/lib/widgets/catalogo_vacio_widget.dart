import 'package:flutter/material.dart';

class CatalogoVacioWidget extends StatelessWidget {
  final VoidCallback onAgregarProducto;

  const CatalogoVacioWidget({super.key, required this.onAgregarProducto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Catálogo vacío',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay productos registrados aún',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAgregarProducto,
            icon: const Icon(Icons.add),
            label: const Text('Agregar primer producto'),
          ),
        ],
      ),
    );
  }
}