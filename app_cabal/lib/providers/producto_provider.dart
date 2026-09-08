import 'package:app_cabal/models/producto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductoNotifier extends StateNotifier<List<Producto>> {
  // We initialize the list of productos to an empty list
  ProductoNotifier(): super([]);

  // Let's allow the UI to add todos.
  void addProducto(String nombre, double precio) {

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevoProducto = Producto(id: id, nombre: nombre, precio: precio);
    state = [...state, nuevoProducto];

  }
} 

final productoProvider = StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
  return ProductoNotifier();
});   
