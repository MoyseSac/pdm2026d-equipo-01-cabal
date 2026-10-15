import 'dart:async';
import 'dart:io';

import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/screens/confirmacion_venta_screen.dart';
import 'package:app_cabal/screens/registrar_venta_screen.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);

class _FakeProductoService extends ProductoService {
  @override
  Future<List<Producto>> obtenerProductos() async => [_cola, _pan];
}

/// Servicio de ventas controlable: cuenta llamadas y deja decidir cuando
/// termina o si falla.
class _VentaServiceControlable extends VentaService {
  int llamadas = 0;
  bool fallar = false;
  Completer<void>? espera;

  @override
  Future<void> registrarVenta(Venta venta) async {
    llamadas++;
    if (espera != null) await espera!.future;
    if (fallar) throw Exception('fallo simulado');
  }
}

Widget _app(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: const RegistrarVentaScreen(),
      routes: {
        AppRoutes.confirmacionVenta: (_) => const ConfirmacionVentaScreen(),
        AppRoutes.catalogo: (_) => const Scaffold(body: Text('CATALOGO')),
      },
    ),
  );
}

void _pantalla(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Finder _confirmar() => find.widgetWithText(ElevatedButton, 'Confirmar venta');

Finder _producto(String nombre) => find.descendant(
      of: find.byType(ListView).first,
      matching: find.text(nombre),
    );

void main() {
  group('con servicio simulado', () {
    late _VentaServiceControlable servicio;
    late List<Override> overrides;

    setUp(() {
      servicio = _VentaServiceControlable();
      overrides = [
        productoServiceProvider.overrideWithValue(_FakeProductoService()),
        ventaServiceProvider.overrideWithValue(servicio),
      ];
    });

    testWidgets('al guardar muestra confirmación y limpia la selección',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(overrides));
      await tester.pumpAndSettle();

      await tester.tap(_producto('Coca Cola'));
      await tester.tap(_producto('Pan dulce'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmar());
      await tester.pumpAndSettle();

      expect(servicio.llamadas, 1);
      expect(find.text('Venta registrada'), findsOneWidget);
      expect(find.text('Total: Q13.00'), findsOneWidget);

      // Al volver a la pantalla de venta la selección está limpia.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Toca un producto para agregarlo a la venta'),
          findsOneWidget);
      expect(tester.widget<ElevatedButton>(_confirmar()).onPressed, isNull);
    });

    testWidgets('muestra carga y evita registros duplicados al pulsar varias '
        'veces', (tester) async {
      _pantalla(tester);
      servicio.espera = Completer<void>();
      await tester.pumpWidget(_app(overrides));
      await tester.pumpAndSettle();

      await tester.tap(_producto('Coca Cola'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmar());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(servicio.llamadas, 1);

      servicio.espera!.complete();
      await tester.pumpAndSettle();

      expect(servicio.llamadas, 1);
      expect(find.text('Venta registrada'), findsOneWidget);
    });

    testWidgets('si falla informa, conserva la selección y permite reintentar',
        (tester) async {
      _pantalla(tester);
      servicio.fallar = true;
      await tester.pumpWidget(_app(overrides));
      await tester.pumpAndSettle();

      await tester.tap(_producto('Coca Cola'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmar());
      await tester.pumpAndSettle();

      expect(find.text(mensajeErrorGuardado), findsOneWidget);
      expect(find.text('Venta registrada'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Subtotal: Q10.50'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(_confirmar()).onPressed, isNotNull);

      servicio.fallar = false;
      await tester.tap(_confirmar());
      await tester.pumpAndSettle();

      expect(servicio.llamadas, 2);
      expect(find.text('Venta registrada'), findsOneWidget);
    });

    testWidgets('no se puede confirmar con una cantidad inválida',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(overrides));
      await tester.pumpAndSettle();

      await tester.tap(_producto('Coca Cola'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      expect(tester.widget<ElevatedButton>(_confirmar()).onPressed, isNull);
      expect(servicio.llamadas, 0);
    });
  });

  group('con SQLite real', () {
    late Directory carpeta;

    // Carpeta propia para no compartir cabal.db con otros archivos de test,
    // que se ejecutan en paralelo.
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      carpeta = Directory.systemTemp.createTempSync('cabal_venta_test_');
      await databaseFactory.setDatabasesPath(carpeta.path);
    });

    setUp(() async {
      await DatabaseService.instance.close();
      await deleteDatabase('${await getDatabasesPath()}/cabal.db');

      final productos = ProductoService();
      await productos.crearProducto(_cola);
      await productos.crearProducto(_pan);
    });

    tearDownAll(() async {
      await DatabaseService.instance.close();
      carpeta.deleteSync(recursive: true);
    });

    testWidgets('guarda venta y detalles y persisten tras reabrir la base',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(const []));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      await tester.tap(_producto('Coca Cola'));
      await tester.tap(_producto('Pan dulce'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '3');
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(_confirmar());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      expect(find.text('Venta registrada'), findsOneWidget);
      expect(find.text('Total: Q34.00'), findsOneWidget);

      // "Reiniciar": se cierra la base y se vuelve a abrir desde el archivo.
      await tester.runAsync(() async {
        await DatabaseService.instance.close();
        final db = await DatabaseService.instance.database;

        final ventas = await db.query('venta');
        expect(ventas.length, 1);

        final detalles =
            await db.query('detalle_venta', orderBy: 'producto_id');
        expect(detalles.length, 2);
        expect(detalles[0]['venta_id'], ventas.first['id']);
        expect(detalles[0]['producto_id'], 'p1');
        expect(detalles[0]['cantidad'], 3);
        expect(detalles[0]['precio_al_momento'], 10.5);
        expect(detalles[1]['producto_id'], 'p2');
        expect(detalles[1]['cantidad'], 1);
        expect(detalles[1]['precio_al_momento'], 2.5);

        final venta =
            await VentaService().obtenerVenta(ventas.first['id'] as String);
        expect(venta, isNotNull);
        expect(venta!.detalles.length, 2);
      });
    });
  });
}
