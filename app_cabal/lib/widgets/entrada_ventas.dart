import 'package:flutter/material.dart';

/// Entrada breve de un bloque; no vuelve a ejecutarse al reconstruirlo.
class EntradaVentas extends StatelessWidget {
  const EntradaVentas({super.key, required this.child, this.demora = 0});

  final Widget child;
  final int demora;

  @override
  Widget build(BuildContext context) {
    final reducir = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reducir ? Duration.zero : Duration(milliseconds: 360 + demora),
      tween: Tween(begin: 0, end: 1),
      curve: Interval(demora / (360 + demora), 1, curve: Curves.easeOutCubic),
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - valor)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
