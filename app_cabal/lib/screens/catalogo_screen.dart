import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../widgets/catalogo_vacio_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/producto_provider.dart';

class CatalogoScreen extends ConsumerWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productos = ref.watch(productoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: productos.isEmpty
        ? CatalogoVacioWidget(
            onAgregarProducto: () =>
              Navigator.of(context).pushNamed(AppRoutes.agregarProducto),
          )
        : Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    return Card(
                      child: InkWell(
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.registrarVenta),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${producto.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.registrarVenta),
                  child: const Text('Probar registrar venta'),
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agregar',
        onPressed: () async {
          final result = await Navigator.of(context)
              .pushNamed(AppRoutes.agregarProducto);
          if (result == true) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto agregado')),
              );
            }
          }
        },
        label: const Text('Agregar producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}