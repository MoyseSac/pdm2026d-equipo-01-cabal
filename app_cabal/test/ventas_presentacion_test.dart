import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/providers/ventas_filtro_provider.dart';
import 'package:app_cabal/screens/ventas_registradas_screen.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:app_cabal/widgets/resumen_ventas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const producto = Producto(
  id: 'p',
  nombre: 'Chorizo criollo artesanal de presentación familiar',
  precio: 99,
  icono: 'embutidos',
);
final datos = [
  Venta(
    id: 'hoy',
    fechaHora: DateTime(2026, 11, 12, 14),
    detalles: const [
      DetalleVenta(producto: producto, cantidad: 3, precioAlMomento: 12.5),
    ],
  ),
  Venta(
    id: 'ayer',
    fechaHora: DateTime(2026, 11, 11, 9),
    detalles: const [
      DetalleVenta(producto: producto, cantidad: 2, precioAlMomento: 10),
    ],
  ),
];

class _Ventas extends VentaService {
  @override
  Future<List<Venta>> obtenerVentas({
    DateTime? desde,
    DateTime? hastaExclusivo,
  }) async => datos
      .where(
        (v) =>
            (desde == null || !v.fechaHora.isBefore(desde)) &&
            (hastaExclusivo == null || v.fechaHora.isBefore(hastaExclusivo)),
      )
      .toList();
}

Future<void> abrir(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double escala = 1,
  bool reducir = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reducir);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ventaServiceProvider.overrideWithValue(_Ventas()),
        fechaActualVentasProvider.overrideWithValue(
          () => DateTime(2026, 11, 12),
        ),
      ],
      child: MaterialApp(
        theme: temaCabal,
        home: const VentasRegistradasScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el importe transiciona y termina en el valor exacto', (
    tester,
  ) async {
    Widget resumen(double total) => MaterialApp(
      theme: temaCabal,
      home: Scaffold(body: ResumenVentas(total: total, ventas: 2, unidades: 5)),
    );
    await tester.pumpWidget(resumen(100));
    expect(find.text('Q0.00'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Q100.00'), findsNothing);
    expect(find.text('Q0.00'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Q100.00'), findsOneWidget);
    await tester.pumpWidget(resumen(250));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Q250.00'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Q250.00'), findsOneWidget);
  });

  testWidgets('con movimiento reducido muestra el importe final de inmediato', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: temaCabal,
        home: const Scaffold(
          body: ResumenVentas(total: 57.5, ventas: 2, unidades: 5),
        ),
      ),
    );
    expect(find.text('Q57.50'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets(
    'el resumen cambia con el período y suma unidades y precios históricos',
    (tester) async {
      await abrir(tester);
      expect(find.text('Q57.50'), findsOneWidget);
      expect(find.text('2 ventas'), findsOneWidget);
      expect(find.text('5 unidades'), findsOneWidget);
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('1 venta'), findsOneWidget);
      expect(find.text('3 unidades'), findsOneWidget);
      expect(find.text('Q57.50'), findsNothing);
      expect(find.text('Q37.50'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(320, 568), const Size(667, 375)]) {
    testWidgets(
      'historial y comprobante accesibles con texto grande en $size sin movimiento',
      (tester) async {
        await abrir(tester, size: size, escala: 2, reducir: true);
        expect(find.text('Q57.50'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.scrollUntilVisible(
          find.text('12/11/2026 14:00'),
          180,
          scrollable: find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('12/11/2026 14:00'));
        await tester.pumpAndSettle();
        expect(find.text('Detalle de venta'), findsOneWidget);
        await tester.ensureVisible(find.text('Total'));
        await tester.pumpAndSettle();
        expect(find.text('Q37.50'), findsNWidgets(2));
        expect(find.text('3 × Q12.50'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  }
}
