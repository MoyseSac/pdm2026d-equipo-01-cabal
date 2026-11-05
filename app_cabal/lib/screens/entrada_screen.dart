import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_routes.dart';
import '../constants/colores_cabal.dart';
import '../widgets/logo_cabal.dart';
import '../widgets/palabra_cabal.dart';

/// Pantalla de entrada. Cabal no tiene usuario ni contrasena: al abrir la
/// app se dibuja el logo, aparece la palabra CABAL letra por letra y la app
/// pasa sola a inicio. Tocar la pantalla salta la animacion.
///
/// Todo sale de un solo AnimationController de 2 segundos. Cada parte toma
/// su tramo con un Interval (fracciones de 0 a 1):
///
///   0.00 - 0.28  se dibuja el anillo de la C
///   0.26 - 0.40  se dibuja el visto
///   0.40 - 0.88  aparecen C, A, B, A, L (ver PalabraCabal)
///   0.88 - 1.00  pausa con todo visible; al llegar a 1 se navega
class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _duracion = Duration(milliseconds: 2000);

  /// Con las animaciones del sistema desactivadas se muestra la marca ya
  /// completa y solo corre este tiempo antes de pasar a inicio.
  static const Duration _pausaSinMovimiento = Duration(milliseconds: 300);

  /// Punto de la linea de tiempo donde ya esta todo visible. La ultima letra
  /// termina en 0.88; se usa 0.90 para que ninguna quede a medias por el
  /// redondeo de los decimales.
  static const double _marcaCompleta = 0.90;

  late final AnimationController _controlador;
  late final Animation<double> _anillo;
  late final Animation<double> _visto;
  bool _iniciada = false;
  bool _continuando = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: _duracion)
      ..addStatusListener(_alCambiarEstado);
    _anillo = _controlador.drive(
      CurveTween(curve: const Interval(0, 0.28, curve: Curves.easeInOut)),
    );
    _visto = _controlador.drive(
      CurveTween(curve: const Interval(0.26, 0.40, curve: Curves.easeOut)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery no se puede leer en initState, y solo se arranca una vez.
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Sin movimiento: se salta a la parte donde todo esta visible y se
      // deja correr solo la pausa final. Esa parte de la linea de tiempo
      // no tiene nada que se mueva.
      _controlador.value = _marcaCompleta;
      _controlador.animateTo(
        1,
        duration: _pausaSinMovimiento,
        curve: Curves.linear,
      );
    } else {
      _controlador.forward();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _alCambiarEstado(AnimationStatus estado) {
    if (estado == AnimationStatus.completed) _continuar();
  }

  /// Tocar la pantalla lleva la animacion al final; eso dispara
  /// [_alCambiarEstado] y se navega sin esperar la pausa.
  void _saltar() {
    if (_controlador.isCompleted) return;
    _controlador.value = 1;
  }

  /// Unico punto por el que se sale de esta pantalla. Cuando se agregue la
  /// huella o el desbloqueo del telefono, se pide aqui antes de navegar.
  void _continuar() {
    if (_continuando || !mounted) return;
    _continuando = true;
    // Se usa pushReplacementNamed porque la entrada no debe quedar en la
    // pila de navegacion: al presionar retroceso desde el inicio, no
    // queremos volver a ella.
    Navigator.of(context).pushReplacementNamed(AppRoutes.inicio);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresCabal.marino,
      // Fondo oscuro: iconos claros en la barra de estado, y la barra de
      // navegacion del mismo marino para que la pantalla se vea continua.
      // AnnotatedRegion (y no SystemChrome) porque al salir de esta pantalla
      // el estilo vuelve solo al de la pantalla siguiente.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColoresCabal.marino,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _saltar,
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LogoCabal(anillo: _anillo, visto: _visto, tamano: 120),
                  const SizedBox(height: 20),
                  PalabraCabal(animacion: _controlador),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
