import 'dart:async';

import 'package:app_cabal/models/cierre.dart';
import 'package:app_cabal/providers/cierre_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/ventas_filtro_provider.dart';
import 'package:app_cabal/screens/cierre_dia_screen.dart';
import 'package:app_cabal/services/cierre_service.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:app_cabal/utils/fecha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _hoy = DateTime(2026, 10, 26, 18, 30);

const _cola = CierreProducto(
  productoId: 'cola',
  nombre: 'Coca Cola',
  unidades: 3,
  subtotal: 31.5,
);
const _pan = CierreProducto(
  productoId: 'pan',
  nombre: 'Pan dulce',
  unidades: 1,
  subtotal: 2.5,
);

/// Servicio falso con el estado del dia en memoria: lo que "se vendio" y, si
/// ya se cerro, la foto guardada.
class _FakeCierreService extends CierreService {
  int numeroVentas;
  double total;
  List<CierreProducto> productos;
  Cierre? guardado;
  bool fallarAlLeer = false;
  bool fallarAlCerrar = false;
  Completer<void>? esperarLectura;
  int lecturas = 0;
  int cierres = 0;

  _FakeCierreService({
    this.numeroVentas = 0,
    this.total = 0,
    this.productos = const [],
    this.guardado,
  });

  @override
  Future<Cierre> calcularDia(DateTime dia) async {
    lecturas++;
    await esperarLectura?.future;
    if (fallarAlLeer) throw Exception('fallo simulado');
    return Cierre(
      dia: DateTime(dia.year, dia.month, dia.day),
      numeroVentas: numeroVentas,
      total: total,
      productos: productos,
    );
  }

  @override
  Future<Cierre?> obtenerCierre(DateTime dia) async => guardado;

  @override
  Future<Cierre> cerrarDia(DateTime dia, {DateTime? cerradoEn}) async {
    if (fallarAlCerrar) throw Exception('fallo simulado');
    cierres++;
    guardado = Cierre(
      id: 'c$cierres',
      dia: DateTime(dia.year, dia.month, dia.day),
      cerradoEn: cerradoEn,
      numeroVentas: numeroVentas,
      total: total,
      productos: productos,
    );
    return guardado!;
  }
}

Future<ProviderContainer> _abrir(
  WidgetTester tester,
  _FakeCierreService servicio,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      cierreServiceProvider.overrideWithValue(servicio),
      fechaActualVentasProvider.overrideWithValue(() => _hoy),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: temaCabal, home: const CierreDiaScreen()),
    ),
  );
  await tester.pump();
  return container;
}

