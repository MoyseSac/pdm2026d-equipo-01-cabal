class Producto {
  final String id;
  final String nombre;
  final double precio;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
  });

  Producto copyWith({String? id, String? nombre, double? precio}) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
    );
  }
}