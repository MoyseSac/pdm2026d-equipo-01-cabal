import 'dart:async';

import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _productos = <Producto>[
  Producto(id: '1', nombre: 'Coca Cola', precio: 10.5),
  Producto(id: '2', nombre: 'Pan dulce', precio: 2),
  Producto(id: '3', nombre: 'Chicle', precio: 0.1),
];

// Servicio falso: permite simular datos, errores y cargas lentas.
class _FakeProductoService extends ProductoService {
  _FakeProductoService({
    this.productos = _productos,
    this.fallar = false,
    this.respuestaPendiente,
  });

  final List<Producto> productos;
  bool fallar;
  final Completer<List<Producto>>? respuestaPendiente;
  int lecturas = 0;

  @override
  Future<List<Producto>> obtenerProductos() async {
    lecturas++;

    if (respuestaPendiente != null) {
      return respuestaPendiente!.future;
    }

    if (fallar) {
      throw Exception('Error simulado de lectura');
    }

    return productos;
  }
}

// Monta la pantalla con el servicio falso mediante override.
Future<void> _montarCatalogo(
  WidgetTester tester,
  _FakeProductoService servicio,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [productoServiceProvider.overrideWithValue(servicio)],
      child: MaterialApp(
        home: const CatalogoScreen(),
        routes: {
          AppRoutes.agregarProducto: (_) =>
              const Scaffold(body: Center(child: Text('Formulario de prueba'))),
        },
      ),
    ),
  );
}

void main() {
  // PRUEBA 1: ESTADO CARGANDO
  testWidgets('muestra cargando mientras espera productos', (tester) async {
    final pendiente = Completer<List<Producto>>();

    await _montarCatalogo(
      tester,
      _FakeProductoService(respuestaPendiente: pendiente),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando productos...'), findsOneWidget);

    pendiente.complete(_productos);
    await tester.pumpAndSettle();

    expect(find.text('Coca Cola'), findsOneWidget);
  });

  // PRUEBA 2: ESTADO ERROR Y REINTENTAR
  testWidgets('muestra error y permite reintentar la carga', (tester) async {
    final servicio = _FakeProductoService(fallar: true);

    await _montarCatalogo(tester, servicio);
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar los productos.'), findsOneWidget);

    expect(find.text('Reintentar'), findsOneWidget);

    // Simulamos que el problema se corrigió.
    servicio.fallar = false;

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    // Después de reintentar aparecen los productos.
    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('Pan dulce'), findsOneWidget);

    // Verifica que realmente consultó dos veces.
    expect(servicio.lecturas, 2);
  });

  // PRUEBA 3: ESTADO VACÍO
  testWidgets('muestra estado vacío y permite agregar producto', (
    tester,
  ) async {
    await _montarCatalogo(tester, _FakeProductoService(productos: const []));
    await tester.pumpAndSettle();

    expect(find.text('Catálogo vacío'), findsOneWidget);
    expect(find.text('Agregar primer producto'), findsOneWidget);

    await tester.tap(find.text('Agregar primer producto'));
    await tester.pumpAndSettle();

    expect(find.text('Formulario de prueba'), findsOneWidget);
  });

  // PRUEBA 4: ESTADO CON DATOS
  testWidgets('el catálogo muestra los precios en quetzales', (tester) async {
    await _montarCatalogo(tester, _FakeProductoService());
    await tester.pumpAndSettle();

    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('Pan dulce'), findsOneWidget);
    expect(find.text('Chicle'), findsOneWidget);

    expect(find.text('Q10.50'), findsOneWidget);
    expect(find.text('Q2.00'), findsOneWidget);
    expect(find.text('Q0.10'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
  });
}
