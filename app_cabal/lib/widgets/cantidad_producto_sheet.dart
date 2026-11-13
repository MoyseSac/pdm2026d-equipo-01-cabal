import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import 'producto_imagen_widget.dart';
import 'transicion_venta.dart';

/// La cantidad elegida se suma a [yaEnVenta]; cerrar la hoja no modifica la venta.
Future<int?> mostrarCantidadProducto(
  BuildContext context,
  Producto producto, {
  int yaEnVenta = 0,
}) {
  final reducir = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(
      duration: reducir ? Duration.zero : const Duration(milliseconds: 320),
      reverseDuration: reducir
          ? Duration.zero
          : const Duration(milliseconds: 220),
    ),
    builder: (context) {
      final teclado = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: teclado),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height - teclado) * 0.85,
          ),
          child: CantidadProductoSheet(
            producto: producto,
            yaEnVenta: yaEnVenta,
          ),
        ),
      );
    },
  );
}

class CantidadProductoSheet extends StatefulWidget {
  const CantidadProductoSheet({
    super.key,
    required this.producto,
    this.yaEnVenta = 0,
  });

  final Producto producto;
  final int yaEnVenta;

  @override
  State<CantidadProductoSheet> createState() => _CantidadProductoSheetState();
}

class _CantidadProductoSheetState extends State<CantidadProductoSheet> {
  final _cantidadController = TextEditingController(text: '1');
  bool _confirmado = false;

  int? get _cantidad {
    final valor = int.tryParse(_cantidadController.text);
    return valor != null && valor > 0 ? valor : null;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  void _establecerCantidad(int cantidad) {
    setState(() {
      _cantidadController.value = TextEditingValue(
        text: '$cantidad',
        selection: TextSelection.collapsed(offset: '$cantidad'.length),
      );
    });
  }

  void _ajustarCantidad(int cambio) {
    final nueva = (_cantidad ?? 0) + cambio;
    if (nueva > 0) _establecerCantidad(nueva);
  }

  void _confirmar() {
    final cantidad = _cantidad;
    if (cantidad == null || _confirmado) return;
    setState(() => _confirmado = true);
    Navigator.of(context).pop(cantidad);
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final cantidad = _cantidad;
    final subtotal = cantidad == null
        ? null
        : subtotalDe(
            DetalleVenta(
              producto: producto,
              cantidad: cantidad,
              precioAlMomento: producto.precio,
            ),
          );
    final contenido = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductoImagenWidget(imagen: producto.imagenProducto, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: textos.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatearQuetzales(producto.precio)} por unidad',
                      style: textos.bodyMedium?.copyWith(
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.yaEnVenta > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Ya en la venta: ${widget.yaEnVenta}',
                style: textos.bodyMedium?.copyWith(
                  color: colores.onPrimaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('¿Cuántas unidades agregas?', style: textos.titleMedium),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton.filledTonal(
                  tooltip: 'Quitar una unidad',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.remove),
                  onPressed: !_confirmado && cantidad != null && cantidad > 1
                      ? () => _ajustarCantidad(-1)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cantidadController,
                  enabled: !_confirmado,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: textos.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    errorText: cantidad == null
                        ? 'Ingresa un entero mayor que cero.'
                        : null,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (antes, despues) =>
                          RegExp(r'^[0-9]*$').hasMatch(despues.text)
                          ? despues
                          : antes,
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _confirmar(),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton.filled(
                  tooltip: 'Agregar una unidad',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.add),
                  onPressed: _confirmado ? null : () => _ajustarCantidad(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cantidades rápidas',
            style: textos.bodySmall?.copyWith(color: colores.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final unidades in [5, 10, 25, 100])
                ChoiceChip(
                  label: Text('$unidades'),
                  selected: cantidad == unidades,
                  tooltip: 'Elegir $unidades unidades',
                  onSelected: _confirmado
                      ? null
                      : (_) => _establecerCantidad(unidades),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subtotal a agregar',
                  style: textos.labelLarge?.copyWith(
                    color: colores.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                TransicionVenta(
                  desplazar: true,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtotal == null ? '—' : formatearQuetzales(subtotal),
                    key: ValueKey(subtotal),
                    style: textos.headlineMedium?.copyWith(
                      color: colores.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final accion = Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onPressed: cantidad == null || _confirmado ? null : _confirmar,
          child: TransicionVenta(
            alignment: Alignment.center,
            child: _confirmado
                ? const Row(
                    key: ValueKey('agregado'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Flexible(child: Text('Agregado')),
                    ],
                  )
                : Text(
                    subtotal == null
                        ? 'Ingresa una cantidad'
                        : 'Agregar a la venta · ${formatearQuetzales(subtotal)}',
                    key: const ValueKey('agregar'),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxHeight < 280;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [contenido, if (compacto) accion],
                  ),
                ),
              ),
              if (!compacto) accion,
            ],
          );
        },
      ),
    );
  }
}
