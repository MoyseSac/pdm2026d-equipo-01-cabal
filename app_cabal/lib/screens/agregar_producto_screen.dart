import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/iconos_producto.dart';
import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../providers/imagen_producto_provider.dart';
import '../services/imagen_producto_service.dart';
import '../validators/producto_validator.dart';
import '../widgets/producto_imagen_widget.dart';

/// Formulario de producto. Sin [producto] agrega uno nuevo; con [producto]
/// edita ese mismo (conserva su id) y arranca con sus valores.
class AgregarProductoScreen extends ConsumerStatefulWidget {
  const AgregarProductoScreen({
    super.key,
    this.producto,
    required this.onGuardar,
  });

  final Producto? producto;

  /// Guarda el producto ya armado. La pantalla no sabe si va a SQL ni a donde.
  final Future<void> Function(Producto producto) onGuardar;

  @override
  ConsumerState<AgregarProductoScreen> createState() =>
      _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends ConsumerState<AgregarProductoScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nombreController;
  late final TextEditingController _precioController;
  late final ImagenProductoService _imagenes;
  late ImagenProducto _imagen;

  /// Fotos copiadas mientras el formulario estuvo abierto. Las que no queden
  /// guardadas en el producto se borran para no dejar archivos huerfanos.
  final Set<String> _fotosNuevas = {};
  bool _guardado = false;
  bool _isLoading = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    final producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre);
    // Siempre 2 decimales: 10.0 se mostraria "10.0" y 10.5 como "10.5".
    _precioController = TextEditingController(
      text: producto?.precio.toStringAsFixed(2),
    );
    _imagenes = ref.read(imagenProductoServiceProvider);
    _imagen = producto?.imagenProducto ?? const SinImagen();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    if (!_guardado) _fotosNuevas.forEach(_borrarFoto);
    super.dispose();
  }

  /// Un archivo que no se pudo borrar solo ocupa espacio; no debe impedir
  /// guardar ni salir del formulario.
  Future<void> _borrarFoto(String archivo) async {
    try {
      await _imagenes.borrar(archivo);
    } catch (_) {}
  }

  Future<void> _elegirFoto({required bool camara}) async {
    try {
      final archivo = await _imagenes.elegir(camara: camara);
      if (archivo == null || !mounted) return;
      _fotosNuevas.add(archivo);
      setState(() => _imagen = FotoElegida(archivo));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cargar la foto. Puedes usar un icono o guardar sin imagen.',
          ),
        ),
      );
    }
  }

  Future<void> _elegirIcono() async {
    final clave = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => GridView.extent(
        maxCrossAxisExtent: 96,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        shrinkWrap: true,
        children: [
          for (final MapEntry(key: clave, value: icono)
              in iconosProducto.entries)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(clave),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono.icono, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    icono.etiqueta,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (clave == null || !mounted) return;
    setState(() => _imagen = IconoElegido(clave));
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nombre = _nombreController.text.trim();
      final precio = double.parse(_precioController.text.trim());

      final existente = widget.producto;

      if (existente == null) {
        await widget.onGuardar(
          Producto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nombre: nombre,
            precio: precio,
            imagen: _imagen.archivoFoto,
            icono: _imagen.claveIcono,
          ),
        );
      } else {
        // Se conserva el id: otro id insertaria un producto nuevo.
        await widget.onGuardar(
          existente.copyWith(
            nombre: nombre,
            precio: precio,
            imagenProducto: _imagen,
          ),
        );
      }

      _guardado = true;
      // Solo despues de guardar: si la base falla, la foto anterior sigue
      // siendo la del producto.
      final fotoGuardada = _imagen.archivoFoto;
      final anterior = existente?.imagen;
      for (final archivo in {..._fotosNuevas, ?anterior}) {
        if (archivo != fotoGuardada) await _borrarFoto(archivo);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _seccionImagen(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  hintText: 'Ej: Coca Cola',
                  border: OutlineInputBorder(),
                ),
                validator: ProductoValidator.validarNombre,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  hintText: 'Ej: 10.50',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: ProductoValidator.validarPrecio,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarProducto,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _esEdicion ? 'Guardar cambios' : 'Guardar producto',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionImagen() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductoImagenWidget(imagen: _imagen, size: 88),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: () => _elegirFoto(camara: false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Elegir foto'),
              ),
              if (_imagenes.admiteCamara)
                OutlinedButton.icon(
                  onPressed: () => _elegirFoto(camara: true),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Tomar foto'),
                ),
              OutlinedButton.icon(
                onPressed: _elegirIcono,
                icon: const Icon(Icons.category),
                label: const Text('Usar icono'),
              ),
              if (_imagen is! SinImagen)
                TextButton.icon(
                  onPressed: () => setState(() => _imagen = const SinImagen()),
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
