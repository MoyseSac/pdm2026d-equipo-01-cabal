import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../providers/tab_provider.dart';
import '../providers/venta_provider.dart';
import '../providers/ventas_filtro_provider.dart';
import '../providers/ventas_registradas_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';

/// Lista de ventas guardadas, con filtro por periodo.
/// Tocar una venta abre su detalle.
class VentasRegistradasScreen extends ConsumerWidget {
  const VentasRegistradasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventas = ref.watch(ventasRegistradasProvider);

    final periodoSeleccionado = ref.watch(ventasFiltroProvider).periodo;

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas registradas')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de periodos.
          _SelectorPeriodo(
            periodoSeleccionado: periodoSeleccionado,
            onSeleccionar: (periodo) {
              ref.read(ventasFiltroProvider.notifier).seleccionar(periodo);
            },
          ),

          const Divider(height: 1),

          // Listado de ventas y estados.
          Expanded(
            child: ventas.when(
              // Conserva la lista visible mientras se
              // actualiza el filtro.
              skipLoadingOnReload: true,

              loading: () => const Center(child: CircularProgressIndicator()),

              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudieron cargar las ventas.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          ref.invalidate(ventasRegistradasProvider);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (lista) {
                if (lista.isEmpty) {
                  // Sin ventas en toda la base de datos.
                  if (periodoSeleccionado == Periodo.todas) {
                    return _SinVentas(
                      onRegistrarVenta: () {
                        ref
                            .read(tabProvider.notifier)
                            .seleccionar(Pestana.vender);
                      },
                    );
                  }

                  // Hay un filtro activo sin resultados.
                  return _SinVentasPeriodo(
                    onVerTodas: () {
                      ref
                          .read(ventasFiltroProvider.notifier)
                          .seleccionar(Periodo.todas);
                    },
                  );
                }

                // Lista con ventas filtradas.
                return ListView.separated(
                  key: const PageStorageKey('ventas_registradas_lista'),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final venta = lista[index];
                    final productos = venta.detalles.length;

                    return ListTile(
                      key: ValueKey(venta.id),
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
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.detalleVenta, arguments: venta);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector horizontal de periodos.
class _SelectorPeriodo extends StatelessWidget {
  final Periodo periodoSeleccionado;
  final ValueChanged<Periodo> onSeleccionar;

  const _SelectorPeriodo({
    required this.periodoSeleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: Periodo.values.map((periodo) {
            final seleccionado = periodoSeleccionado == periodo;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(periodo.etiqueta),
                selected: seleccionado,
                onSelected: (_) {
                  onSeleccionar(periodo);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Estado cuando el periodo seleccionado
/// no tiene ventas.
class _SinVentasPeriodo extends StatelessWidget {
  final VoidCallback onVerTodas;

  const _SinVentasPeriodo({required this.onVerTodas});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay ventas en este período',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba seleccionando otro período '
              'para consultar tus ventas.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onVerTodas,
              icon: const Icon(Icons.list),
              label: const Text('Ver todas'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado cuando no existen ventas registradas.
class _SinVentas extends StatelessWidget {
  final VoidCallback onRegistrarVenta;

  const _SinVentas({required this.onRegistrarVenta});

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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRegistrarVenta,
              icon: const Icon(Icons.add),
              label: const Text('Registrar venta'),
            ),
          ],
        ),
      ),
    );
  }
}
