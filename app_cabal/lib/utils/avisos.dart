import 'package:flutter/material.dart';

/// Cambiar de contexto descarta también la cola de avisos anteriores.
void limpiarAvisosTemporales(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..removeCurrentSnackBar();
}

/// Un solo aviso visible; nunca se encolan confirmaciones repetidas.
void mostrarAvisoTemporal(
  BuildContext context, {
  required Widget contenido,
  SnackBarAction? accion,
  bool error = false,
  double margenInferior = 12,
}) {
  limpiarAvisosTemporales(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: contenido,
      action: accion,
      duration: Duration(seconds: accion != null || error ? 5 : 2),
      showCloseIcon: true,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(12, 12, 12, margenInferior),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
