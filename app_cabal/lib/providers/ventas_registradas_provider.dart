import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/venta.dart';
import 'venta_provider.dart';

/// Ventas guardadas en SQLite, de la mas reciente a la mas antigua. Se
/// vuelve a leer cada vez que se abre la pantalla de ventas registradas.
final ventasRegistradasProvider = FutureProvider.autoDispose<List<Venta>>((
  ref,
) {
  return ref.watch(ventaServiceProvider).obtenerVentas();
});
