import 'package:flutter/material.dart';

import '../constants/iconos_producto.dart';

class IlustracionCatalogoVacio extends StatelessWidget {
  const IlustracionCatalogoVacio({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 264,
          height: 164,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 14,
                top: 32,
                child: Transform.rotate(
                  angle: -0.18,
                  child: _TarjetaProducto(clave: 'pan'),
                ),
              ),
              Positioned(
                right: 14,
                top: 32,
                child: Transform.rotate(
                  angle: 0.18,
                  child: _TarjetaProducto(clave: 'lacteos'),
                ),
              ),
              const Positioned(
                top: 8,
                child: _TarjetaProducto(
                  clave: 'frutas_verduras',
                  principal: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({required this.clave, this.principal = false});

  final String clave;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      width: principal ? 112 : 96,
      height: principal ? 140 : 112,
      decoration: BoxDecoration(
        color: colores.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colores.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colores.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconosProducto[clave]!.asset,
            width: principal ? 64 : 48,
            height: principal ? 64 : 48,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: colores.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
