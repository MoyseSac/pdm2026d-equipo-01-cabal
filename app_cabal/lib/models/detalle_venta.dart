import 'producto.dart';

class DetalleVenta {
  final Producto producto;
  final int cantidad;
  final double precioAlMomento;

  const DetalleVenta({
    required this.producto,
    required this.cantidad,
    required this.precioAlMomento,
  });
}