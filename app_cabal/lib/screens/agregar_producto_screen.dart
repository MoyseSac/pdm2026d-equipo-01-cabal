import 'package:flutter/material.dart';

import '../constants/iconos_producto.dart';
import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../services/imagen_producto_service.dart';
import '../services/producto_service.dart';
import '../validators/producto_validator.dart';
import '../widgets/producto_imagen_widget.dart';
import '../widgets/icono_producto_widget.dart';

/// Formulario de producto. Sin [producto] agrega uno nuevo; con [producto]
/// edita ese mismo (conserva su id) y arranca con sus valores.
class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({
    super.key,
    this.producto,
    required this.onGuardar,
    required this.imagenes,
  });

  final Producto? producto;

  /// Guarda el producto ya armado. La pantalla no sabe si va a SQL ni a donde.
  final Future<void> Function(Producto producto) onGuardar;

  /// Elige y borra las fotos. Llega de fuera para que la pantalla no busque
  /// nada en ningun provider.
  final ImagenProductoService imagenes;

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
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
    _imagenes = widget.imagenes;
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
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Text(
              'Elige un icono',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final escala = MediaQuery.textScalerOf(context);
                  final columnas =
                      (constraints.maxWidth / (144 * escala.scale(13) / 13))
                          .ceil()
                          .clamp(1, 6);
                  final ancho =
                      (constraints.maxWidth - 32 - (columnas - 1) * 8) /
                      columnas;
                  var altoTexto = 0.0;
                  for (final categoria in iconosProducto.values) {
                    final texto = TextPainter(
                      text: TextSpan(
                        text: categoria.etiqueta,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: escala,
                    )..layout(maxWidth: ancho - 8);
                    if (texto.height > altoTexto) altoTexto = texto.height;
                    texto.dispose();
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      mainAxisExtent: 80 + altoTexto,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: iconosProducto.length,
                    itemBuilder: (context, index) {
                      final entrada = iconosProducto.entries.elementAt(index);
                      final seleccionado = _imagen.claveIcono == entrada.key;
                      return Semantics(
                        button: true,
                        selected: seleccionado,
                        child: Material(
                          color: seleccionado
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(entrada.key),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconoProductoWidget(
                                  clave: entrada.key,
                                  size: 48,
                                  excluirSemantica: true,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    entrada.value.etiqueta,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            content: Text(
              e is NombreRepetidoException
                  ? e.toString()
                  : 'Error al guardar: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
