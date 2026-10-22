import 'package:app_cabal/app.dart';
import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:app_cabal/utils/fecha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);

class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => [_cola, _pan];
}

class _FakeVentaService extends VentaService {
  final List<Venta> lista;
  bool fallar;
  int lecturas = 0;

  _FakeVentaService(this.lista, {this.fallar = false});

  @override
  Future<List<Venta>> obtenerVentas() async {
    lecturas++;
    if (fallar) throw Exception('fallo simulado');
    return lista;
  }
}

final _reciente = Venta(
  id: 'v2',
  fechaHora: DateTime(2026, 10, 15, 21, 5),
  detalles: [
    const DetalleVenta(producto: _cola, cantidad: 2, precioAlMomento: 10.5),
    const DetalleVenta(producto: _pan, cantidad: 3, precioAlMomento: 2.5),
  ],
);

final _antigua = Venta(
  id: 'v1',
  fechaHora: DateTime(2026, 10, 14, 9, 30),
  detalles: [
    const DetalleVenta(producto: _pan, cantidad: 1, precioAlMomento: 2.0),
  ],
);

Future<void> _abrirVentas(
  WidgetTester tester,
  _FakeVentaService servicio,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productoServiceProvider.overrideWithValue(_FakeProductoService()),
        ventaServiceProvider.overrideWithValue(servicio),
      ],
      child: const CabalApp(),
    ),
  );
  await tester.tap(find.text('Ingresar (placeholder)'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Ventas'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('formatearFechaHora usa dd/mm/aaaa hh:mm', () {
    expect(
      formatearFechaHora(DateTime(2026, 10, 15, 21, 5)),
      '15/10/2026 21:05',
    );
    expect(formatearFechaHora(DateTime(2026, 1, 2, 3, 4)), '02/01/2026 03:04');
  });

  testWidgets('sin ventas muestra el estado vacío', (tester) async {
    await _abrirVentas(tester, _FakeVentaService([]));

    expect(find.widgetWithText(AppBar, 'Ventas registradas'), findsOneWidget);
    expect(find.text('Aún no hay ventas registradas'), findsOneWidget);
    expect(
      find.text('Las ventas que registres aparecerán aquí.'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('el estado vacío ofrece registrar una venta', (tester) async {
    await _abrirVentas(tester, _FakeVentaService([]));

    await tester.tap(find.text('Registrar venta'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Registrar venta'), findsOneWidget);
    expect(find.text('Aún no hay ventas registradas'), findsNothing);
  });

  testWidgets('lista las ventas con fecha, cantidad de productos y total', (
    tester,
  ) async {
    await _abrirVentas(tester, _FakeVentaService([_reciente, _antigua]));

    expect(find.text('15/10/2026 21:05'), findsOneWidget);
    expect(find.text('2 productos'), findsOneWidget);
    expect(find.text('Q28.50'), findsOneWidget);

    expect(find.text('14/10/2026 09:30'), findsOneWidget);
    expect(find.text('1 producto'), findsOneWidget);
    expect(find.text('Q2.00'), findsOneWidget);
  });

  testWidgets(
    'se muestran en el orden en que llegan, la más reciente primero',
    (tester) async {
      await _abrirVentas(tester, _FakeVentaService([_reciente, _antigua]));

      final arriba = tester.getTopLeft(find.text('15/10/2026 21:05')).dy;
      final abajo = tester.getTopLeft(find.text('14/10/2026 09:30')).dy;
      expect(arriba, lessThan(abajo));
    },
  );

  testWidgets('tocar una venta muestra su detalle', (tester) async {
    await _abrirVentas(tester, _FakeVentaService([_reciente, _antigua]));

    await tester.tap(find.text('15/10/2026 21:05'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Detalle de venta'), findsOneWidget);
    expect(find.text('15/10/2026 21:05'), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('2 × Q10.50'), findsOneWidget);
    expect(find.text('Q21.00'), findsOneWidget);
    expect(find.text('Pan dulce'), findsOneWidget);
    expect(find.text('3 × Q2.50'), findsOneWidget);
    expect(find.text('Q7.50'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Q28.50'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay ventas registradas'), findsNothing);
    expect(find.text('14/10/2026 09:30'), findsOneWidget);
  });

  testWidgets('el detalle muestra el precio al momento de la venta', (
    tester,
  ) async {
    await _abrirVentas(tester, _FakeVentaService([_antigua]));

    await tester.tap(find.text('14/10/2026 09:30'));
    await tester.pumpAndSettle();

    // El catálogo actual tiene el pan a Q2.50, la venta lo guardó a Q2.00.
    expect(find.text('1 × Q2.00'), findsOneWidget);
    expect(find.text('1 × Q2.50'), findsNothing);
  });

  testWidgets('si falla la lectura informa y permite reintentar', (
    tester,
  ) async {
    final servicio = _FakeVentaService([_reciente], fallar: true);
    await _abrirVentas(tester, servicio);

    expect(find.text('No se pudieron cargar las ventas.'), findsOneWidget);

    servicio.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('15/10/2026 21:05'), findsOneWidget);
    expect(servicio.lecturas, 3);
  });

  testWidgets('al volver a la pestaña Ventas se leen de nuevo las ventas', (
    tester,
  ) async {
    final servicio = _FakeVentaService([_antigua]);
    await _abrirVentas(tester, servicio);
    expect(servicio.lecturas, 2);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Catálogo'),
      ),
    );
    await tester.pumpAndSettle();
    servicio.lista.insert(0, _reciente);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ventas'),
      ),
    );
    await tester.pumpAndSettle();

    expect(servicio.lecturas, 3);
    expect(find.text('15/10/2026 21:05'), findsOneWidget);
  });
}
