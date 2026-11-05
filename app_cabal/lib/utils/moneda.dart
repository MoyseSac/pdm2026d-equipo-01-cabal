/// Formatea un monto en quetzales con dos decimales y separador de miles, por
/// ejemplo Q10.50 o Q1,540.50.
String formatearQuetzales(double monto) {
  final texto = monto.abs().toStringAsFixed(2);
  final punto = texto.indexOf('.');
  final enteros = texto.substring(0, punto);
  final decimales = texto.substring(punto);

  final grupos = StringBuffer();
  for (var i = 0; i < enteros.length; i++) {
    if (i > 0 && (enteros.length - i) % 3 == 0) grupos.write(',');
    grupos.write(enteros[i]);
  }

  final signo = monto < 0 && texto != '0.00' ? '-' : '';
  return '${signo}Q$grupos$decimales';
}
