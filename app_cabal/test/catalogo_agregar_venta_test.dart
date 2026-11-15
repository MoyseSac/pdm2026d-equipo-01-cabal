import 'package:app_cabal/app.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  _FakeProductoService({this.productos});

  final List<Producto>? productos;

  @override
  Future<List<Producto>> obtenerProductos() async =>
      productos ??
      const [
        Producto(id: 'p1', nombre: 'Leche', precio: 12.5),
        Producto(id: 'p2', nombre: 'Pan', precio: 2),
      ];
}

Future<ProviderContainer> _abrirApp(
  WidgetTester tester, {
  List<Producto>? productos,
  Size size = const Size(400, 800),
  double escalaTexto = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = ProviderContainer(
    overrides: [
      productoServiceProvider.overrideWithValue(
        _FakeProductoService(productos: productos),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CabalApp()),
  );
  await tester.pumpAndSettle();

  return container;
}

Finder _hoja() => find.byType(BottomSheet);

Finder _enHoja(Finder f) => find.descendant(of: _hoja(), matching: f);

void main() {
  const nombreLargo =
      'Chocolate artesanal con almendras y leche en presentacion familiar';
  final productosLargos = [
    for (var i = 0; i < 20; i++)
      Producto(id: 'l$i', nombre: '$nombreLargo $i', precio: 15),
  ];

  Finder listaCatalogo() => find.descendant(
    of: find.byType(CatalogoScreen),
    matching: find.byType(ListView),
  );

  Future<void> irAlFinal(WidgetTester tester) async {
    final lista = listaCatalogo();
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: lista, matching: find.byType(Scrollable)),
    );
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    // Las filas de dos lineas pueden corregir la extension estimada.
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(320, 568), const Size(360, 640)]) {
    for (final escala in [1.0, 1.3]) {
      testWidgets('ultimo producto accesible en $size con texto $escala', (
        tester,
      ) async {
        await _abrirApp(
          tester,
          productos: productosLargos,
          size: size,
          escalaTexto: escala,
        );
        await irAlFinal(tester);

        final ultimaFila = find.byKey(const ValueKey('l19'));
        final fab = find.byType(FloatingActionButton);
        expect(
          tester.getBottomRight(ultimaFila).dy,
          lessThanOrEqualTo(tester.getTopLeft(fab).dy - 12),
        );
        final menu = find.descendant(
          of: ultimaFila,
          matching: find.byTooltip('Opciones de producto'),
        );
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.text('Editar producto'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ultimo producto accesible con teclado y despues de cerrarlo', (
    tester,
  ) async {
    await _abrirApp(tester, productos: productosLargos);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();
    await irAlFinal(tester);

    void comprobarUltimo() {
      expect(
        tester.getBottomRight(find.byKey(const ValueKey('l19'))).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byType(FloatingActionButton)).dy - 12,
        ),
      );
      expect(tester.takeException(), isNull);
    }

    comprobarUltimo();
    await tester.drag(find.byKey(const ValueKey('l19')), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await irAlFinal(tester);
    comprobarUltimo();
  });

  testWidgets(
    'agregar un nombre largo no muestra avisos ni tapa la navegación',
    (tester) async {
      final container = await _abrirApp(
        tester,
        productos: productosLargos,
        size: const Size(320, 568),
      );
      await irAlFinal(tester);
      final ultimaFila = find.byKey(const ValueKey('l19'));
      await tester.tap(
        find.descendant(
          of: ultimaFila,
          matching: find.byTooltip('Agregar a la venta'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Agregar a la venta ·'));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(find.byType(SnackBar), findsNothing);
      expect(container.read(ventaProvider).detalles.single.producto.id, 'l19');
      expect(
        tester.getBottomRight(fab).dy,
        lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );
      expect(tester.takeException(), isNull);
      // La venta sigue disponible desde la navegación principal.
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Vender'),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(tabProvider), Pestana.vender);
    },
  );

  testWidgets('el botón + abre la hoja y no cambia de pestaña', (tester) async {
    final container = await _abrirApp(tester);

    await tester.tap(find.byTooltip('Agregar a la venta').first);
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

  testWidgets('confirmar agrega la cantidad y actualiza el badge sin aviso', (
    tester,
  ) async {
    final container = await _abrirApp(tester);
    await tester.enterText(find.byType(TextField), 'lech');
    await tester.pumpAndSettle();
    expect(find.text('Pan'), findsNothing);

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
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Badge),
      ),
      findsWidgets,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Vender'),
      ),
    );
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
