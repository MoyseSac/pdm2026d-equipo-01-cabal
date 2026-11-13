import 'package:flutter/material.dart';

/// Un error permanece junto a la acción hasta que se corrige o se reintenta.
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea({super.key, required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colores.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline,
                size: 20,
                color: colores.onErrorContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colores.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
