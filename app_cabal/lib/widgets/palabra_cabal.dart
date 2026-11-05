import 'package:flutter/widgets.dart';

import '../constants/colores_cabal.dart';

/// La palabra CABAL con cada letra apareciendo despues de la anterior.
///
/// [animacion] va de 0 a 1 (en la pantalla de entrada es el mismo
/// controller que anima el logo). La letra i empieza en
/// `inicio + i * escalon` y dura [duracionLetra], todo como fraccion de
/// [animacion]. Con los valores por defecto la ultima letra termina en 0.88.
/// La ultima letra (la L) usa [colorUltima].
class PalabraCabal extends StatelessWidget {
  const PalabraCabal({
    super.key,
    required this.animacion,
    this.tamano = 40,
    this.color = const Color(0xFFFFFFFF),
    this.colorUltima = ColoresCabal.menta,
    this.inicio = 0.40,
    this.escalon = 0.07,
    this.duracionLetra = 0.20,
  });

  /// Palabra ya completa, sin animar.
  const PalabraCabal.completa({
    super.key,
    this.tamano = 40,
    this.color = const Color(0xFFFFFFFF),
    this.colorUltima = ColoresCabal.menta,
  }) : animacion = const AlwaysStoppedAnimation(1),
       inicio = 0,
       escalon = 0,
       duracionLetra = 1;

  static const String palabra = 'CABAL';

  final Animation<double> animacion;
  final double tamano;
  final Color color;
  final Color colorUltima;
  final double inicio;
  final double escalon;
  final double duracionLetra;

  /// Cuanto sube cada letra al aparecer, en puntos logicos.
  static const double _desplazamiento = 14;

  @override
  Widget build(BuildContext context) {
    final espaciado = tamano * 0.1;
    return Semantics(
      label: 'Cabal',
      excludeSemantics: true,
      // Flutter agrega el espaciado despues de cada letra, tambien de la
      // ultima; el padding izquierdo lo compensa para que quede centrada.
      child: Padding(
        padding: EdgeInsets.only(left: espaciado),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < palabra.length; i++)
              _Letra(
                letra: palabra[i],
                progreso: animacion.drive(
                  CurveTween(
                    curve: Interval(
                      (inicio + i * escalon).clamp(0.0, 1.0),
                      (inicio + i * escalon + duracionLetra).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                estilo: TextStyle(
                  fontFamily: 'Montserrat',
                  fontVariations: const [FontVariation('wght', 800)],
                  fontWeight: FontWeight.w800,
                  fontSize: tamano,
                  letterSpacing: espaciado,
                  height: 1,
                  color: i == palabra.length - 1 ? colorUltima : color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Letra extends StatelessWidget {
  const _Letra({
    required this.letra,
    required this.progreso,
    required this.estilo,
  });

  final String letra;
  final Animation<double> progreso;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progreso,
      child: Text(letra, style: estilo),
      builder: (context, hijo) => Opacity(
        opacity: progreso.value,
        child: Transform.translate(
          offset: Offset(
            0,
            (1 - progreso.value) * PalabraCabal._desplazamiento,
          ),
          child: hijo,
        ),
      ),
    );
  }
}
