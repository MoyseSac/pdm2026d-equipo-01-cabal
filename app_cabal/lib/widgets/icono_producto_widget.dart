import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/iconos_producto.dart';

class IconoProductoWidget extends StatelessWidget {
  const IconoProductoWidget({
    super.key,
    required this.clave,
    this.size = 48,
    this.excluirSemantica = false,
  });

  final String clave;
  final double size;
  final bool excluirSemantica;

  @override
  Widget build(BuildContext context) {
    final categoria = iconosProducto[clave]!;
    final colores = Theme.of(context).colorScheme;
    final tamanoDibujo = math.min(size * 0.75, 48.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          categoria.color.withValues(alpha: 0.14),
          colores.surface,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        categoria.asset,
        width: tamanoDibujo,
        height: tamanoDibujo,
        fit: BoxFit.contain,
        semanticLabel: excluirSemantica ? null : categoria.etiqueta,
        excludeFromSemantics: excluirSemantica,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
