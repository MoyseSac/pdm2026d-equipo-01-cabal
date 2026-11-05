import 'dart:math' as math;

import 'package:app_cabal/constants/colores_cabal.dart';
import 'package:app_cabal/theme/tema_cabal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG 2.1 entre dos colores (de 1 a 21).
double _contraste(Color a, Color b) {
  double luminancia(Color c) {
    double canal(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  }

  final claro = math.max(luminancia(a), luminancia(b));
  final oscuro = math.min(luminancia(a), luminancia(b));
  return (claro + 0.05) / (oscuro + 0.05);
}

const _blanco = Color(0xFFFFFFFF);

void main() {
  final esquema = temaCabal.colorScheme;

  group('roles del ColorScheme', () {
    test('usan los colores de la paleta', () {
      expect(esquema.primary, ColoresCabal.verdeOscuro);
      expect(esquema.onPrimary, _blanco);
      expect(esquema.secondary, ColoresCabal.marino);
      expect(esquema.surface, ColoresCabal.fondoClaro);
      expect(esquema.onSurface, ColoresCabal.marino);
      expect(esquema.onSurfaceVariant, ColoresCabal.textoSuave);
      expect(esquema.error, ColoresCabal.error);
      expect(esquema.outline, ColoresCabal.borde);
      expect(esquema.primaryContainer, ColoresCabal.mentaClaro);
    });

    test('es un tema claro de Material 3', () {
      expect(temaCabal.useMaterial3, isTrue);
      expect(esquema.brightness, Brightness.light);
    });
  });

  group('contraste', () {
    // Texto: minimo 4.5 (WCAG AA).
    final parejasDeTexto = <String, (Color, Color)>{
      'onPrimary sobre primary (botones)': (esquema.onPrimary, esquema.primary),
      'onSurface sobre surface (texto principal)': (
        esquema.onSurface,
        esquema.surface,
      ),
      'onSurface sobre blanco (tarjetas)': (esquema.onSurface, _blanco),
      'onSurfaceVariant sobre surface (texto secundario)': (
        esquema.onSurfaceVariant,
        esquema.surface,
      ),
      'onSurfaceVariant sobre blanco': (esquema.onSurfaceVariant, _blanco),
      'onSurfaceVariant sobre superficie tenue (imagen generica)': (
        esquema.onSurfaceVariant,
        esquema.surfaceContainerHighest,
      ),
      'onError sobre error': (esquema.onError, esquema.error),
      'error sobre surface (mensajes de error)': (
        esquema.error,
        esquema.surface,
      ),
      'onPrimaryContainer sobre primaryContainer (barra de navegacion)': (
        esquema.onPrimaryContainer,
        esquema.primaryContainer,
      ),
      'blanco sobre marino (AppBar y SnackBar)': (_blanco, ColoresCabal.marino),
      'menta sobre marino (acento de la entrada)': (
        ColoresCabal.menta,
        ColoresCabal.marino,
      ),
      'primary sobre surface (botones de texto)': (
        esquema.primary,
        esquema.surface,
      ),
    };
    parejasDeTexto.forEach((nombre, par) {
      test('$nombre llega a 4.5', () {
        expect(
          _contraste(par.$1, par.$2),
          greaterThanOrEqualTo(4.5),
          reason: nombre,
        );
      });
    });

    // Elementos de interfaz (bordes, iconos): minimo 3.
    test('el borde llega a 3 sobre el fondo y sobre blanco', () {
      expect(
        _contraste(esquema.outline, esquema.surface),
        greaterThanOrEqualTo(3),
      );
      expect(_contraste(esquema.outline, _blanco), greaterThanOrEqualTo(3));
    });
  });

  group('aspecto de los componentes', () {
    Future<void> montar(WidgetTester tester, Widget cuerpo) =>
        tester.pumpWidget(MaterialApp(theme: temaCabal, home: cuerpo));

    testWidgets('el AppBar es marino con texto blanco', (tester) async {
      await montar(
        tester,
        Scaffold(appBar: AppBar(title: const Text('Catalogo'))),
      );

      final barra = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(barra.color, ColoresCabal.marino);
      // El estilo final del texto es el que llega a RichText, no el primer
      // DefaultTextStyle que se cruza hacia arriba.
      final titulo = tester.widget<RichText>(
        find.descendant(
          of: find.text('Catalogo'),
          matching: find.byType(RichText),
        ),
      );
      expect(titulo.text.style?.color, _blanco);
    });

    testWidgets('el boton flotante y los botones llenos son verde oscuro', (
      tester,
    ) async {
      await montar(
        tester,
        Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              FilledButton(onPressed: () {}, child: const Text('lleno')),
              ElevatedButton(onPressed: () {}, child: const Text('elevado')),
            ],
          ),
        ),
      );

      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .backgroundColor,
        isNull,
        reason: 'el color viene del tema, no del widget',
      );
      Color? fondo(Finder f) => tester
          .widget<Material>(
            find.descendant(of: f, matching: find.byType(Material)).first,
          )
          .color;
      expect(
        fondo(find.byType(FloatingActionButton)),
        ColoresCabal.verdeOscuro,
      );
      expect(fondo(find.byType(FilledButton)), ColoresCabal.verdeOscuro);
      expect(fondo(find.byType(ElevatedButton)), ColoresCabal.verdeOscuro);
    });

    testWidgets(
      'la barra de navegacion marca la pestana activa en menta claro',
      (tester) async {
        await montar(
          tester,
          Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Uno'),
                NavigationDestination(icon: Icon(Icons.list), label: 'Dos'),
              ],
            ),
          ),
        );

        final indicador = tester.widget<NavigationIndicator>(
          find.byType(NavigationIndicator).first,
        );
        expect(indicador.color, ColoresCabal.mentaClaro);
      },
    );
  });
}
