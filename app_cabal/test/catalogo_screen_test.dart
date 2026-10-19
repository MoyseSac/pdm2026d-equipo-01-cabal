import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => const [
    Producto(id: '1', nombre: 'Coca Cola', precio: 10.5),
    Producto(id: '2', nombre: 'Pan dulce', precio: 2),
    Producto(id: '3', nombre: 'Chicle', precio: 0.1),
  ];
}

void main() {
  testWidgets('el catálogo muestra los precios en quetzales', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productoServiceProvider.overrideWithValue(_FakeProductoService()),
        ],
        child: const MaterialApp(home: CatalogoScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Q10.50'), findsOneWidget);
    expect(find.text('Q2.00'), findsOneWidget);
    expect(find.text('Q0.10'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
  });
}
