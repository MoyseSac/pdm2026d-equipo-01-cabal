/// Lo que se dibuja junto a un producto: nada, un icono del registro fijo
/// o una foto propia. Es una sola eleccion, asi que un producto no puede
/// quedar con foto e icono a la vez.
sealed class ImagenProducto {
  const ImagenProducto();

  /// Valor para la columna `imagen`: solo una foto la llena.
  String? get archivoFoto => switch (this) {
    FotoElegida(:final archivo) => archivo,
    _ => null,
  };

  /// Valor para la columna `icono`: solo un icono la llena.
  String? get claveIcono => switch (this) {
    IconoElegido(:final clave) => clave,
    _ => null,
  };
}

class SinImagen extends ImagenProducto {
  const SinImagen();
}

/// [clave] apunta al registro de constants/iconos_producto.dart.
class IconoElegido extends ImagenProducto {
  const IconoElegido(this.clave);

  final String clave;
}

/// [archivo] es solo el nombre del archivo dentro de la carpeta de
/// imagenes; la ruta absoluta del contenedor cambia entre versiones en iOS.
class FotoElegida extends ImagenProducto {
  const FotoElegida(this.archivo);

  final String archivo;
}
