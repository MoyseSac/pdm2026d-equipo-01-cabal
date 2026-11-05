import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colores_cabal.dart';

/// Tema de la app con la paleta de Cabal. Solo claro: la paleta no define
/// modo oscuro.
///
/// El ColorScheme se arma a mano y no con ColorScheme.fromSeed: fromSeed
/// inventa tonos a partir de un color y el resultado no seria exactamente la
/// paleta aprobada.
///
/// Regla para el resto del codigo: los colores salen de
/// `Theme.of(context).colorScheme`, no de `Colors.x`. Asi un cambio de paleta
/// se hace en un solo lugar. Ver docs/diseno-tema-de-color.md.
final ThemeData temaCabal = _crearTema();

ThemeData _crearTema() {
  const blanco = Color(0xFFFFFFFF);
  const transparente = Color(0x00000000);

  const esquema = ColorScheme(
    brightness: Brightness.light,
    primary: ColoresCabal.verdeOscuro,
    onPrimary: blanco,
    primaryContainer: ColoresCabal.mentaClaro,
    onPrimaryContainer: ColoresCabal.marino,
    secondary: ColoresCabal.marino,
    onSecondary: blanco,
    secondaryContainer: ColoresCabal.mentaClaro,
    onSecondaryContainer: ColoresCabal.marino,
    error: ColoresCabal.error,
    onError: blanco,
    surface: ColoresCabal.fondoClaro,
    onSurface: ColoresCabal.marino,
    onSurfaceVariant: ColoresCabal.textoSuave,
    outline: ColoresCabal.borde,
    outlineVariant: ColoresCabal.bordeSuave,
    // Material 3 pinta tarjetas, hojas, dialogos y la barra de navegacion con
    // estos "contenedores". Aqui todos son blancos, que se separan del fondo
    // claro de la pantalla sin recurrir a sombras ni a un tinte.
    surfaceContainerLowest: blanco,
    surfaceContainerLow: blanco,
    surfaceContainer: blanco,
    surfaceContainerHigh: blanco,
    surfaceContainerHighest: ColoresCabal.superficieTenue,
    surfaceTint: transparente,
    // SnackBar usa estos dos: queda marino con texto blanco.
    inverseSurface: ColoresCabal.marino,
    onInverseSurface: blanco,
    inversePrimary: ColoresCabal.menta,
  );

  const formaBoton = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: esquema.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresCabal.marino,
      foregroundColor: blanco,
      surfaceTintColor: transparente,
      scrolledUnderElevation: 0,
      // Fondo oscuro: iconos claros en la barra de estado del telefono.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: transparente,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: blanco,
      indicatorColor: ColoresCabal.mentaClaro,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? ColoresCabal.marino
              : ColoresCabal.textoSuave,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontSize: 12,
          fontWeight: estados.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: estados.contains(WidgetState.selected)
              ? ColoresCabal.marino
              : ColoresCabal.textoSuave,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ColoresCabal.verdeOscuro,
      foregroundColor: blanco,
    ),
    // ElevatedButton y FilledButton se ven igual: verde oscuro con texto
    // blanco. La app usa los dos y no debe haber dos botones principales.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresCabal.verdeOscuro,
        foregroundColor: blanco,
        shape: formaBoton,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresCabal.verdeOscuro,
        foregroundColor: blanco,
        shape: formaBoton,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresCabal.marino,
        side: const BorderSide(color: ColoresCabal.borde),
        shape: formaBoton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColoresCabal.verdeOscuro),
    ),
    // Los campos de texto no llevan tema propio: con este ColorScheme el borde
    // sale de `outline`, el foco y la etiqueta de `primary` y los errores de
    // `error`, que es lo que se busca. Un tema fijo pintaria la etiqueta de
    // verde incluso en un campo con error.
    cardTheme: CardThemeData(
      color: blanco,
      elevation: 0,
      surfaceTintColor: transparente,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ColoresCabal.bordeSuave),
      ),
    ),
    dividerTheme: const DividerThemeData(color: ColoresCabal.bordeSuave),
  );
}
