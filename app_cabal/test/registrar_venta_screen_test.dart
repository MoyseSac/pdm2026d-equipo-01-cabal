import 'dart:async';

import 'package:app_cabal/providers/catalogo_provider.dart';
import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/tab_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/screens/registrar_venta_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/utils/moneda.dart';
import 'package:app_cabal/validators/cantidad_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catalogo con tres productos; la pantalla de venta no debe listarlos.
class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => const [_cola, _pan, _agua];
}

Future<void> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productoServiceProvider.overrideWithValue(_FakeProductoService()),
      ],
      child: const MaterialApp(home: RegistrarVentaScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Agrega un producto a la venta como lo hace el catalogo: por el provider.
Future<void> _agregar(
  WidgetTester tester,
  Producto producto, [
  int cantidad = 1,
]) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RegistrarVentaScreen)),
  );
  container.read(ventaProvider.notifier).agregarProducto(producto, cantidad);
  await tester.pumpAndSettle();
}

const _cola = Producto(id: '1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: '2', nombre: 'Pan dulce', precio: 2.5);
const _agua = Producto(id: '3', nombre: 'Agua pura', precio: 8);

Finder _enVenta(String texto) =>
    find.descendant(of: find.byType(ListView), matching: find.text(texto));

Finder _confirmar() => find.widgetWithText(ElevatedButton, 'Confirmar venta');

Finder _campoCantidad(int posicion) => find.byType(TextField).at(posicion);

String _cantidadEn(WidgetTester tester, int posicion) =>
    tester.widget<TextField>(_campoCantidad(posicion)).controller!.text;

bool _confirmarHabilitado(WidgetTester tester) =>
    _confirmar().evaluate().isNotEmpty &&
    tester.widget<ElevatedButton>(_confirmar()).onPressed != null;

Finder _total(String texto) =>
    find.descendant(of: find.byType(Padding), matching: find.text(texto));

void main() {
  group('estados iniciales', () {
    testWidgets('catálogo cargando no se confunde con vacío', (tester) async {
      final carga = Completer<List<Producto>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogoProductosProvider.overrideWith((ref) => carga.future),
          ],
          child: const MaterialApp(home: RegistrarVentaScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Consultando productos…'), findsOneWidget);
      expect(find.text('Agregar primer producto'), findsNothing);
      expect(_confirmar(), findsNothing);
      carga.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Primero agrega un producto'), findsOneWidget);
    });

    testWidgets('error de catálogo permite reintentar sin mostrar vacío', (
      tester,
    ) async {
      var intentos = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogoProductosProvider.overrideWith((ref) async {
              if (++intentos == 1) throw Exception('consulta fallida');
              return [_cola];
            }),
          ],
          child: const MaterialApp(home: RegistrarVentaScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se pudo consultar el catálogo'), findsOneWidget);
      expect(find.text('Agregar primer producto'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir productos'), findsOneWidget);
      expect(intentos, 2);
    });

    testWidgets('crear primer producto refresca el estado al regresar', (
      tester,
    ) async {
      var creado = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogoProductosProvider.overrideWith(
              (ref) async => creado ? [_cola] : [],
            ),
          ],
          child: MaterialApp(
            home: const RegistrarVentaScreen(),
            routes: {
              AppRoutes.agregarProducto: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    creado = true;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Guardar producto de prueba'),
                ),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar primer producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar producto de prueba'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir productos'), findsOneWidget);
    });

    testWidgets(
      'Agregar más conserva selección y contador distingue unidades',
      (tester) async {
        await _abrir(tester);
        await _agregar(tester, _cola, 2);
        await _agregar(tester, _pan);
        expect(find.text('2 productos · 3 unidades'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(RegistrarVentaScreen)),
        );
        container.read(tabProvider.notifier).seleccionar(Pestana.vender);
        await tester.tap(find.text('Agregar más'));
        await tester.pump();
        expect(container.read(tabProvider), Pestana.catalogo);
        expect(container.read(ventaProvider).detalles.length, 2);
        expect(container.read(ventaProvider).total, 23.5);
      },
    );
  });

  group('selección de productos', () {
    testWidgets('venta vacía muestra mensaje para agregar desde el catálogo', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.text('Empieza una nueva venta'), findsOneWidget);
      expect(
        find.textContaining('Selecciona productos del catálogo'),
        findsOneWidget,
      );
      expect(find.text('Elegir productos'), findsOneWidget);
      expect(find.text('Venta actual'), findsNothing);
    });

    testWidgets('Elegir productos cambia a la pestaña del catálogo', (
      tester,
    ) async {
      await _abrir(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RegistrarVentaScreen)),
      );
      container.read(tabProvider.notifier).seleccionar(Pestana.vender);

      await tester.tap(find.text('Elegir productos'));
      await tester.pump();

      expect(container.read(tabProvider), Pestana.catalogo);
    });

    testWidgets('solo muestra los productos agregados, no todo el catálogo', (
      tester,
    ) async {
      await _abrir(tester);
      await _agregar(tester, _cola);

      expect(find.text('Venta actual'), findsOneWidget);
      expect(find.text('Productos'), findsNothing);
      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Pan dulce'), findsNothing);
      expect(find.text('Agua pura'), findsNothing);
      expect(find.text('Empieza una nueva venta'), findsNothing);
    });

    testWidgets('seleccionar varios productos los agrega a la venta actual', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await _agregar(tester, _pan);
      await tester.pumpAndSettle();

      expect(_enVenta('Coca Cola'), findsOneWidget);
      expect(_enVenta('Pan dulce'), findsOneWidget);
      expect(_enVenta('Agua pura'), findsNothing);
    });

    testWidgets('volver a seleccionar un producto actualiza su cantidad', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await _agregar(tester, _cola);
      await _agregar(tester, _cola);
      await tester.pumpAndSettle();

      expect(_enVenta('Coca Cola'), findsOneWidget);
      expect(_cantidadEn(tester, 0), '3');
    });

    testWidgets('se puede eliminar un producto de la selección', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await _agregar(tester, _pan);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Quitar').first);
      await tester.pumpAndSettle();

      expect(_enVenta('Pan dulce'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Quitar'), findsOneWidget);
    });
  });

  testWidgets(
    'tarjeta separa información y controles y conserva áreas táctiles',
    (tester) async {
      await _abrir(tester);
      await _agregar(
        tester,
        const Producto(
          id: 'largo',
          nombre:
              'Chocolate artesanal con almendras y leche en presentación familiar',
          precio: 1234.5,
        ),
      );
      final tarjeta = find.byType(Card);
      expect(tarjeta, findsOneWidget);
      expect(find.text('Q1,234.50 por unidad'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(48),
      );
      for (final boton in find.byType(IconButton).evaluate()) {
        final size = tester.getSize(find.byWidget(boton.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester.getTopLeft(find.byType(TextField)).dy,
        greaterThan(tester.getBottomLeft(find.text('Q1,234.50 por unidad')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('recuperación de la edición', () {
    testWidgets('Deshacer recupera posición, cantidad y precio de la fila', (
      tester,
    ) async {
      await _abrir(tester);
      await _agregar(tester, _cola, 3);
      await _agregar(tester, _pan);
      await tester.tap(find.widgetWithText(TextButton, 'Quitar').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('quitado de la venta'), findsOneWidget);
      expect(_enVenta('Coca Cola'), findsNothing);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RegistrarVentaScreen)),
      );
      final detalles = container.read(ventaProvider).detalles;
      expect(detalles.map((d) => d.producto.id), ['1', '2']);
      expect(detalles.first.cantidad, 3);
      expect(detalles.first.precioAlMomento, 10.5);
      expect(find.text('Q34.00'), findsOneWidget);
    });

    testWidgets('Deshacer del último producto recupera una venta editable', (
      tester,
    ) async {
      await _abrir(tester);
      await _agregar(tester, _cola, 2);
      await tester.enterText(_campoCantidad(0), '0');
      await tester.pumpAndSettle();
      expect(find.textContaining('El total conserva'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
      await tester.pumpAndSettle();
      expect(find.text('Empieza una nueva venta'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(_cantidadEn(tester, 0), '2');
      expect(_confirmarHabilitado(tester), isTrue);
      expect(find.textContaining('El total conserva'), findsNothing);
    });

    testWidgets(
      'agregar desde catálogo corrige una cantidad inválida anterior',
      (tester) async {
        await _abrir(tester);
        await _agregar(tester, _cola);
        await tester.enterText(_campoCantidad(0), 'abc');
        await tester.pumpAndSettle();
        expect(_confirmarHabilitado(tester), isFalse);
        await _agregar(tester, _cola);
        expect(_cantidadEn(tester, 0), '2');
        expect(_confirmarHabilitado(tester), isTrue);
        expect(find.textContaining('El total conserva'), findsNothing);
      },
    );

    testWidgets(
      'Deshacer no duplica un producto agregado otra vez desde catálogo',
      (tester) async {
        await _abrir(tester);
        await _agregar(tester, _cola, 2);
        await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
        await tester.pumpAndSettle();
        await _agregar(
          tester,
          const Producto(id: '1', nombre: 'Cola actualizada', precio: 12),
          4,
        );
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();
        expect(_cantidadEn(tester, 0), '4');
        expect(find.text('Q48.00'), findsOneWidget);
      },
    );
  });

  group('cantidades', () {
    testWidgets('los botones +/- ajustan la cantidad y no bajan de 1', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await tester.pumpAndSettle();

      final menos = find.widgetWithIcon(
        IconButton,
        Icons.remove_circle_outline,
      );
      expect(tester.widget<IconButton>(menos).onPressed, isNull);

      await tester.tap(find.byTooltip('Aumentar cantidad de Coca Cola'));
      await tester.pumpAndSettle();
      expect(_cantidadEn(tester, 0), '2');

      await tester.tap(menos);
      await tester.pumpAndSettle();
      expect(_cantidadEn(tester, 0), '1');
    });

    testWidgets('se puede escribir una cantidad válida', (tester) async {
      await _abrir(tester);
      await _agregar(tester, _cola);
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
      testWidgets('cantidad "${caso.key}" muestra error y bloquea confirmar', (
        tester,
      ) async {
        await _abrir(tester);
        await _agregar(tester, _cola);
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

    testWidgets('una cantidad inválida en un producto bloquea toda la venta', (
      tester,
    ) async {
      await _abrir(tester);
      await _agregar(tester, _cola);
      await _agregar(tester, _pan);
      await tester.pumpAndSettle();

      await tester.enterText(_campoCantidad(1), '0');
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isFalse);

      // Eliminar el producto inválido desbloquea la venta.
      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Quitar').last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Quitar').last);
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isTrue);
    });

    testWidgets('confirmar está deshabilitado mientras la venta está vacía', (
      tester,
    ) async {
      await _abrir(tester);

      expect(_confirmarHabilitado(tester), isFalse);

      await _agregar(tester, _cola);
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isTrue);

      await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
      await tester.pumpAndSettle();
      expect(_confirmarHabilitado(tester), isFalse);
    });
  });

  group('subtotales y total', () {
    testWidgets('venta vacía oculta total y confirmación', (tester) async {
      await _abrir(tester);

      expect(_total('Q0.00'), findsNothing);
      expect(_confirmar(), findsNothing);
    });

    testWidgets('calcula subtotales y total con varios productos', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await _agregar(tester, _pan);
      await tester.pumpAndSettle();
      await tester.enterText(_campoCantidad(0), '2');
      await tester.enterText(_campoCantidad(1), '3');
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: Q21.00'), findsOneWidget);
      expect(find.text('Subtotal: Q7.50'), findsOneWidget);
      expect(_total('Q28.50'), findsOneWidget);
    });

    testWidgets('el total se actualiza al agregar, modificar y eliminar', (
      tester,
    ) async {
      await _abrir(tester);

      await _agregar(tester, _cola);
      await tester.pumpAndSettle();
      expect(_total('Q10.50'), findsWidgets);

      await _agregar(tester, _pan);
      await tester.pumpAndSettle();
      expect(_total('Q13.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Aumentar cantidad de Coca Cola').first);
      await tester.pumpAndSettle();
      expect(_total('Q23.50'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Quitar').first);
      await tester.pumpAndSettle();
      expect(_total('Q2.50'), findsWidgets);
    });

    testWidgets('el total no tiene errores de redondeo', (tester) async {
      const a = Producto(id: 'a', nombre: 'A', precio: 0.1);
      const b = Producto(id: 'b', nombre: 'B', precio: 0.2);
      const c = Producto(id: 'c', nombre: 'C', precio: 0.3);
      await _abrir(tester);

      await _agregar(tester, a);
      await _agregar(tester, b);
      await _agregar(tester, c);
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
      expect(formatearQuetzales(1234.567), 'Q1,234.57');
      expect(formatearQuetzales(999.99), 'Q999.99');
      expect(formatearQuetzales(1000), 'Q1,000.00');
      expect(formatearQuetzales(1234567.5), 'Q1,234,567.50');
    });

    test('CantidadValidator sigue las reglas de negocio', () {
      expect(CantidadValidator.validar('1'), isNull);
      expect(CantidadValidator.validar(' 25 '), isNull);
      expect(
        CantidadValidator.validar('0'),
        CantidadValidator.mensajeNoPositiva,
      );
      expect(
        CantidadValidator.validar('-3'),
        CantidadValidator.mensajeNoPositiva,
      );
      expect(
        CantidadValidator.validar('1.5'),
        CantidadValidator.mensajeNoEntera,
      );
      expect(
        CantidadValidator.validar('2.0'),
        CantidadValidator.mensajeNoEntera,
      );
      expect(
        CantidadValidator.validar('abc'),
        CantidadValidator.mensajeInvalida,
      );
      expect(
        CantidadValidator.validar('NaN'),
        CantidadValidator.mensajeInvalida,
      );
      expect(CantidadValidator.validar(''), CantidadValidator.mensajeInvalida);
      expect(
        CantidadValidator.validar(null),
        CantidadValidator.mensajeInvalida,
      );
    });
  });
}
