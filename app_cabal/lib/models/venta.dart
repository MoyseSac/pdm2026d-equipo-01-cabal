import 'detalle_venta.dart';

class Venta {
  final String id;
  final DateTime fechaHora;
  final List<DetalleVenta> detalles;

  const Venta({
    required this.id,
    required this.fechaHora,
    required this.detalles,
  });
}