/// Reglas de cantidad de un detalle de venta (docs/reglas_negocio_ventas.md,
/// seccion 3): entero mayor que cero.
class CantidadValidator {
  static const mensajeInvalida = 'Ingresa una cantidad válida.';
  static const mensajeNoEntera = 'La cantidad debe ser un número entero.';
  static const mensajeNoPositiva = 'La cantidad debe ser mayor que cero.';

  /// Devuelve el mensaje de error, o null si la cantidad es valida.
  static String? validar(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) return mensajeInvalida;

    final entero = int.tryParse(texto);
    if (entero != null) {
      return entero > 0 ? null : mensajeNoPositiva;
    }

    final decimal = double.tryParse(texto);
    if (decimal != null && decimal.isFinite) return mensajeNoEntera;

    return mensajeInvalida;
  }
}
