/// Compara nombres sin distinguir mayúsculas, tildes ni espacios sobrantes.
String normalizarBusqueda(String texto) {
  const originales = 'áéíóúü';
  const reemplazos = 'aeiouu';
  var resultado = texto.toLowerCase().trim();
  for (var i = 0; i < originales.length; i++) {
    resultado = resultado.replaceAll(originales[i], reemplazos[i]);
  }
  // También contempla texto con acentos Unicode descompuestos.
  return resultado
      .replaceAll(RegExp('[\u0300-\u0308]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
