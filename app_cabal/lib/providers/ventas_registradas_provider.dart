import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/venta.dart';
import 'venta_provider.dart';
import 'ventas_filtro_provider.dart';

/// Ventas guardadas en SQLite, ordenadas de la mas reciente
/// a la mas antigua.
///
/// Este provider depende del filtro seleccionado.
/// Cuando cambia el periodo, Riverpod repite la consulta
/// automaticamente, sin necesidad de un boton Recargar.
final ventasRegistradasProvider = FutureProvider.autoDispose<List<Venta>>((
  ref,
) {
  // Escucha el filtro actual.
  final filtro = ref.watch(ventasFiltroProvider);

  // Obtiene el servicio existente.
  final servicio = ref.watch(ventaServiceProvider);

  // Reloj inyectable para pruebas.
  final ahora = ref.watch(fechaActualVentasProvider)();

  // Calcula el rango correspondiente.
  final rango = filtro.calcularRango(ahora);

  // Consulta SQLite con el rango seleccionado.
  // Para "Todas", ambos parametros son null.
  return servicio.obtenerVentas(
    desde: rango?.desde,
    hastaExclusivo: rango?.hastaExclusivo,
  );
});
