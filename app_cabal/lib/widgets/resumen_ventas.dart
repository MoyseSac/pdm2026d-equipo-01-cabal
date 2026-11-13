import 'package:flutter/material.dart';

import '../utils/moneda.dart';

class ResumenVentas extends StatelessWidget {
  const ResumenVentas({
    super.key,
    required this.total,
    required this.ventas,
    required this.unidades,
  });

  final double total;
  final int ventas;
  final int unidades;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colores.secondary, colores.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total vendido',
            style: textos.titleMedium?.copyWith(color: colores.onPrimary),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Total vendido: ${formatearQuetzales(total)}',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 480),
                tween: Tween(begin: 0, end: total),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => Text(
                  formatearQuetzales(valor),
                  style: textos.headlineLarge?.copyWith(
                    color: colores.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Dato(texto: ventas == 1 ? '1 venta' : '$ventas ventas'),
              _Dato(texto: unidades == 1 ? '1 unidad' : '$unidades unidades'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colores.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: colores.onPrimary),
      ),
    );
  }
}
