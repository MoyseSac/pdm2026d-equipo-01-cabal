import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';

/// Pantalla de registrar venta. Por ahora solo permite seleccionar
/// productos del catalogo y armar la venta actual en memoria; guardar la
/// venta y calcular el total definitivo quedan para issues posteriores.
class RegistrarVentaScreen extends ConsumerStatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  ConsumerState<RegistrarVentaScreen> createState() =>
      _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends ConsumerState<RegistrarVentaScreen> {
  final List<DetalleVenta> _seleccion = [];

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

  void _disminuir(int index) {
    final cantidad = _seleccion[index].cantidad;
    if (cantidad <= 1) return;
    setState(() => _cambiarCantidad(index, cantidad - 1));
  }

  void _aumentar(int index) {
    setState(() => _cambiarCantidad(index, _seleccion[index].cantidad + 1));
  }

  void _eliminar(int index) {
    setState(() => _seleccion.removeAt(index));
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _seleccion.isEmpty
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed(AppRoutes.confirmacionVenta),
                      child: const Text('Confirmar venta (placeholder)'),
                    ),
                  ),
                ),
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
                subtitle: Text('\$${producto.precio.toStringAsFixed(2)}'),
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
                    return ListTile(
                      title: Text(
                        detalle.producto.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '\$${detalle.precioAlMomento.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Quitar una unidad',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: detalle.cantidad > 1
                                ? () => _disminuir(index)
                                : null,
                          ),
                          Text(
                            '${detalle.cantidad}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Agregar una unidad',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _aumentar(index),
                          ),
                          IconButton(
                            tooltip: 'Eliminar de la venta',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _eliminar(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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
