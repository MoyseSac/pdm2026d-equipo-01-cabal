class ActividadVentasDia {
  const ActividadVentasDia({
    required this.dia,
    required this.ventas,
    required this.centavos,
  });

  final DateTime dia;
  final int ventas;
  final int centavos;

  double get total => centavos / 100;
}
