/// Formatea una fecha y hora como dd/mm/aaaa hh:mm, por ejemplo
/// 15/10/2026 21:05.
String formatearFechaHora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}
