import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';

/// Hoja con los productos archivados, cada uno con su boton para restaurar.
Future<void> mostrarArchivados(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ArchivadosSheet(),
  );
}

class _ArchivadosSheet extends ConsumerWidget {
  const _ArchivadosSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivados = ref.watch(productosArchivadosProvider);

    return SafeArea(
      child: archivados.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No se pudieron cargar los productos archivados.'),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text('No tienes productos archivados.'),
            );
          }

          return ListView(
            shrinkWrap: true,
            children: [
              for (final producto in lista)
                ListTile(
                  title: Text(producto.nombre),
                  subtitle: const Text('Archivado'),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref
                          .read(productoServiceProvider)
                          .desarchivarProducto(producto);
                      ref.invalidate(productosArchivadosProvider);
                      ref.invalidate(catalogoProductosProvider);
                    },
                    child: const Text('Restaurar'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
