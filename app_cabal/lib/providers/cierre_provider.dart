import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cierre.dart';
import '../services/cierre_service.dart';
import 'ventas_filtro_provider.dart';

final cierreServiceProvider = Provider<CierreService>((ref) {
  return CierreService();
});

/// El cierre de hoy: el calculo en vivo y, si ya se cerro, la foto guardada.
///
/// No usa el filtro de la pestana Ventas: el cierre siempre es del dia de
/// hoy, sin importar que periodo este elegido alla. El reloj es el mismo
/// inyectable que usan las ventas, para poder probar con una fecha fija.
final cierreHoyProvider = FutureProvider.autoDispose<CierreHoy>((ref) async {
  final servicio = ref.watch(cierreServiceProvider);
  final ahora = ref.watch(fechaActualVentasProvider)();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);

  final enVivo = await servicio.calcularDia(hoy);
  final guardado = await servicio.obtenerCierre(hoy);

  return CierreHoy(enVivo: enVivo, guardado: guardado);
});

/// Acciones del cierre. Quien guarda es el servicio; despues se invalida
/// [cierreHoyProvider] para que vuelva a leer la base, en vez de armar a
/// mano el estado nuevo (una sola fuente de verdad: la base).
class CierreAcciones {
  final Ref _ref;

  CierreAcciones(this._ref);

  Future<void> cerrarHoy() async {
    final ahora = _ref.read(fechaActualVentasProvider)();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    await _ref.read(cierreServiceProvider).cerrarDia(hoy, cerradoEn: ahora);

    _ref.invalidate(cierreHoyProvider);
  }
}

final cierreAccionesProvider = Provider<CierreAcciones>(CierreAcciones.new);
