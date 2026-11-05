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
}
