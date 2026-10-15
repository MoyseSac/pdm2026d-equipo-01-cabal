import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/registrar_venta_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
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

void main() {
  testWidgets('sin productos muestra mensaje para agregar al catálogo',
      (tester) async {
    await _abrir(tester, []);

    expect(find.text('No hay productos registrados'), findsOneWidget);
    expect(find.textContaining('Agrega productos al catálogo'),
        findsOneWidget);
    expect(find.text('Venta actual'), findsNothing);
  });

  testWidgets('muestra nombre y precio de cada producto del catálogo',
      (tester) async {
    await _abrir(tester, [_cola, _pan, _agua]);

    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('\$10.50'), findsOneWidget);
    expect(find.text('Pan dulce'), findsOneWidget);
    expect(find.text('\$2.50'), findsOneWidget);
    expect(find.text('Agua pura'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
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
    expect(_enVenta('3'), findsOneWidget);
  });

  testWidgets('se puede eliminar un producto de la selección', (tester) async {
    await _abrir(tester, [_cola, _pan]);

    await tester.tap(_enProductos('Coca Cola'));
    await tester.tap(_enProductos('Pan dulce'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar de la venta').first);
    await tester.pumpAndSettle();

    expect(_enVenta('Pan dulce'), findsOneWidget);
    expect(find.byTooltip('Eliminar de la venta'), findsOneWidget);
  });

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
    expect(_enVenta('2'), findsOneWidget);

    await tester.tap(menos);
    await tester.pumpAndSettle();
    expect(_enVenta('1'), findsOneWidget);
  });

  testWidgets('confirmar está deshabilitado mientras la venta está vacía',
      (tester) async {
    await _abrir(tester, [_cola]);

    final boton = find.widgetWithText(
        ElevatedButton, 'Confirmar venta (placeholder)');
    expect(tester.widget<ElevatedButton>(boton).onPressed, isNull);

    await tester.tap(_enProductos('Coca Cola'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(boton).onPressed, isNotNull);
  });
}
