import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';
import '../utils/moneda.dart';

/// Productos archivados: salen del catalogo pero conservan sus ventas.
/// Desde aqui se restauran.
class ArchivadosScreen extends ConsumerWidget {
  const ArchivadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivados = ref.watch(productosArchivadosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archivados')),
      body: archivados.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No se pudieron cargar los productos archivados.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(productosArchivadosProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No tienes productos archivados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final producto = lista[index];

              return Card(
                child: ListTile(
                  title: Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(formatearQuetzales(producto.precio)),
                  trailing: TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(productoServiceProvider)
                          .desarchivarProducto(producto);
                      ref.invalidate(productosArchivadosProvider);
                      ref.invalidate(catalogoProductosProvider);
                    },
                    icon: const Icon(Icons.unarchive_outlined),
                    label: const Text('Restaurar'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
