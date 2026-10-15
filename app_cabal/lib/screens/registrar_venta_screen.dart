import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import '../validators/cantidad_validator.dart';

/// Pantalla de registrar venta. Permite seleccionar productos del
/// catalogo, editar sus cantidades y ver subtotales y total. La venta en
/// curso vive en memoria de la pantalla; guardarla queda para un issue
/// posterior.
class RegistrarVentaScreen extends ConsumerStatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  ConsumerState<RegistrarVentaScreen> createState() =>
      _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends ConsumerState<RegistrarVentaScreen> {
  final List<DetalleVenta> _seleccion = [];

  /// Ids de productos cuya cantidad escrita es invalida en este momento.
  final Set<String> _invalidos = {};

  bool get _puedeConfirmar => _seleccion.isNotEmpty && _invalidos.isEmpty;

  /// Agrega el producto a la venta. Si ya estaba, no se duplica: se suma
  /// uno a su cantidad.
  void _seleccionar(Producto producto) {
    setState(() {
      final index = _seleccion.indexWhere((d) => d.producto.id == producto.id);
      if (index == -1) {
        _seleccion.add(DetalleVenta(
          producto: producto,
          cantidad: 1,
          precioAlMomento: producto.precio,
        ));
      } else {
        _cambiarCantidad(index, _seleccion[index].cantidad + 1);
        _invalidos.remove(producto.id);
      }
    });
  }

  void _cambiarCantidad(int index, int cantidad) {
    final actual = _seleccion[index];
    _seleccion[index] = DetalleVenta(
      producto: actual.producto,
      cantidad: cantidad,
      precioAlMomento: actual.precioAlMomento,
    );
  }

  void _establecerCantidad(String productoId, int cantidad) {
    setState(() {
      final index = _seleccion.indexWhere((d) => d.producto.id == productoId);
      if (index == -1) return;
      _cambiarCantidad(index, cantidad);
      _invalidos.remove(productoId);
    });
  }

  void _marcarInvalido(String productoId) {
    setState(() => _invalidos.add(productoId));
  }

  void _eliminar(String productoId) {
    setState(() {
      _seleccion.removeWhere((d) => d.producto.id == productoId);
      _invalidos.remove(productoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(productoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: productos.isEmpty
          ? const _SinProductos()
          : Column(
              children: [
                Expanded(child: _listaProductos(productos)),
                const Divider(height: 1),
                Expanded(child: _ventaActual()),
                _resumen(),
              ],
            ),
    );
  }

  Widget _listaProductos(List<Producto> productos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Productos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                title: Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatearQuetzales(producto.precio)),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => _seleccionar(producto),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _ventaActual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Venta actual',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _seleccion.isEmpty
              ? Center(
                  child: Text(
                    'Toca un producto para agregarlo a la venta',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _seleccion.length,
                  itemBuilder: (context, index) {
                    final detalle = _seleccion[index];
                    return _FilaDetalle(
                      key: ValueKey(detalle.producto.id),
                      detalle: detalle,
                      onCantidad: (c) =>
                          _establecerCantidad(detalle.producto.id, c),
                      onInvalida: () => _marcarInvalido(detalle.producto.id),
                      onEliminar: () => _eliminar(detalle.producto.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _resumen() {
    final total = totalDe(_seleccion);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                formatearQuetzales(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _puedeConfirmar
                  ? () => Navigator.of(context)
                      .pushNamed(AppRoutes.confirmacionVenta)
                  : null,
              child: const Text('Confirmar venta (placeholder)'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de un producto en la venta actual: cantidad editable (con +/-),
/// subtotal y boton para eliminar.
class _FilaDetalle extends StatefulWidget {
  final DetalleVenta detalle;
  final ValueChanged<int> onCantidad;
  final VoidCallback onInvalida;
  final VoidCallback onEliminar;

  const _FilaDetalle({
    super.key,
    required this.detalle,
    required this.onCantidad,
    required this.onInvalida,
    required this.onEliminar,
  });

  @override
  State<_FilaDetalle> createState() => _FilaDetalleState();
}

class _FilaDetalleState extends State<_FilaDetalle> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.detalle.cantidad}');
  }

  @override
  void didUpdateWidget(covariant _FilaDetalle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la cantidad cambio desde fuera (p. ej. se volvio a tocar el
    // producto), el campo vuelve a reflejar la cantidad valida.
    if (oldWidget.detalle.cantidad != widget.detalle.cantidad &&
        _controller.text.trim() != '${widget.detalle.cantidad}') {
      _controller.text = '${widget.detalle.cantidad}';
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    final error = CantidadValidator.validar(texto);
    setState(() => _error = error);
    if (error == null) {
      widget.onCantidad(int.parse(texto.trim()));
    } else {
      widget.onInvalida();
    }
  }

  void _fijar(int cantidad) {
    _controller.text = '$cantidad';
    setState(() => _error = null);
    widget.onCantidad(cantidad);
  }

  @override
  Widget build(BuildContext context) {
    final detalle = widget.detalle;
    final cantidad = detalle.cantidad;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detalle.producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      formatearQuetzales(detalle.precioAlMomento),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Subtotal: ${formatearQuetzales(subtotalDe(detalle))}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar una unidad',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: cantidad > 1 ? () => _fijar(cantidad - 1) : null,
              ),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    enabledBorder: _error == null
                        ? null
                        : const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                  ),
                  onChanged: _alEscribir,
                ),
              ),
              IconButton(
                tooltip: 'Agregar una unidad',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _fijar(cantidad + 1),
              ),
              IconButton(
                tooltip: 'Eliminar de la venta',
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onEliminar,
              ),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _SinProductos extends StatelessWidget {
  const _SinProductos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos registrados',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos al catálogo para registrar ventas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.agregarProducto),
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
