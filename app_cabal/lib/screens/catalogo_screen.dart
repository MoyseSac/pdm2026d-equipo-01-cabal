import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../providers/catalogo_provider.dart';
import '../utils/moneda.dart';
import '../widgets/catalogo_vacio_widget.dart';

class CatalogoScreen extends ConsumerWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProductosProvider);

    Future<void> abrirAgregarProducto() async {
      final result = await Navigator.of(
        context,
      ).pushNamed(AppRoutes.agregarProducto);

      if (!context.mounted) return;

      // Actualiza el catálogo al regresar del formulario.
      ref.invalidate(catalogoProductosProvider);

      if (result == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto agregado')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Ventas registradas',
            icon: const Icon(Icons.receipt_long),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.ventasRegistradas),
          ),
        ],
      ),

      // Manejo de los cuatro estados del catálogo.
      body: catalogo.when(
        // ESTADO 1: CARGANDO
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando productos...'),
            ],
          ),
        ),

        // ESTADO 2: ERROR
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No se pudieron cargar los productos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(catalogoProductosProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),

        // ESTADOS 3 Y 4: VACÍO O DATOS
        data: (productos) {
          if (productos.isEmpty) {
            return CatalogoVacioWidget(onAgregarProducto: abrirAgregarProducto);
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 215,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];

                    return Card(
                      child: InkWell(
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.registrarVenta),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
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
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
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
                                    formatearQuetzales(producto.precio),
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
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agregar',
        onPressed: abrirAgregarProducto,
        label: const Text('Agregar producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
