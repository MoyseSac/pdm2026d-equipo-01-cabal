import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../constants/iconos_producto.dart';
import '../models/imagen_producto.dart';
import '../providers/imagen_producto_provider.dart';

/// Cuadro de imagen de un producto. Si la foto no se puede leer (borrada,
/// o la carpeta aun no se resuelve) o el icono no esta en el registro, se
/// dibuja el icono generico en lugar de un error.
class ProductoImagenWidget extends ConsumerWidget {
  const ProductoImagenWidget({super.key, required this.imagen, this.size = 48});

  final ImagenProducto imagen;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (imagen) {
        FotoElegida(:final archivo) => _foto(context, ref, archivo),
        IconoElegido(:final clave) => _icono(
          iconosProducto[clave]?.icono ?? iconoProductoGenerico,
          colores.onSurfaceVariant,
        ),
        SinImagen() => _generico(colores),
      },
    );
  }

  Widget _foto(BuildContext context, WidgetRef ref, String archivo) {
    final carpeta = ref.watch(carpetaImagenesProvider).valueOrNull;
    if (carpeta == null) return _generico(Theme.of(context).colorScheme);

    return Image.file(
      File(p.join(carpeta.path, archivo)),
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => _generico(Theme.of(context).colorScheme),
    );
  }

  Widget _generico(ColorScheme colores) =>
      _icono(iconoProductoGenerico, colores.onSurfaceVariant);

  Widget _icono(IconData icono, Color color) =>
      Icon(icono, color: color, size: size * 0.55);
}
