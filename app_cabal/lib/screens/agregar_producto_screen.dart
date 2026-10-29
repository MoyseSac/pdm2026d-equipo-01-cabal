import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../validators/producto_validator.dart';

/// Formulario de producto. Sin [producto] agrega uno nuevo; con [producto]
/// edita ese mismo (conserva su id) y arranca con sus valores.
class AgregarProductoScreen extends ConsumerStatefulWidget {
  const AgregarProductoScreen({super.key, this.producto});

  final Producto? producto;

  @override
  ConsumerState<AgregarProductoScreen> createState() =>
      _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends ConsumerState<AgregarProductoScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nombreController;
  late final TextEditingController _precioController;
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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
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

      final notifier = ref.read(productoProvider.notifier);
      final existente = widget.producto;

      if (existente == null) {
        await notifier.agregarProducto(
          Producto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nombre: nombre,
            precio: precio,
          ),
        );
      } else {
        // Se conserva el id: otro id insertaria un producto nuevo.
        await notifier.editarProducto(
          existente.copyWith(nombre: nombre, precio: precio),
        );
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
}
