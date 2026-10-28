import 'package:app_cabal/app.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => const [
    Producto(id: 'p1', nombre: 'Leche', precio: 12.5),
    Producto(id: 'p2', nombre: 'Pan', precio: 2),
  ];
}

Future<ProviderContainer> _abrirApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      productoServiceProvider.overrideWithValue(_FakeProductoService()),
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

Finder _hoja() => find.byType(BottomSheet);

Finder _enHoja(Finder f) => find.descendant(of: _hoja(), matching: f);

void main() {
  testWidgets('tocar un producto abre la hoja y no cambia de pestaña', (
    tester,
  ) async {
    final container = await _abrirApp(tester);

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();

    expect(_hoja(), findsOneWidget);
    expect(container.read(tabProvider), Pestana.catalogo);
    expect(container.read(ventaProvider).detalles, isEmpty);
  });

  testWidgets('el − no baja de 1 y el botón muestra el subtotal', (
    tester,
  ) async {
    await _abrirApp(tester);

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();

    final quitar = find.byTooltip('Quitar una unidad');
    final botonQuitar = find.ancestor(
      of: quitar,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(botonQuitar).onPressed, isNull);

    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.pump();

    expect(_enHoja(find.text('3')), findsOneWidget);
    expect(find.text('Agregar a la venta · Q37.50'), findsOneWidget);

    await tester.tap(quitar);
    await tester.pump();

    expect(_enHoja(find.text('2')), findsOneWidget);
  });

  testWidgets('confirmar agrega la cantidad, muestra aviso y badge', (
    tester,
  ) async {
    final container = await _abrirApp(tester);

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.pump();
    await tester.tap(find.textContaining('Agregar a la venta'));
    await tester.pumpAndSettle();

    final detalles = container.read(ventaProvider).detalles;
    expect(detalles, hasLength(1));
    expect(detalles.single.producto.id, 'p1');
    expect(detalles.single.cantidad, 2);

    expect(_hoja(), findsNothing);
    expect(container.read(tabProvider), Pestana.catalogo);
    expect(find.text('2 × Leche agregado a la venta'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Badge),
      ),
      findsWidgets,
    );

    await tester.tap(find.text('Ver venta'));
    await tester.pumpAndSettle();

    expect(container.read(tabProvider), Pestana.vender);
  });

  testWidgets('cerrar la hoja sin confirmar no agrega nada', (tester) async {
    final container = await _abrirApp(tester);

    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(_hoja(), findsNothing);
    expect(container.read(ventaProvider).detalles, isEmpty);
  });

  testWidgets('si el producto ya está en la venta, la hoja lo indica y suma', (
    tester,
  ) async {
    final container = await _abrirApp(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Leche'));
      await tester.pumpAndSettle();

      if (i == 1) expect(find.text('Ya en la venta: 1'), findsOneWidget);

      await tester.tap(find.textContaining('Agregar a la venta'));
      await tester.pumpAndSettle();
    }

    expect(container.read(ventaProvider).detalles.single.cantidad, 2);
  });
}
