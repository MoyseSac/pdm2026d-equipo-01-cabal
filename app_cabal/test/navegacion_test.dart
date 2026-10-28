import 'package:app_cabal/app.dart';
import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => [
    for (var i = 0; i < 40; i++)
      Producto(
        id: 'p$i',
        nombre: 'Producto ${i.toString().padLeft(2, '0')}',
        precio: 5,
      ),
  ];
}

class _FakeVentaService extends VentaService {
  @override
  Future<List<Venta>> obtenerVentas({
    DateTime? desde,
    DateTime? hastaExclusivo,
  }) async => [
    Venta(
      id: 'v1',
      fechaHora: DateTime(2026, 10, 15, 21, 5),
      detalles: const [
        DetalleVenta(
          producto: Producto(id: 'p1', nombre: 'Producto 01', precio: 5),
          cantidad: 1,
          precioAlMomento: 5,
        ),
      ],
    ),
  ];
}

Future<ProviderContainer> _abrirApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      productoServiceProvider.overrideWithValue(_FakeProductoService()),
      ventaServiceProvider.overrideWithValue(_FakeVentaService()),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CabalApp()),
  );

  await tester.tap(find.text('Ingresar (placeholder)'));
  await tester.pumpAndSettle();

  return container;
}

Finder _destino(String etiqueta) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(etiqueta),
);

void main() {
  testWidgets('cada botón de la barra cambia de pantalla', (tester) async {
    final container = await _abrirApp(tester);

    expect(find.widgetWithText(AppBar, 'Catálogo'), findsOneWidget);

    await tester.tap(_destino('Vender'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Registrar venta'), findsOneWidget);
    expect(container.read(tabProvider), Pestana.vender);

    await tester.tap(_destino('Ventas'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Ventas registradas'), findsOneWidget);

    await tester.tap(_destino('Cierre'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Cierre del día'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget);

    await tester.tap(_destino('Catálogo'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Catálogo'), findsOneWidget);
  });

  testWidgets('al volver a una pestaña conserva su scroll', (tester) async {
    await _abrirApp(tester);

    final grid = find.byType(GridView);

    await tester.drag(grid, const Offset(0, -600));
    await tester.pumpAndSettle();

    double offset() => tester
        .state<ScrollableState>(
          find.descendant(of: grid, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;

    final antes = offset();

    expect(antes, greaterThan(0));

    await tester.tap(_destino('Ventas'));
    await tester.pumpAndSettle();

    await tester.tap(_destino('Catálogo'));
    await tester.pumpAndSettle();

    expect(offset(), antes);
  });

  testWidgets('desde otra pantalla se navega cambiando el provider', (
    tester,
  ) async {
    final container = await _abrirApp(tester);

    // Tocar un producto del catálogo lleva a Vender.
    await tester.tap(find.text('Producto 00'));
    await tester.pumpAndSettle();

    expect(container.read(tabProvider), Pestana.vender);

    expect(find.widgetWithText(AppBar, 'Registrar venta'), findsOneWidget);

    // Cambiar el provider también cambia la pantalla.
    container.read(tabProvider.notifier).seleccionar(Pestana.ventas);

    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Ventas registradas'), findsOneWidget);
  });
}
