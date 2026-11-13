import 'package:flutter/material.dart';

import '../constants/iconos_producto.dart';
import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../services/imagen_producto_service.dart';
import '../services/producto_service.dart';
import '../validators/producto_validator.dart';
import '../widgets/producto_imagen_widget.dart';
import '../widgets/aviso_en_linea.dart';
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
  String? _errorImagen;
  String? _errorGuardado;

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
      setState(() {
        _imagen = FotoElegida(archivo);
        _errorImagen = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorImagen =
            'No se pudo cargar la foto. Puedes usar un icono o guardar sin imagen.',
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
    setState(() {
      _imagen = IconoElegido(clave);
      _errorImagen = null;
    });
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorGuardado = null;
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
        setState(
          () => _errorGuardado = e is NombreRepetidoException
              ? e.toString()
              : 'No se pudo guardar el producto. Intenta de nuevo.',
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
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto'),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colores.surfaceContainerLowest,
              border: Border(top: BorderSide(color: colores.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorGuardado != null) ...[
                      AvisoEnLinea(mensaje: _errorGuardado!),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: _isLoading ? null : _guardarProducto,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _esEdicion
                                    ? 'Guardar cambios'
                                    : 'Guardar producto',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _seccionImagen(),
                          const SizedBox(height: 28),
                          Text('Datos del producto', style: textos.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa el nombre y el precio de venta.',
                            style: textos.bodyMedium?.copyWith(
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nombreController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              hintText: 'Ej: Coca Cola',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              if (_errorGuardado != null) {
                                setState(() => _errorGuardado = null);
                              }
                            },
                            validator: ProductoValidator.validarNombre,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _precioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio de venta',
                              hintText: '0.00',
                              prefixText: 'Q ',
                              helperText: 'Precio por unidad en quetzales',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) {
                              if (_errorGuardado != null) {
                                setState(() => _errorGuardado = null);
                              }
                            },
                            validator: ProductoValidator.validarPrecio,
                          ),
                        ],
                      ),
                    ),
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
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: colores.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colores.outlineVariant),
      ),
      child: Column(
        children: [
          if (_imagen is SinImagen)
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: colores.onPrimaryContainer,
              ),
            )
          else
            ProductoImagenWidget(imagen: _imagen, size: 112),
          const SizedBox(height: 12),
          Text('Imagen del producto', style: textos.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Agrega una foto o elige un icono. Es opcional.',
            textAlign: TextAlign.center,
            style: textos.bodySmall?.copyWith(color: colores.onSurfaceVariant),
          ),
          if (_errorImagen != null) ...[
            const SizedBox(height: 12),
            AvisoEnLinea(mensaje: _errorImagen!),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _elegirFoto(camara: false),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Elegir foto'),
              ),
              TextButton.icon(
                onPressed: _elegirIcono,
                icon: const Icon(Icons.category_outlined, size: 20),
                label: const Text('Usar icono'),
              ),
              if (_imagenes.admiteCamara)
                TextButton.icon(
                  onPressed: () => _elegirFoto(camara: true),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  label: const Text('Tomar foto'),
                ),
              if (_imagen is! SinImagen)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _imagen = const SinImagen();
                    _errorImagen = null;
                  }),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Quitar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
