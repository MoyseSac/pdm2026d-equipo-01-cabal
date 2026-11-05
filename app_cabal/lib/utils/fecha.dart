/// Formatea una fecha y hora como dd/mm/aaaa hh:mm, por ejemplo
/// 15/10/2026 21:05.
String formatearFechaHora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

/// Formatea solo la fecha como dd/mm/aaaa, por ejemplo 15/10/2026.
String formatearFecha(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

/// Formatea solo la hora como hh:mm, por ejemplo 21:05.
String formatearHora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');

  return '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

const _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Formatea la fecha en palabras, por ejemplo "jueves 5 de noviembre".
String formatearFechaLarga(DateTime fecha) {
  return '${_diasSemana[fecha.weekday - 1]} ${fecha.day} de '
      '${_meses[fecha.month - 1]}';
}
