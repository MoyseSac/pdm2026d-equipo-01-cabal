import 'package:flutter/material.dart';

import 'ilustracion_catalogo_vacio.dart';

enum EstadoVacio { catalogo, venta, ventas, periodo, archivados }

/// El texto del estado comunica el significado; la imagen es decorativa.
class IlustracionEstadoVacio extends StatelessWidget {
  const IlustracionEstadoVacio({super.key, required this.estado});

  final EstadoVacio estado;

  @override
  Widget build(BuildContext context) {
    if (estado == EstadoVacio.catalogo) {
      return const IlustracionCatalogoVacio();
    }
    final colores = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colores.primary.withValues(alpha: 0.08),
          colores.surface,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Image.asset(
        'assets/icons/estados/${estado.name}.png',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
