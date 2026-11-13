import 'package:flutter/material.dart';

/// La fila anima su entrada una sola vez. Deslizar sigue a cargo de Dismissible.
class FilaCatalogoAnimada extends StatefulWidget {
  const FilaCatalogoAnimada({
    super.key,
    required this.child,
    required this.animarEntrada,
  });
  final Widget child;
  final bool animarEntrada;

  @override
  State<FilaCatalogoAnimada> createState() => FilaCatalogoAnimadaState();
}

class FilaCatalogoAnimadaState extends State<FilaCatalogoAnimada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  bool _iniciada = false;
  bool _retirando = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
      value: widget.animarEntrada ? 0 : 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = _retirando ? 0 : 1;
    } else if (!_iniciada && widget.animarEntrada) {
      _controlador.forward();
    }
    _iniciada = true;
  }

  Future<void> retirar() async {
    if (_retirando) return;
    setState(() => _retirando = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = 0;
      return;
    }
    try {
      await _controlador.reverse().orCancel;
    } on TickerCanceled {
      // La búsqueda o la navegación pueden desmontar la fila durante su salida.
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      alignment: Alignment.topCenter,
      sizeFactor: _controlador.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _controlador,
        child: ExcludeFocus(
          excluding: _retirando,
          child: ExcludeSemantics(
            excluding: _retirando,
            child: IgnorePointer(ignoring: _retirando, child: widget.child),
          ),
        ),
      ),
    );
  }
}
