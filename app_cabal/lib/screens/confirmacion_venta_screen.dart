import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';

/// Pantalla de confirmacion de venta. Segun el diagrama (#4), desde aqui
/// se vuelve al catalogo, no se sigue apilando la navegacion (la venta
/// registrada, agregar-producto, y registrar-venta ya cumplieron su
/// proposito), por eso se usa pushNamedAndRemoveUntil para limpiar la
/// pila hasta el catalogo.
class ConfirmacionVentaScreen extends ConsumerWidget {
  const ConfirmacionVentaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venta = ref.watch(ventaProvider).ventaConfirmada;

    return Scaffold(
      appBar: AppBar(title: const Text('Venta confirmada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Venta registrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (venta != null) ...[
              const SizedBox(height: 8),
              Text('Total: ${formatearQuetzales(totalDe(venta.detalles))}'),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.catalogo,
                  (route) =>
                      route.settings.name == AppRoutes.catalogo ||
                      route.isFirst,
                );
              },
              child: const Text('Volver al catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
