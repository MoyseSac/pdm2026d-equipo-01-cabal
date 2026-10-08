import 'package:app_cabal/models/producto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductoNotifier extends StateNotifier<List<Producto>> {
  ProductoNotifier()
      : super([
          Producto(id: '1', nombre: 'Laptop Dell', precio: 799.99),
          Producto(id: '2', nombre: 'Mouse Logitech', precio: 29.99),
          Producto(id: '3', nombre: 'Teclado Mecánico', precio: 129.99),
          Producto(id: '4', nombre: 'Monitor LG 24"', precio: 199.99),
        ]);

  void addProducto(String nombre, double precio) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevoProducto = Producto(id: id, nombre: nombre, precio: precio);
    state = [...state, nuevoProducto];
  }
}

final productoProvider = StateNotifierProvider<ProductoNotifier, List<Producto>>(
  (ref) => ProductoNotifier(),
);   
