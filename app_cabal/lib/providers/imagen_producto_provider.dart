import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/imagen_producto_service.dart';

final imagenProductoServiceProvider = Provider<ImagenProductoService>((ref) {
  return ImagenProductoService();
});

/// Se resuelve una sola vez para todas las filas del catalogo.
final carpetaImagenesProvider = FutureProvider<Directory>((ref) {
  return ref.watch(imagenProductoServiceProvider).carpeta();
});
