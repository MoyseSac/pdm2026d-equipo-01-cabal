import 'package:flutter/material.dart';

import '../models/venta.dart';
import '../providers/venta_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';

/// Detalle de una venta guardada: fecha, productos con cantidad, precio al
/// momento y subtotal, y el total. Recibe la Venta como argumento de ruta.
class DetalleVentaScreen extends StatelessWidget {
  const DetalleVentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final venta = ModalRoute.of(context)?.settings.arguments as Venta?;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de venta')),
      body: venta == null
          ? const Center(child: Text('No se encontró la venta.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatearFechaHora(venta.fechaHora),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: venta.detalles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final detalle = venta.detalles[index];

                      return ListTile(
                        title: Text(detalle.producto.nombre),
                        subtitle: Text(
                          '${detalle.cantidad} × '
                          '${formatearQuetzales(detalle.precioAlMomento)}',
                        ),
                        trailing: Text(
                          formatearQuetzales(subtotalDe(detalle)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatearQuetzales(totalDe(venta.detalles)),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
