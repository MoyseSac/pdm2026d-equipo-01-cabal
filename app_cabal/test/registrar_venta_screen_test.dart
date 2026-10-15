import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/screens/registrar_venta_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/utils/moneda.dart';
import 'package:app_cabal/validators/cantidad_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  final List<Producto> items;
  _FakeProductoService(this.items);

  @override
  Future<List<Producto>> obtenerProductos() async => [...items];
}

Future<void> _abrir(WidgetTester tester, List<Producto> productos) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      productoServiceProvider
          .overrideWithValue(_FakeProductoService(productos)),
    ],
    child: const MaterialApp(home: RegistrarVentaScreen()),
  ));
  await tester.pumpAndSettle();
}

const _cola = Producto(id: '1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: '2', nombre: 'Pan dulce', precio: 2.5);
const _agua = Producto(id: '3', nombre: 'Agua pura', precio: 8);

Finder _enProductos(String texto) => find.descendant(
      of: find.byType(ListView).first,
      matching: find.text(texto),
    );

Finder _enVenta(String texto) => find.descendant(
      of: find.byType(ListView).last,
      matching: find.text(texto),
    );

Finder _confirmar() =>
    find.widgetWithText(ElevatedButton, 'Confirmar venta (placeholder)');

Finder _campoCantidad(int posicion) => find.byType(TextField).at(posicion);

String _cantidadEn(WidgetTester tester, int posicion) =>
    tester.widget<TextField>(_campoCantidad(posicion)).controller!.text;

bool _confirmarHabilitado(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_confirmar()).onPressed != null;

Finder _total(String texto) => find.descendant(
      of: find.byType(Padding),
      matching: find.text(texto),
    );

void main() {
  group('selección de productos', () {
    testWidgets('sin productos muestra mensaje para agregar al catálogo',
        (tester) async {
      await _abrir(tester, []);

      expect(find.text('No hay productos registrados'), findsOneWidget);
      expect(find.textContaining('Agrega productos al catálogo'),
          findsOneWidget);
      expect(find.text('Venta actual'), findsNothing);
    });

    testWidgets('muestra nombre y precio en quetzales de cada producto',
        (tester) async {
      await _abrir(tester, [_cola, _pan, _agua]);

      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Q10.50'), findsOneWidget);
      expect(find.text('Pan dulce'), findsOneWidget);
      expect(find.text('Q2.50'), findsOneWidget);
      expect(find.text('Agua pura'), findsOneWidget);
      expect(find.text('Q8.00'), findsOneWidget);
    });

    testWidgets('seleccionar varios productos los agrega a la venta actual',
        (tester) async {
      await _abrir(tester, [_cola, _pan, _agua]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Pan dulce'));
      await tester.pumpAndSettle();

      expect(_enVenta('Coca Cola'), findsOneWidget);
      expect(_enVenta('Pan dulce'), findsOneWidget);
      expect(_enVenta('Agua pura'), findsNothing);
    });

    testWidgets('volver a seleccionar un producto actualiza su cantidad',
        (tester) async {
      await _abrir(tester, [_cola, _pan]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Coca Cola'));
      await tester.pumpAndSettle();

      expect(_enVenta('Coca Cola'), findsOneWidget);
      expect(_cantidadEn(tester, 0), '3');
    });

    testWidgets('se puede eliminar un producto de la selección',
        (tester) async {
      await _abrir(tester, [_cola, _pan]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Pan dulce'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Eliminar de la venta').first);
      await tester.pumpAndSettle();

      expect(_enVenta('Pan dulce'), findsOneWidget);
      expect(find.byTooltip('Eliminar de la venta'), findsOneWidget);
    });
  });

  group('cantidades', () {
    testWidgets('los botones +/- ajustan la cantidad y no bajan de 1',
        (tester) async {
      await _abrir(tester, [_cola]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.pumpAndSettle();

      final menos =
          find.widgetWithIcon(IconButton, Icons.remove_circle_outline);
      expect(tester.widget<IconButton>(menos).onPressed, isNull);

      await tester.tap(find.byTooltip('Agregar una unidad'));
      await tester.pumpAndSettle();
      expect(_cantidadEn(tester, 0), '2');

      await tester.tap(menos);
      await tester.pumpAndSettle();
      expect(_cantidadEn(tester, 0), '1');
    });

    testWidgets('se puede escribir una cantidad válida', (tester) async {
      await _abrir(tester, [_cola]);
      await tester.tap(_enProductos('Coca Cola'));
      await tester.pumpAndSettle();

      await tester.enterText(_campoCantidad(0), '25');
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: Q262.50'), findsOneWidget);
      expect(_confirmarHabilitado(tester), isTrue);
    });

    for (final caso in {
      '0': CantidadValidator.mensajeNoPositiva,
      '-1': CantidadValidator.mensajeNoPositiva,
      '1.5': CantidadValidator.mensajeNoEntera,
      'abc': CantidadValidator.mensajeInvalida,
      '': CantidadValidator.mensajeInvalida,
    }.entries) {
      testWidgets('cantidad "${caso.key}" muestra error y bloquea confirmar',
          (tester) async {
        await _abrir(tester, [_cola]);
        await tester.tap(_enProductos('Coca Cola'));
        await tester.pumpAndSettle();

        await tester.enterText(_campoCantidad(0), caso.key);
        await tester.pumpAndSettle();

        expect(find.text(caso.value), findsOneWidget);
        expect(_confirmarHabilitado(tester), isFalse);

        // Al corregirla se vuelve a poder confirmar.
        await tester.enterText(_campoCantidad(0), '2');
        await tester.pumpAndSettle();
        expect(find.text(caso.value), findsNothing);
        expect(_confirmarHabilitado(tester), isTrue);
      });
    }

    testWidgets('una cantidad inválida en un producto bloquea toda la venta',
        (tester) async {
      await _abrir(tester, [_cola, _pan]);
      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Pan dulce'));
      await tester.pumpAndSettle();

      await tester.enterText(_campoCantidad(1), '0');
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isFalse);

      // Eliminar el producto inválido desbloquea la venta.
      await tester.tap(find.byTooltip('Eliminar de la venta').last);
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isTrue);
    });

    testWidgets('confirmar está deshabilitado mientras la venta está vacía',
        (tester) async {
      await _abrir(tester, [_cola]);

      expect(_confirmarHabilitado(tester), isFalse);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isTrue);

      await tester.tap(find.byTooltip('Eliminar de la venta'));
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isFalse);
    });
  });

  group('subtotales y total', () {
    testWidgets('venta vacía muestra total Q0.00', (tester) async {
      await _abrir(tester, [_cola]);

      expect(_total('Q0.00'), findsOneWidget);
    });

    testWidgets('calcula subtotales y total con varios productos',
        (tester) async {
      await _abrir(tester, [_cola, _pan, _agua]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.tap(_enProductos('Pan dulce'));
      await tester.pumpAndSettle();
      await tester.enterText(_campoCantidad(0), '2');
      await tester.enterText(_campoCantidad(1), '3');
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: Q21.00'), findsOneWidget);
      expect(find.text('Subtotal: Q7.50'), findsOneWidget);
      expect(_total('Q28.50'), findsOneWidget);
    });

    testWidgets('el total se actualiza al agregar, modificar y eliminar',
        (tester) async {
      await _abrir(tester, [_cola, _pan]);

      await tester.tap(_enProductos('Coca Cola'));
      await tester.pumpAndSettle();
      expect(_total('Q10.50'), findsWidgets);

      await tester.tap(_enProductos('Pan dulce'));
      await tester.pumpAndSettle();
      expect(_total('Q13.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Agregar una unidad').first);
      await tester.pumpAndSettle();
      expect(_total('Q23.50'), findsOneWidget);

      await tester.tap(find.byTooltip('Eliminar de la venta').first);
      await tester.pumpAndSettle();
      expect(_total('Q2.50'), findsWidgets);
    });

    testWidgets('el total no tiene errores de redondeo', (tester) async {
      const a = Producto(id: 'a', nombre: 'A', precio: 0.1);
      const b = Producto(id: 'b', nombre: 'B', precio: 0.2);
      const c = Producto(id: 'c', nombre: 'C', precio: 0.3);
      await _abrir(tester, [a, b, c]);

      await tester.tap(_enProductos('A'));
      await tester.tap(_enProductos('B'));
      await tester.tap(_enProductos('C'));
      await tester.pumpAndSettle();

      expect(_total('Q0.60'), findsOneWidget);
    });
  });

  group('cálculo monetario', () {
    DetalleVenta detalle(double precio, int cantidad) => DetalleVenta(
          producto: Producto(id: '$precio', nombre: 'P', precio: precio),
          cantidad: cantidad,
          precioAlMomento: precio,
        );

    test('subtotal = cantidad x precio, a dos decimales', () {
      expect(subtotalDe(detalle(10.5, 2)), 21.0);
      expect(subtotalDe(detalle(0.1, 3)), 0.3);
      expect(subtotalDe(detalle(19.99, 3)), 59.97);
      expect(subtotalDe(detalle(0.01, 1)), 0.01);
    });

    test('el total suma subtotales sin errores de representación', () {
      expect(totalDe([detalle(0.1, 1), detalle(0.2, 1)]), 0.3);
      expect(totalDe([detalle(10.5, 2), detalle(2.5, 3)]), 28.5);
      expect(totalDe([detalle(0.1, 1), detalle(0.2, 1), detalle(0.3, 1)]), 0.6);
      expect(totalDe(const []), 0);
    });

    test('formatearQuetzales usa Q y dos decimales', () {
      expect(formatearQuetzales(0), 'Q0.00');
      expect(formatearQuetzales(5), 'Q5.00');
      expect(formatearQuetzales(10.5), 'Q10.50');
      expect(formatearQuetzales(28.5), 'Q28.50');
      expect(formatearQuetzales(1234.567), 'Q1234.57');
    });

    test('CantidadValidator sigue las reglas de negocio', () {
      expect(CantidadValidator.validar('1'), isNull);
      expect(CantidadValidator.validar(' 25 '), isNull);
      expect(CantidadValidator.validar('0'),
          CantidadValidator.mensajeNoPositiva);
      expect(CantidadValidator.validar('-3'),
          CantidadValidator.mensajeNoPositiva);
      expect(CantidadValidator.validar('1.5'),
          CantidadValidator.mensajeNoEntera);
      expect(CantidadValidator.validar('2.0'),
          CantidadValidator.mensajeNoEntera);
      expect(CantidadValidator.validar('abc'),
          CantidadValidator.mensajeInvalida);
      expect(CantidadValidator.validar('NaN'),
          CantidadValidator.mensajeInvalida);
      expect(CantidadValidator.validar(''), CantidadValidator.mensajeInvalida);
      expect(CantidadValidator.validar(null),
          CantidadValidator.mensajeInvalida);
    });
  });
}
