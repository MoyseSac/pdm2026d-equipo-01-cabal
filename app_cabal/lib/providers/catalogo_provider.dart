import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import 'producto_provider.dart';

final catalogoProductosProvider = FutureProvider.autoDispose<List<Producto>>((
  ref,
) {
  final productoService = ref.watch(productoServiceProvider);

  return productoService.obtenerProductos();
});
