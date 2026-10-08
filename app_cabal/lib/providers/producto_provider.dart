import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import '../services/producto_service.dart';

final productoServiceProvider = Provider<ProductoService>((ref) {
  return ProductoService();
});

final productoProvider =
    StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
  final productoService = ref.watch(productoServiceProvider);

  return ProductoNotifier(productoService);
});

class ProductoNotifier extends StateNotifier<List<Producto>> {
  final ProductoService _productoService;

  ProductoNotifier(this._productoService) : super([]) {
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    state = await _productoService.obtenerProductos();
  }

  Future<void> agregarProducto(Producto producto) async {
    await _productoService.crearProducto(producto);

    state = await _productoService.obtenerProductos();
  }

  Future<void> editarProducto(Producto producto) async {
    await _productoService.actualizarProducto(producto);

    state = await _productoService.obtenerProductos();
  }
}