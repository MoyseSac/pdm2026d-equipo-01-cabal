class ProductoValidator {
  static String? validarNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el nombre del producto.';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Ingresa el nombre del producto.';
    }

    return null;
  }

  static String? validarPrecio(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el precio del producto.';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Ingresa el precio del producto.';
    }

    double? precio;
    try {
      precio = double.parse(trimmed);
    } catch (e) {
      return 'Ingresa un precio válido.';
    }

    if (precio <= 0) {
      return 'El precio debe ser mayor que cero.';
    }

    final decimalPart = trimmed.split('.');
    if (decimalPart.length > 1 && decimalPart[1].length > 2) {
      return 'El precio puede tener máximo 2 decimales.';
    }

    return null;
  }
}
