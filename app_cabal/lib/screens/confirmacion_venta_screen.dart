import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tab_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';

/// Pantalla de confirmacion de venta. Se muestra solo cuando la venta se
/// guardo correctamente. Permite empezar otra venta de inmediato o volver
/// al catalogo.
class ConfirmacionVentaScreen extends ConsumerWidget {
  const ConfirmacionVentaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venta = ref.watch(ventaProvider).ventaConfirmada;

    return Scaffold(
      appBar: AppBar(title: const Text('Venta confirmada')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Venta registrada',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (venta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${formatearQuetzales(totalDe(venta.detalles))}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _nuevaVenta(context, ref),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Nueva venta'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _irAPestana(context, ref, Pestana.catalogo),
                    child: const Text('Volver al catálogo'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _irAPestana(context, ref, Pestana.ventas),
                    child: const Text('Ver ventas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Regresa a registrar venta, que queda sin productos y con total Q0.00.
  void _nuevaVenta(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ventaProvider.notifier);
    Navigator.of(context).pop();
    notifier.limpiar();
  }

  /// Desapila registrar venta y esta confirmacion hasta la barra de
  /// navegacion y muestra la pestana pedida.
  void _irAPestana(BuildContext context, WidgetRef ref, Pestana pestana) {
    ref.read(tabProvider.notifier).seleccionar(pestana);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
