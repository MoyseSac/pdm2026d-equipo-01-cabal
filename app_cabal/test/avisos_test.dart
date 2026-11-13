import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/catalogo_provider.dart';
import 'package:app_cabal/providers/cierre_provider.dart';
import 'package:app_cabal/providers/ventas_registradas_provider.dart';
import 'package:app_cabal/screens/home_shell.dart';
import 'package:app_cabal/utils/avisos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> abrir(WidgetTester tester) async {
  late BuildContext contexto;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            contexto = context;
            return const Text('Contenido');
          },
        ),
      ),
    ),
  );
  return contexto;
}

void main() {
  testWidgets(
    'el último aviso reemplaza los anteriores y desaparece a los dos segundos',
    (tester) async {
      final contexto = await abrir(tester);
      for (final mensaje in ['Primero', 'Segundo', 'Tercero']) {
        mostrarAvisoTemporal(contexto, contenido: Text(mensaje));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Primero'), findsNothing);
      expect(find.text('Segundo'), findsNothing);
      expect(find.text('Tercero'), findsOneWidget);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 2),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      expect(find.byType(SnackBar), findsNothing);
    },
  );
  testWidgets('Deshacer ofrece cinco segundos y permite recuperar la acción', (
    tester,
  ) async {
    final contexto = await abrir(tester);
    var restauraciones = 0;
    mostrarAvisoTemporal(
      contexto,
      contenido: const Text('Eliminado'),
      accion: SnackBarAction(
        label: 'Deshacer',
        onPressed: () => restauraciones++,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 5),
    );
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).showCloseIcon,
      isTrue,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Deshacer'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(restauraciones, 1);
  });
  testWidgets(
    'la acción de Deshacer respeta la lectura accesible sin forzar el tiempo',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final contexto = await abrir(tester);
      mostrarAvisoTemporal(
        contexto,
        contenido: const Text('Eliminado'),
        accion: SnackBarAction(label: 'Deshacer', onPressed: () {}),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    },
  );
  testWidgets('los errores temporales se pueden cerrar sin esperar', (
    tester,
  ) async {
    final contexto = await abrir(tester);
    mostrarAvisoTemporal(
      contexto,
      contenido: const Text('No se pudo eliminar'),
      error: true,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 5),
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('un aviso de otra pestaña no sigue encima del contenido nuevo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogoProductosProvider.overrideWith(
            (ref) async => const [Producto(id: 'p', nombre: 'Pan', precio: 1)],
          ),
          ventasRegistradasProvider.overrideWith((ref) async => []),
          cierreHoyProvider.overrideWith(
            (ref) async => throw Exception('sin cierre de prueba'),
          ),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
    mostrarAvisoTemporal(
      tester.element(find.byType(HomeShell)),
      contenido: const Text('Aviso del catálogo'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Vender'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aviso del catálogo'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
