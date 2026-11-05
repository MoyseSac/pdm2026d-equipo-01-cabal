import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import 'producto_provider.dart';

/// Unica fuente de la lista de productos. Quien cambie un producto invalida
/// este provider para que todas las pantallas vuelvan a leer la base.
final catalogoProductosProvider = FutureProvider.autoDispose<List<Producto>>((
  ref,
) {
  final productoService = ref.watch(productoServiceProvider);

  return productoService.obtenerProductos();
});

final productosArchivadosProvider = FutureProvider.autoDispose<List<Producto>>((
  ref,
) {
  return ref.watch(productoServiceProvider).obtenerArchivados();
});

/// La misma lista para quien solo la necesita ya cargada (registrar venta).
final productoProvider = Provider.autoDispose<List<Producto>>((ref) {
  return ref.watch(catalogoProductosProvider).value ?? const [];
});
