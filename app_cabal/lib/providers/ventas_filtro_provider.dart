import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Periodos disponibles para filtrar las ventas.
enum Periodo { todas, hoy, ultimos7Dias, esteMes }

/// Nombre que se muestra en la interfaz.
extension PeriodoEtiqueta on Periodo {
  String get etiqueta {
    switch (this) {
      case Periodo.todas:
        return 'Todas';
      case Periodo.hoy:
        return 'Hoy';
      case Periodo.ultimos7Dias:
        return 'Últimos 7 días';
      case Periodo.esteMes:
        return 'Este mes';
    }
  }
}

/// Rango con inicio inclusivo y final exclusivo.
class RangoVentas {
  final DateTime desde;
  final DateTime hastaExclusivo;

  const RangoVentas({required this.desde, required this.hastaExclusivo});
}

/// Objeto inmutable que representa el filtro seleccionado.
class VentasFiltro {
  final Periodo periodo;

  const VentasFiltro({this.periodo = Periodo.todas});

  /// Calcula el rango usando una fecha recibida.
  /// Esto permite realizar pruebas sin depender del reloj real.
  RangoVentas? calcularRango(DateTime ahora) {
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);

    final inicioManana = DateTime(ahora.year, ahora.month, ahora.day + 1);

    switch (periodo) {
      case Periodo.todas:
        return null;

      case Periodo.hoy:
        return RangoVentas(desde: inicioHoy, hastaExclusivo: inicioManana);

      case Periodo.ultimos7Dias:
        return RangoVentas(
          desde: DateTime(ahora.year, ahora.month, ahora.day - 6),
          hastaExclusivo: inicioManana,
        );

      case Periodo.esteMes:
        return RangoVentas(
          desde: DateTime(ahora.year, ahora.month, 1),
          hastaExclusivo: DateTime(ahora.year, ahora.month + 1, 1),
        );
    }
  }
}

/// Administra el periodo seleccionado.
/// Cada cambio crea un nuevo objeto inmutable.
class VentasFiltroNotifier extends Notifier<VentasFiltro> {
  @override
  VentasFiltro build() {
    return const VentasFiltro();
  }

  void seleccionar(Periodo periodo) {
    if (state.periodo == periodo) return;

    state = VentasFiltro(periodo: periodo);
  }
}

/// Provider global del filtro.
final ventasFiltroProvider =
    NotifierProvider<VentasFiltroNotifier, VentasFiltro>(
      VentasFiltroNotifier.new,
    );

/// Reloj inyectable para facilitar las pruebas.
final fechaActualVentasProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});
