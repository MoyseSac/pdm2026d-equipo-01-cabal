import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../constants/colores_cabal.dart';

/// Logo de Cabal: una C (anillo abierto hacia la derecha) con un visto
/// adentro. Se dibuja con CustomPainter para no depender de paquetes ni de
/// imagenes, y porque asi el trazo se puede animar.
///
/// [anillo] y [visto] van de 0 a 1 y dicen cuanto del trazo se ha dibujado.
/// Quien lo usa decide el momento de cada uno (la pantalla de entrada los
/// saca de un mismo AnimationController con distintos Interval). Para
/// mostrarlo ya completo se usa [LogoCabal.completo].
class LogoCabal extends StatelessWidget {
  const LogoCabal({
    super.key,
    required this.anillo,
    required this.visto,
    this.tamano = 96,
    this.colorTrazo = const Color(0xFFFFFFFF),
    this.colorAcento = ColoresCabal.menta,
  });

  /// Logo sin animar. Sobre fondo claro conviene pasar
  /// `colorTrazo: ColoresCabal.marino` y `colorAcento: ColoresCabal.verdeOscuro`.
  const LogoCabal.completo({
    super.key,
    this.tamano = 96,
    this.colorTrazo = const Color(0xFFFFFFFF),
    this.colorAcento = ColoresCabal.menta,
  }) : anillo = const AlwaysStoppedAnimation(1),
       visto = const AlwaysStoppedAnimation(1);

  final Animation<double> anillo;
  final Animation<double> visto;
  final double tamano;
  final Color colorTrazo;
  final Color colorAcento;

  @override
  Widget build(BuildContext context) {
    // El logo es decorativo: la pantalla que lo usa ya dice "Cabal".
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(tamano),
        painter: _LogoPainter(
          anillo: anillo,
          visto: visto,
          colorTrazo: colorTrazo,
          colorAcento: colorAcento,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.anillo,
    required this.visto,
    required this.colorTrazo,
    required this.colorAcento,
  }) : super(repaint: Listenable.merge([anillo, visto]));

  final Animation<double> anillo;
  final Animation<double> visto;
  final Color colorTrazo;
  final Color colorAcento;

  // El dibujo se define en un cuadrado de 120 x 120 y se escala al tamano
  // real, igual que el boceto aprobado.
  static const double _lado = 120;

  // Anillo: circulo de radio 36, abierto a la derecha entre -45 y +45 grados.
  // Se recorre en sentido antihorario (angulo negativo): sale arriba a la
  // derecha, pasa por arriba, la izquierda y abajo, y termina abajo a la
  // derecha, 270 grados despues.
  static const Offset _centro = Offset(60, 60);
  static const double _radio = 36;
  static const double _anguloInicial = -math.pi / 4;
  static const double _barrido = -3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _lado, size.height / _lado);

    final anilloCompleto = Path()
      ..arcTo(
        Rect.fromCircle(center: _centro, radius: _radio),
        _anguloInicial,
        _barrido,
        true,
      );
    final vistoCompleto = Path()
      ..moveTo(46, 62)
      ..lineTo(57, 73)
      ..lineTo(76, 51);

    _trazar(
      canvas,
      anilloCompleto,
      anillo.value,
      14,
      colorTrazo,
      StrokeJoin.round,
    );
    _trazar(
      canvas,
      vistoCompleto,
      visto.value,
      10,
      colorAcento,
      StrokeJoin.round,
    );
  }

  /// Dibuja solo la fraccion [progreso] (0 a 1) del largo del trazo.
  void _trazar(
    Canvas canvas,
    Path completo,
    double progreso,
    double grosor,
    Color color,
    StrokeJoin union,
  ) {
    if (progreso <= 0) return;
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = union
      ..color = color;
    final p = progreso.clamp(0.0, 1.0);
    for (final tramo in completo.computeMetrics()) {
      canvas.drawPath(tramo.extractPath(0, tramo.length * p), pincel);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter anterior) =>
      anterior.colorTrazo != colorTrazo ||
      anterior.colorAcento != colorAcento ||
      anterior.anillo != anillo ||
      anterior.visto != visto;
}
