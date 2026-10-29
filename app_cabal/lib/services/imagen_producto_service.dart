import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Fotos de producto guardadas en `<documentos>/productos/`. Fuera de esta
/// clase solo circula el nombre del archivo.
class ImagenProductoService {
  ImagenProductoService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  Future<Directory>? _carpeta;

  Future<Directory> carpeta() => _carpeta ??= _crearCarpeta();

  Future<Directory> _crearCarpeta() async {
    final documentos = await getApplicationDocumentsDirectory();
    return Directory(
      p.join(documentos.path, 'productos'),
    ).create(recursive: true);
  }

  /// En escritorio no hay camara disponible para image_picker.
  bool get admiteCamara => _picker.supportsImageSource(ImageSource.camera);

  /// Copia la foto elegida a la carpeta de la app y devuelve su nombre, o
  /// null si se cancelo. La copia es necesaria porque image_picker entrega
  /// un archivo temporal que el sistema puede borrar.
  Future<String?> elegir({bool camara = false}) async {
    final elegida = await _picker.pickImage(
      source: camara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (elegida == null) return null;

    final extension = p.extension(elegida.path);
    // Un nombre nuevo en cada foto evita que Image.file muestre la anterior
    // desde su cache al reemplazarla.
    final archivo =
        '${DateTime.now().microsecondsSinceEpoch}'
        '${extension.isEmpty ? '.jpg' : extension}';
    await elegida.saveTo(p.join((await carpeta()).path, archivo));
    return archivo;
  }

  Future<void> borrar(String archivo) async {
    final foto = File(p.join((await carpeta()).path, archivo));
    if (await foto.exists()) await foto.delete();
  }
}
