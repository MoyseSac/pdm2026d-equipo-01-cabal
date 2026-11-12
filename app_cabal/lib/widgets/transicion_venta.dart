import 'package:flutter/material.dart';

/// Mantiene la transición fuera de la lógica de venta y retira las acciones
/// salientes del foco, del lector de pantalla y de la interacción táctil.
class TransicionVenta extends StatelessWidget {
  const TransicionVenta({
    super.key,
    required this.child,
    this.desplazar = false,
    this.alignment = Alignment.centerRight,
  });

  final Widget child;
  final bool desplazar;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reducirMovimiento = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reducirMovimiento
          ? Duration.zero
          : const Duration(milliseconds: 200),
      reverseDuration: reducirMovimiento
          ? Duration.zero
          : const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (actual, anteriores) => Stack(
        alignment: alignment,
        children: [
          for (final anterior in anteriores)
            ExcludeFocus(
              child: ExcludeSemantics(child: IgnorePointer(child: anterior)),
            ),
          ?actual,
        ],
      ),
      transitionBuilder: (child, animation) {
        final contenido = FadeTransition(opacity: animation, child: child);
        if (!desplazar) return contenido;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: contenido,
        );
      },
      child: child,
    );
  }
}
