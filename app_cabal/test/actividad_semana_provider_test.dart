import 'package:app_cabal/models/actividad_ventas.dart';
import 'package:app_cabal/models/cierre.dart';
import 'package:app_cabal/providers/cierre_provider.dart';
import 'package:app_cabal/providers/ventas_filtro_provider.dart';
import 'package:app_cabal/services/cierre_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Servicio extends CierreService {
  int centavos = 100;
  int consultas = 0;
  @override
  Future<Cierre> calcularDia(DateTime dia) async => Cierre(
    dia: dia,
    numeroVentas: 1,
    total: centavos / 100,
    productos: const [],
  );
  @override
  Future<Cierre?> obtenerCierre(DateTime dia) async => null;
  @override
  Future<List<ActividadVentasDia>> actividadSemana(DateTime hoy) async {
    consultas++;
    return List.generate(
      7,
      (i) => ActividadVentasDia(
        dia: DateTime(hoy.year, hoy.month, hoy.day - 6 + i),
        ventas: i == 6 ? 1 : 0,
        centavos: i == 6 ? centavos : 0,
      ),
    );
  }
}

void main() {
  test(
    'la actividad semanal se actualiza cuando se vuelve a leer el cierre',
    () async {
      final servicio = _Servicio();
      final container = ProviderContainer(
        overrides: [
          cierreServiceProvider.overrideWithValue(servicio),
          fechaActualVentasProvider.overrideWithValue(
            () => DateTime(2026, 11, 13),
          ),
        ],
      );
      final suscripcion = container.listen(actividadSemanaProvider, (_, _) {});
      addTearDown(() {
        suscripcion.close();
        container.dispose();
      });
      expect(
        (await container.read(actividadSemanaProvider.future)).last.centavos,
        100,
      );
      servicio.centavos = 250;
      container.invalidate(cierreHoyProvider);
      expect(
        (await container.read(actividadSemanaProvider.future)).last.centavos,
        250,
      );
      expect(servicio.consultas, 2);
    },
  );
}
