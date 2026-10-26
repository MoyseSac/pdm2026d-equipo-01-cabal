import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/providers/ventas_filtro_provider.dart';
import 'package:app_cabal/screens/ventas_registradas_screen.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _producto = Producto(id: 'p1', nombre: 'Producto de prueba', precio: 10);

/// Crea una venta de prueba con una fecha determinada.
Venta _crearVenta(String id, DateTime fecha) {
  return Venta(
    id: id,
    fechaHora: fecha,
    detalles: const [
      DetalleVenta(producto: _producto, cantidad: 1, precioAlMomento: 10),
    ],
  );
}

/// Servicio simulado para comprobar los filtros.
///
/// Utiliza los mismos limites de fechas que
/// el servicio real de SQLite.
class _FakeVentaService extends VentaService {
  final List<Venta> datos;
  bool fallar;
  int consultas = 0;

  _FakeVentaService(this.datos, {this.fallar = false});

  @override
  Future<List<Venta>> obtenerVentas({
    DateTime? desde,
    DateTime? hastaExclusivo,
  }) async {
    consultas++;

    if (fallar) {
      throw Exception('Error simulado de SQLite');
    }

    return datos.where((venta) {
      final fecha = venta.fechaHora;

      if (desde != null && fecha.isBefore(desde)) {
        return false;
      }

      if (hastaExclusivo != null && !fecha.isBefore(hastaExclusivo)) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Abre directamente la pantalla de ventas.
///
/// Se utiliza una fecha fija para evitar que
/// las pruebas dependan del reloj real.
Future<void> _abrirPantalla(
  WidgetTester tester,
  _FakeVentaService servicio,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;

  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ventaServiceProvider.overrideWithValue(servicio),
        fechaActualVentasProvider.overrideWithValue(
          () => DateTime(2026, 10, 26, 12),
        ),
      ],
      child: const MaterialApp(home: VentasRegistradasScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

/// Selecciona un periodo del filtro.
///
/// CORRECCION:
/// Algunos filtros pueden quedar fuera de la
/// pantalla debido al desplazamiento horizontal.
///
/// ensureVisible desplaza el selector antes de
/// intentar presionar el chip.
Future<void> _seleccionarPeriodo(WidgetTester tester, String etiqueta) async {
  final chip = find.text(etiqueta);

  // Verifica que exista el filtro.
  expect(chip, findsOneWidget);

  // Desplaza horizontalmente si es necesario.
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();

  // Selecciona el filtro.
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('Filtro de ventas - pruebas de widget', () {
    testWidgets('cambiar el filtro actualiza la lista automaticamente', (
      tester,
    ) async {
      final servicio = _FakeVentaService([
        _crearVenta('hoy', DateTime(2026, 10, 26, 9)),
        _crearVenta('ayer', DateTime(2026, 10, 25, 17)),
        _crearVenta('inicio_mes', DateTime(2026, 10, 1, 8)),
        _crearVenta('mes_anterior', DateTime(2026, 9, 28, 10)),
      ]);

      await _abrirPantalla(tester, servicio);

      // ESTADO INICIAL: TODAS
      // Deben aparecer todas las ventas.
      expect(find.text('26/10/2026 09:00'), findsOneWidget);

      expect(find.text('25/10/2026 17:00'), findsOneWidget);

      expect(find.text('28/09/2026 10:00'), findsOneWidget);

      // FILTRO: HOY
      await _seleccionarPeriodo(tester, 'Hoy');

      expect(find.text('26/10/2026 09:00'), findsOneWidget);

      expect(find.text('25/10/2026 17:00'), findsNothing);

      expect(find.text('28/09/2026 10:00'), findsNothing);

      // FILTRO: ULTIMOS 7 DIAS
      await _seleccionarPeriodo(tester, 'Últimos 7 días');

      expect(find.text('26/10/2026 09:00'), findsOneWidget);

      expect(find.text('25/10/2026 17:00'), findsOneWidget);

      expect(find.text('01/10/2026 08:00'), findsNothing);

      // FILTRO: ESTE MES
      // ensureVisible evita el error del chip
      // fuera de la pantalla.
      await _seleccionarPeriodo(tester, 'Este mes');

      expect(find.text('26/10/2026 09:00'), findsOneWidget);

      expect(find.text('01/10/2026 08:00'), findsOneWidget);

      expect(find.text('28/09/2026 10:00'), findsNothing);

      // FILTRO: TODAS
      await _seleccionarPeriodo(tester, 'Todas');

      expect(find.text('26/10/2026 09:00'), findsOneWidget);

      expect(find.text('28/09/2026 10:00'), findsOneWidget);

      // Una consulta inicial y cuatro cambios.
      // No se utiliza ningun boton Recargar.
      expect(servicio.consultas, greaterThanOrEqualTo(5));
    });

    testWidgets('un periodo sin ventas muestra el estado vacio', (
      tester,
    ) async {
      final servicio = _FakeVentaService([
        _crearVenta('venta_antigua', DateTime(2026, 9, 10, 8)),
      ]);

      await _abrirPantalla(tester, servicio);

      // Inicialmente aparece la venta.
      expect(find.text('10/09/2026 08:00'), findsOneWidget);

      // Seleccionamos Hoy, que no tiene ventas.
      await _seleccionarPeriodo(tester, 'Hoy');

      expect(find.text('No hay ventas en este período'), findsOneWidget);

      expect(find.text('10/09/2026 08:00'), findsNothing);

      expect(find.text('Ver todas'), findsOneWidget);

      // Restauramos el listado completo.
      await tester.tap(find.text('Ver todas'));
      await tester.pumpAndSettle();

      expect(find.text('10/09/2026 08:00'), findsOneWidget);

      expect(find.text('No hay ventas en este período'), findsNothing);
    });

    testWidgets('sin ninguna venta aparece el estado vacio general', (
      tester,
    ) async {
      final servicio = _FakeVentaService([]);

      await _abrirPantalla(tester, servicio);

      expect(find.text('Aún no hay ventas registradas'), findsOneWidget);

      expect(find.text('Registrar venta'), findsOneWidget);

      // El estado vacio general no debe mostrar
      // el mensaje especifico del filtro.
      expect(find.text('No hay ventas en este período'), findsNothing);
    });

    testWidgets('un error permite reintentar la consulta', (tester) async {
      final servicio = _FakeVentaService([
        _crearVenta('venta1', DateTime(2026, 10, 26, 10)),
      ], fallar: true);

      await _abrirPantalla(tester, servicio);

      // El servicio inicialmente falla.
      expect(find.text('No se pudieron cargar las ventas.'), findsOneWidget);

      expect(find.text('Reintentar'), findsOneWidget);

      // Simulamos que el servicio vuelve a funcionar.
      servicio.fallar = false;

      // Presionamos Reintentar.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // La venta debe aparecer correctamente.
      expect(find.text('26/10/2026 10:00'), findsOneWidget);

      // El mensaje de error debe desaparecer.
      expect(find.text('No se pudieron cargar las ventas.'), findsNothing);

      // Confirma que se realizaron nuevas consultas.
      expect(servicio.consultas, greaterThanOrEqualTo(2));
    });
  });
}
