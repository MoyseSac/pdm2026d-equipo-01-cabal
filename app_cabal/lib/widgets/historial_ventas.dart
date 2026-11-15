import 'package:flutter/material.dart';

import '../models/venta.dart';
import '../providers/venta_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';
import 'entrada_ventas.dart';
import 'resumen_ventas.dart';

class HistorialVentas extends StatelessWidget {
  const HistorialVentas({
    super.key,
    required this.ventas,
    required this.onAbrir,
    required this.filtro,
  });

  final List<Venta> ventas;
  final String filtro;
  final ValueChanged<Venta> onAbrir;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final total = ventas.fold<double>(
      0,
      (suma, venta) => suma + totalDe(venta.detalles),
    );
    final unidades = ventas.fold<int>(
      0,
      (suma, venta) =>
          suma +
          venta.detalles.fold<int>(
            0,
            (suma, detalle) => suma + detalle.cantidad,
          ),
    );
    return CustomScrollView(
      key: const PageStorageKey('ventas_registradas_lista'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: ResumenVentas(
              total: total,
              ventas: ventas.length,
              unidades: unidades,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              final fecha = formatearFecha(venta.fechaHora);
              final nuevoDia =
                  index == 0 ||
                  fecha != formatearFecha(ventas[index - 1].fechaHora);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (nuevoDia)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
                      child: Text(
                        formatearFechaLarga(venta.fechaHora),
                        style: textos.titleSmall,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EntradaVentas(
                      key: ValueKey('$filtro/${venta.id}'),
                      demora: (index.clamp(0, 3)) * 45,
                      child: Material(
                        color: colores.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onAbrir(venta),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colores.primaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/estados/ventas.png',
                                    width: 28,
                                    height: 28,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatearQuetzales(
                                          totalDe(venta.detalles),
                                        ),
                                        style: textos.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatearFechaHora(venta.fechaHora),
                                        style: textos.bodySmall?.copyWith(
                                          color: colores.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        venta.detalles.length == 1
                                            ? '1 producto'
                                            : '${venta.detalles.length} productos',
                                        style: textos.bodySmall?.copyWith(
                                          color: colores.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
