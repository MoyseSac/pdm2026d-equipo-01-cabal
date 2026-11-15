import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/ilustracion_estado_vacio.dart';
import '../widgets/historial_ventas.dart';
import 'detalle_venta_screen.dart';

import '../constants/app_routes.dart';
import '../providers/tab_provider.dart';
import '../providers/ventas_filtro_provider.dart';
import '../providers/ventas_registradas_provider.dart';

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

          if (ventas.isLoading && ventas.hasValue)
            const LinearProgressIndicator(
              semanticsLabel: 'Actualizando período',
            ),

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
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
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

                return HistorialVentas(
                  ventas: lista,
                  filtro: periodoSeleccionado.name,
                  onAbrir: (venta) {
                    final reducir = MediaQuery.disableAnimationsOf(context);
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        settings: RouteSettings(
                          name: AppRoutes.detalleVenta,
                          arguments: venta,
                        ),
                        transitionDuration: reducir
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        reverseTransitionDuration: reducir
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        pageBuilder: (_, _, _) => const DetalleVentaScreen(),
                        transitionsBuilder: (_, animation, _, child) =>
                            FadeTransition(
                              opacity: animation.drive(
                                CurveTween(curve: Curves.easeOut),
                              ),
                              child: SlideTransition(
                                position:
                                    Tween(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              ),
                            ),
                      ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IlustracionEstadoVacio(estado: EstadoVacio.periodo),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IlustracionEstadoVacio(estado: EstadoVacio.ventas),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
