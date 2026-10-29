import 'imagen_producto.dart';

class Producto {
  final String id;
  final String nombre;
  final double precio;

  /// Nombre del archivo de la foto, nunca la ruta completa.
  final String? imagen;

  /// Clave del registro de iconos.
  final String? icono;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    this.imagen,
    this.icono,
  }) : assert(
         imagen == null || icono == null,
         'Un producto tiene foto o icono, no ambos.',
       );

  ImagenProducto get imagenProducto {
    final foto = imagen;
    if (foto != null) return FotoElegida(foto);
    final clave = icono;
    if (clave != null) return IconoElegido(clave);
    return const SinImagen();
  }

  /// [imagenProducto] reemplaza foto e icono juntos; sin el, se conservan.
  Producto copyWith({
    String? id,
    String? nombre,
    double? precio,
    ImagenProducto? imagenProducto,
  }) {
    final eleccion = imagenProducto ?? this.imagenProducto;
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      imagen: eleccion.archivoFoto,
      icono: eleccion.claveIcono,
    );
  }
}