/// Toca el boton y confirma en el dialogo.
Future<void> _cerrarYConfirmar(WidgetTester tester, String boton) async {
  await tester.tap(find.text(boton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sí, cerrar'));
  await tester.pumpAndSettle();
}

_FakeCierreService _conVentas() => _FakeCierreService(
  numeroVentas: 2,
  total: 34.0,
  productos: const [_cola, _pan],
);

void main() {
  test('formatearFecha usa dd/mm/aaaa', () {
    expect(formatearFecha(DateTime(2026, 10, 15, 21, 5)), '15/10/2026');
    expect(formatearFecha(DateTime(2026, 1, 2)), '02/01/2026');
  });

  testWidgets('mientras lee muestra el indicador de carga', (tester) async {
    final servicio = _conVentas()..esperarLectura = Completer<void>();
    await _abrir(tester, servicio);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cerrar día'), findsNothing);

    servicio.esperarLectura!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Cerrar día'), findsOneWidget);
  });

  testWidgets('si falla la lectura informa y permite reintentar', (
    tester,
  ) async {
    final servicio = _conVentas()..fallarAlLeer = true;
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el cierre del día.'), findsOneWidget);
    expect(find.text('Cerrar día'), findsNothing);

    servicio.fallarAlLeer = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el cierre del día.'), findsNothing);
    expect(find.text('Total del día'), findsOneWidget);
  });

  testWidgets('sin ventas hoy muestra el estado vacío y no deja cerrar', (
    tester,
  ) async {
    await _abrir(tester, _FakeCierreService());
    await tester.pumpAndSettle();

    expect(find.text('Hoy no hay ventas para cerrar'), findsOneWidget);
    expect(find.text('Cerrar día'), findsNothing);
    expect(find.text('Total del día'), findsNothing);
  });

  testWidgets('el estado vacío lleva a registrar una venta', (tester) async {
    final container = await _abrir(tester, _FakeCierreService());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar venta'));
    await tester.pump();

    expect(container.read(tabProvider), Pestana.vender);
  });

  testWidgets('con ventas muestra total, número de ventas, vendidos y sin '
      'vender', (tester) async {
    await _abrir(tester, _conVentas());
    await tester.pumpAndSettle();

    expect(find.text('26/10/2026'), findsOneWidget);
    expect(find.text('Total del día'), findsOneWidget);
    expect(find.text('Q34.00'), findsOneWidget);
    expect(find.text('2 ventas'), findsOneWidget);

    expect(find.text('Vendidos (2)'), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('3 unidades'), findsOneWidget);
    expect(find.text('Q31.50'), findsOneWidget);
    expect(find.text('Pan dulce'), findsOneWidget);
    expect(find.text('1 unidad'), findsOneWidget);
    expect(find.text('Q2.50'), findsOneWidget);

    // El cierre de caja no lista lo que no se vendio.
    expect(find.textContaining('Sin vender'), findsNothing);

    expect(find.text('Cerrar día'), findsOneWidget);
    expect(find.text('Volver a cerrar'), findsNothing);
  });

  testWidgets('una sola venta se escribe en singular', (tester) async {
    await _abrir(
      tester,
      _FakeCierreService(numeroVentas: 1, total: 2.5, productos: const [_pan]),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 venta'), findsOneWidget);
  });

  testWidgets('tocar Cerrar día guarda y la pantalla pasa a cerrado', (
    tester,
  ) async {
    final servicio = _conVentas();
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    await _cerrarYConfirmar(tester, 'Cerrar día');

    expect(servicio.cierres, 1);
    expect(servicio.guardado, isNotNull);
    expect(find.text('Día cerrado el 26/10/2026 18:30.'), findsOneWidget);
    expect(find.text('Cerrar día'), findsNothing);
    expect(find.text('Volver a cerrar'), findsNothing);
    expect(find.text('Q34.00'), findsOneWidget);
  });

  testWidgets('tocar Cerrar día pide confirmar y no guarda hasta aceptar', (
    tester,
  ) async {
    final servicio = _conVentas();
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar día'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar el día?'), findsOneWidget);
    expect(
      find.text(
        'Se guardará el cierre de hoy con 2 ventas y un total de Q34.00.',
      ),
      findsOneWidget,
    );
    expect(servicio.cierres, 0);
  });

  testWidgets('cancelar la confirmación no cierra el día', (tester) async {
    final servicio = _conVentas();
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar día'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(servicio.cierres, 0);
    expect(servicio.guardado, isNull);
    expect(find.text('¿Cerrar el día?'), findsNothing);
    expect(find.text('Cerrar día'), findsOneWidget);
  });

  testWidgets('volver a cerrar avisa que reemplaza el cierre anterior', (
    tester,
  ) async {
    final servicio = _FakeCierreService(
      numeroVentas: 3,
      total: 40.0,
      productos: const [_cola, _pan],
      guardado: Cierre(
        id: 'c0',
        dia: DateTime(2026, 10, 26),
        cerradoEn: DateTime(2026, 10, 26, 17),
        numeroVentas: 2,
        total: 34.0,
        productos: const [_cola, _pan],
      ),
    );
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Volver a cerrar el día?'), findsOneWidget);
    expect(
      find.textContaining('Reemplaza el cierre anterior.'),
      findsOneWidget,
    );
    expect(servicio.cierres, 0);
  });

  testWidgets('si falla al cerrar avisa y deja intentar de nuevo', (
    tester,
  ) async {
    final servicio = _conVentas()..fallarAlCerrar = true;
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    await _cerrarYConfirmar(tester, 'Cerrar día');

    expect(find.text(mensajeErrorCierre), findsOneWidget);
    expect(find.text('Cerrar día'), findsOneWidget);

    servicio.fallarAlCerrar = false;
    await _cerrarYConfirmar(tester, 'Cerrar día');

    expect(servicio.cierres, 1);
    expect(find.text('Día cerrado el 26/10/2026 18:30.'), findsOneWidget);
  });

  testWidgets('ya cerrado y sin cambios muestra la foto guardada', (
    tester,
  ) async {
    final servicio = _conVentas();
    servicio.guardado = Cierre(
      id: 'c0',
      dia: DateTime(2026, 10, 26),
      cerradoEn: DateTime(2026, 10, 26, 17),
      numeroVentas: 2,
      total: 34.0,
      productos: const [_cola],
    );
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    // Se ve lo guardado, no el calculo en vivo (que ademas trae el pan).
    expect(find.text('Día cerrado el 26/10/2026 17:00.'), findsOneWidget);
    expect(find.text('Vendidos (1)'), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('Pan dulce'), findsNothing);
    expect(find.text('Volver a cerrar'), findsNothing);
  });

  testWidgets('con ventas nuevas desde el cierre avisa y ofrece volver a '
      'cerrar', (tester) async {
    final servicio = _FakeCierreService(
      numeroVentas: 3,
      total: 40.0,
      productos: const [_cola, _pan],
      guardado: Cierre(
        id: 'c0',
        dia: DateTime(2026, 10, 26),
        cerradoEn: DateTime(2026, 10, 26, 17),
        numeroVentas: 2,
        total: 34.0,
        productos: const [_cola, _pan],
      ),
    );
    await _abrir(tester, servicio);
    await tester.pumpAndSettle();

    expect(
      find.text('Hay ventas nuevas desde el cierre de las 26/10/2026 17:00.'),
      findsOneWidget,
    );
    expect(find.text('Volver a cerrar'), findsOneWidget);
    expect(find.text('Q40.00'), findsOneWidget);
    expect(find.text('3 ventas'), findsOneWidget);

    await _cerrarYConfirmar(tester, 'Volver a cerrar');

    expect(servicio.cierres, 1);
    expect(servicio.guardado!.numeroVentas, 3);
    expect(find.textContaining('Hay ventas nuevas'), findsNothing);
    expect(find.text('Día cerrado el 26/10/2026 18:30.'), findsOneWidget);
    expect(find.text('Volver a cerrar'), findsNothing);
  });

  testWidgets('invalidar el provider vuelve a leer la base', (tester) async {
    final servicio = _FakeCierreService(
      numeroVentas: 1,
      total: 2.5,
      productos: const [_pan],
    );
    final container = await _abrir(tester, servicio);
    await tester.pumpAndSettle();
    expect(find.text('1 venta'), findsOneWidget);

    servicio
      ..numeroVentas = 2
      ..total = 5;
    container.invalidate(cierreHoyProvider);
    await tester.pumpAndSettle();

    expect(servicio.lecturas, 2);
    expect(find.text('2 ventas'), findsOneWidget);
    expect(find.text('Q5.00'), findsOneWidget);
  });
}
