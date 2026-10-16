import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../providers/venta_provider.dart';
import '../providers/ventas_registradas_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';

/// Lista de las ventas guardadas, de la mas reciente a la mas antigua.
/// Tocar una venta abre su detalle.
class VentasRegistradasScreen extends ConsumerWidget {
  const VentasRegistradasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventas = ref.watch(ventasRegistradasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas registradas')),
      body: ventas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No se pudieron cargar las ventas.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(ventasRegistradasProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const _SinVentas();
          }

          return ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final venta = lista[index];
              final productos = venta.detalles.length;

              return ListTile(
                title: Text(formatearFechaHora(venta.fechaHora)),
                subtitle: Text(
                  productos == 1 ? '1 producto' : '$productos productos',
                ),
                trailing: Text(
                  formatearQuetzales(totalDe(venta.detalles)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.detalleVenta,
                  arguments: venta,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SinVentas extends StatelessWidget {
  const _SinVentas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay ventas registradas',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Las ventas que registres aparecerán aquí.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
