import 'package:flutter/material.dart';

import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';

/// Abre la hoja para elegir cuantas unidades de [producto] agregar a la
/// venta. Devuelve la cantidad elegida, o null si se cierra sin confirmar.
/// [yaEnVenta] solo informa: la cantidad elegida se suma a la existente.
Future<int?> mostrarCantidadProducto(
  BuildContext context,
  Producto producto, {
  int yaEnVenta = 0,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        CantidadProductoSheet(producto: producto, yaEnVenta: yaEnVenta),
  );
}

class CantidadProductoSheet extends StatefulWidget {
  final Producto producto;
  final int yaEnVenta;

  const CantidadProductoSheet({
    super.key,
    required this.producto,
    this.yaEnVenta = 0,
  });

  @override
  State<CantidadProductoSheet> createState() => _CantidadProductoSheetState();
}

class _CantidadProductoSheetState extends State<CantidadProductoSheet> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final subtotal = subtotalDe(
      DetalleVenta(
        producto: producto,
        cantidad: _cantidad,
        precioAlMomento: producto.precio,
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              formatearQuetzales(producto.precio),
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.yaEnVenta > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ya en la venta: ${widget.yaEnVenta}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Quitar una unidad',
                  icon: const Icon(Icons.remove),
                  onPressed: _cantidad > 1
                      ? () => setState(() => _cantidad--)
                      : null,
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '$_cantidad',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Agregar una unidad',
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _cantidad++),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_cantidad),
              child: Text(
                'Agregar a la venta · ${formatearQuetzales(subtotal)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
