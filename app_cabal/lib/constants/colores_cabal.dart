import 'dart:ui';

/// Paleta de Cabal ("Marino y verde"). Solo constantes, sin depender de
/// Flutter widgets ni de las pantallas, igual que app_routes.dart.
///
/// El menta solo se usa sobre fondo marino: sobre claro casi no se ve
/// (contraste menor a 2), ahi se usa [verdeOscuro].
class ColoresCabal {
  ColoresCabal._();

  /// Fondo de la pantalla de entrada y barras.
  static const Color marino = Color(0xFF0A2342);

  /// Acento sobre fondo marino (contraste 8.92).
  static const Color menta = Color(0xFF3DDC97);

  /// Acento sobre fondo claro y botones con texto blanco (contraste 4.96).
  static const Color verdeOscuro = Color(0xFF1B7F5C);

  /// Fondo de las pantallas internas.
  static const Color fondoClaro = Color(0xFFF4F8F7);

  /// Texto secundario sobre [fondoClaro] (contraste 6.23).
  static const Color textoSuave = Color(0xFF4B5F6B);

  // Colores que la paleta aprobada no traia y que el tema necesita. Se
  // eligieron con el mismo criterio: contraste calculado, no a ojo.

  /// Errores y borrar. Blanco sobre este rojo da 6.54; sobre [fondoClaro], 6.11.
  static const Color error = Color(0xFFB3261E);

  /// Fondo suave verdoso (indicador de la barra de navegacion). Texto
  /// [marino] encima da 13.49. No poner [verdeOscuro] encima: da 4.24.
  static const Color mentaClaro = Color(0xFFD3F5E6);

  /// Bordes de campos y botones, e iconos apagados. Contraste 3.51 sobre
  /// [fondoClaro] y 3.76 sobre blanco (el minimo para elementos de interfaz es 3).
  static const Color borde = Color(0xFF738884);

  /// Borde decorativo de tarjetas y divisores. No lleva informacion, por eso
  /// no necesita el contraste de [borde].
  static const Color bordeSuave = Color(0xFFD5E0DD);

  /// Fondo de la imagen generica de un producto. [textoSuave] encima da 5.50.
  static const Color superficieTenue = Color(0xFFE3EBE8);
}
