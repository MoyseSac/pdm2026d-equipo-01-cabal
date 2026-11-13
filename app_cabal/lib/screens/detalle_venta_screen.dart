import 'package:flutter/material.dart';

import '../models/venta.dart';
import '../providers/venta_provider.dart';
import '../utils/fecha.dart';
import '../utils/moneda.dart';
import '../widgets/entrada_ventas.dart';
import '../widgets/producto_imagen_widget.dart';

class DetalleVentaScreen extends StatelessWidget {
  const DetalleVentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final venta = ModalRoute.of(context)?.settings.arguments as Venta?;
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de venta')),
      body: venta == null
          ? const Center(child: Text('No se encontró la venta.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: EntradaVentas(
                      child: ClipPath(
                        clipper: _BordeComprobante(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          color: colores.surfaceContainerLowest,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colores.primaryContainer,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/estados/ventas.png',
                                    width: 40,
                                    height: 40,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Venta registrada',
                                textAlign: TextAlign.center,
                                style: textos.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatearFechaHora(venta.fechaHora),
                                textAlign: TextAlign.center,
                                style: textos.bodyMedium?.copyWith(
                                  color: colores.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _SeparadorComprobante(),
                              const SizedBox(height: 20),
                              Text('Productos', style: textos.titleMedium),
                              const SizedBox(height: 8),
                              for (
                                var index = 0;
                                index < venta.detalles.length;
                                index++
                              )
                                EntradaVentas(
                                  demora: 60 + index.clamp(0, 3) * 45,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ProductoImagenWidget(
                                          imagen: venta
                                              .detalles[index]
                                              .producto
                                              .imagenProducto,
                                          size: 40,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venta
                                                    .detalles[index]
                                                    .producto
                                                    .nombre,
                                                style: textos.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${venta.detalles[index].cantidad} × ${formatearQuetzales(venta.detalles[index].precioAlMomento)}',
                                                style: textos.bodyMedium
                                                    ?.copyWith(
                                                      color: colores
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                formatearQuetzales(
                                                  subtotalDe(
                                                    venta.detalles[index],
                                                  ),
                                                ),
                                                style: textos.titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              const _SeparadorComprobante(),
                              const SizedBox(height: 20),
                              EntradaVentas(
                                demora: 180,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colores.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total',
                                        style: textos.titleMedium?.copyWith(
                                          color: colores.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formatearQuetzales(
                                          totalDe(venta.detalles),
                                        ),
                                        style: textos.headlineMedium?.copyWith(
                                          color: colores.onPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SeparadorComprobante extends StatelessWidget {
  const _SeparadorComprobante();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            (constraints.maxWidth / 12).floor().clamp(1, 100),
            (_) => SizedBox(
              width: 5,
              height: 1,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BordeComprobante extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height - 8),
          topLeft: const Radius.circular(28),
          topRight: const Radius.circular(28),
        ),
      );
    for (var x = 0.0; x < size.width; x += 16) {
      path.addPolygon([
        Offset(x, size.height - 8),
        Offset(x + 8, size.height),
        Offset((x + 16).clamp(0, size.width), size.height - 8),
      ], true);
    }
    return path;
  }

  @override
  bool shouldReclip(_BordeComprobante oldClipper) => false;
}
