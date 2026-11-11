import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../models/detalle_venta.dart';
import '../providers/tab_provider.dart';
import '../providers/catalogo_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import '../validators/cantidad_validator.dart';
import '../widgets/transicion_venta.dart';

/// Pantalla de registrar venta. Muestra solo lo que ya se agrego a la venta
/// desde el catalogo: permite editar cantidades, ver subtotales y total, y
/// confirmar la venta. La venta en curso y su guardado viven en
/// ventaProvider.
class RegistrarVentaScreen extends ConsumerStatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  ConsumerState<RegistrarVentaScreen> createState() =>
      _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends ConsumerState<RegistrarVentaScreen> {
  /// Ids de productos cuya cantidad escrita es invalida en este momento.
  final Set<String> _invalidos = {};

  VentaNotifier get _venta => ref.read(ventaProvider.notifier);

  void _establecerCantidad(String productoId, int cantidad) {
    if (_venta.establecerCantidad(productoId, cantidad)) {
      setState(() => _invalidos.remove(productoId));
    }
  }

  void _marcarInvalido(String productoId) {
    setState(() => _invalidos.add(productoId));
  }

  void _eliminar(String productoId) {
    final detalles = ref.read(ventaProvider).detalles;
    final posicion = detalles.indexWhere((d) => d.producto.id == productoId);
    if (posicion == -1 || ref.read(ventaProvider).guardando) return;
    final detalle = detalles[posicion];
    _venta.quitarProducto(productoId);
    setState(() => _invalidos.remove(productoId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${detalle.producto.nombre} quitado de la venta',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _venta.restaurarDetalle(detalle, posicion),
          ),
        ),
      );
  }

  Future<void> _confirmar() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final guardada = await _venta.confirmarVenta();
    if (!guardada || !mounted) return;

    setState(_invalidos.clear);
    await Navigator.of(context).pushNamed(AppRoutes.confirmacionVenta);
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaProvider);
    ref.listen(ventaProvider, (anterior, nueva) {
      _invalidos.removeWhere((id) {
        final antes = anterior?.detalles
            .where((d) => d.producto.id == id)
            .firstOrNull;
        final ahora = nueva.detalles
            .where((d) => d.producto.id == id)
            .firstOrNull;
        return ahora == null || antes?.cantidad != ahora.cantidad;
      });
    });

    // Mientras se guarda no se permite salir de la pantalla, para que el
    // resultado del guardado no quede sin mostrar.
    return PopScope(
      canPop: !venta.guardando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar venta')),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (venta.detalles.isEmpty) {
                    return const TransicionVenta(
                      key: ValueKey('contenido-venta'),
                      desplazar: true,
                      alignment: Alignment.topCenter,
                      child: KeyedSubtree(
                        key: ValueKey('vacia'),
                        child: _VentaVacia(),
                      ),
                    );
                  }
                  final escala =
                      MediaQuery.textScalerOf(context).scale(16) / 16;
                  final tieneAviso =
                      _invalidos.isNotEmpty || venta.mensajeError != null;
                  // Reserva espacio para leer al menos una tarjeta. Con teclado,
                  // paisaje o texto grande todo comparte el mismo desplazamiento.
                  final resumenFijo =
                      constraints.maxHeight >=
                      240 + 140 * escala + (tieneAviso ? 120 * escala : 0);
                  return TransicionVenta(
                    key: const ValueKey('contenido-venta'),
                    desplazar: true,
                    alignment: Alignment.topCenter,
                    child: Column(
                      key: const ValueKey('con-productos'),
                      children: [
                        Expanded(
                          child: _ventaActual(
                            venta,
                            incluirResumen: !resumenFijo,
                          ),
                        ),
                        if (resumenFijo) _resumen(venta),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ventaActual(VentaState venta, {required bool incluirResumen}) {
    final seleccion = venta.detalles;
    final unidades = seleccion.fold<int>(0, (suma, d) => suma + d.cantidad);
    final tema = Theme.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venta actual',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${seleccion.length} ${seleccion.length == 1 ? 'producto' : 'productos'} · '
                '$unidades ${unidades == 1 ? 'unidad' : 'unidades'}',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: venta.guardando
                    ? null
                    : () => ref
                          .read(tabProvider.notifier)
                          .seleccionar(Pestana.catalogo),
                icon: const Icon(Icons.add),
                label: const Text('Agregar más'),
              ),
            ],
          ),
        ),
        for (final detalle in seleccion)
          _FilaDetalle(
            key: ValueKey(detalle.producto.id),
            detalle: detalle,
            habilitado: !venta.guardando,
            onCantidad: (c) => _establecerCantidad(detalle.producto.id, c),
            onInvalida: () => _marcarInvalido(detalle.producto.id),
            onEliminar: () => _eliminar(detalle.producto.id),
          ),
        if (incluirResumen)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _resumen(venta),
          ),
      ],
    );
  }

  Widget _resumen(VentaState venta) {
    final puedeConfirmar =
        venta.detalles.isNotEmpty && _invalidos.isEmpty && !venta.guardando;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Semantics(
                    liveRegion: true,
                    child: TransicionVenta(
                      child: Text(
                        formatearQuetzales(venta.total),
                        key: ValueKey(venta.total),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_invalidos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Revisa la cantidad de ${_invalidos.length} '
                    '${_invalidos.length == 1 ? 'producto' : 'productos'} para continuar. '
                    'El total conserva las últimas cantidades válidas.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            if (venta.estado == EstadoRegistroVenta.error &&
                venta.mensajeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  venta.mensajeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: puedeConfirmar ? _confirmar : null,
                child: venta.guardando
                    ? const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          Text('Registrando venta…'),
                        ],
                      )
                    : Text(
                        venta.estado == EstadoRegistroVenta.error
                            ? 'Reintentar registro'
                            : 'Confirmar venta',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de un producto en la venta actual: cantidad editable (con +/-),
/// subtotal y boton para eliminar.
class _FilaDetalle extends StatefulWidget {
  final DetalleVenta detalle;
  final bool habilitado;
  final ValueChanged<int> onCantidad;
  final VoidCallback onInvalida;
  final VoidCallback onEliminar;

  const _FilaDetalle({
    super.key,
    required this.detalle,
    required this.habilitado,
    required this.onCantidad,
    required this.onInvalida,
    required this.onEliminar,
  });

  @override
  State<_FilaDetalle> createState() => _FilaDetalleState();
}

class _FilaDetalleState extends State<_FilaDetalle>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller;
  String? _error;

  @override
  bool get wantKeepAlive => _error != null;

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
      updateKeepAlive();
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
    updateKeepAlive();
    if (error == null) {
      widget.onCantidad(int.parse(texto.trim()));
    } else {
      widget.onInvalida();
    }
  }

  void _fijar(int cantidad) {
    _controller.text = '$cantidad';
    setState(() => _error = null);
    updateKeepAlive();
    widget.onCantidad(cantidad);
  }

  Widget _controlCantidad(
    String etiqueta,
    IconData icono,
    VoidCallback? onPressed,
  ) {
    return Tooltip(
      message: etiqueta,
      excludeFromSemantics: true,
      child: IconButton(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(icono, semanticLabel: etiqueta),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final detalle = widget.detalle;
    final cantidad = detalle.cantidad;

    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detalle.producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatearQuetzales(detalle.precioAlMomento)} por unidad',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _controlCantidad(
                  'Reducir cantidad de ${detalle.producto.nombre}',
                  Icons.remove_circle_outline,
                  widget.habilitado && cantidad > 1
                      ? () => _fijar(cantidad - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label: 'Cantidad de ${detalle.producto.nombre}',
                    child: TextField(
                      controller: _controller,
                      enabled: widget.habilitado,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        errorText: _error,
                        errorMaxLines: 4,
                      ),
                      onChanged: _alEscribir,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _controlCantidad(
                  'Aumentar cantidad de ${detalle.producto.nombre}',
                  Icons.add_circle_outline,
                  widget.habilitado ? () => _fijar(cantidad + 1) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 16,
                overflowSpacing: 8,
                children: [
                  TransicionVenta(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Subtotal: ${formatearQuetzales(subtotalDe(detalle))}',
                      key: ValueKey(subtotalDe(detalle)),
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.habilitado ? widget.onEliminar : null,
                    style: TextButton.styleFrom(
                      foregroundColor: colores.error,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Semantics(
                      label: 'Quitar ${detalle.producto.nombre} de la venta',
                      excludeSemantics: true,
                      child: const Text('Quitar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de la venta sin productos: invita a agregarlos desde el catalogo.
class _VentaVacia extends ConsumerWidget {
  const _VentaVacia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProductosProvider);

    Future<void> agregarProducto() async {
      final guardado = await Navigator.of(
        context,
      ).pushNamed(AppRoutes.agregarProducto);
      if (context.mounted && guardado == true) {
        ref.invalidate(catalogoProductosProvider);
      }
    }

    return catalogo.when(
      skipLoadingOnReload: false,
      loading: () => const _MensajeVentaVacia(
        titulo: 'Consultando productos…',
        descripcion: 'Estamos preparando el catálogo para tu venta.',
        cargando: true,
      ),
      error: (_, _) => _MensajeVentaVacia(
        titulo: 'No se pudo consultar el catálogo',
        descripcion: 'Vuelve a intentarlo para elegir productos para tu venta.',
        accion: 'Reintentar',
        onAccion: () => ref.invalidate(catalogoProductosProvider),
      ),
      data: (productos) => productos.isEmpty
          ? _MensajeVentaVacia(
              titulo: 'Primero agrega un producto',
              descripcion:
                  'Tu catálogo no tiene productos activos. Agrega uno para empezar a vender.',
              accion: 'Agregar primer producto',
              onAccion: agregarProducto,
            )
          : _MensajeVentaVacia(
              titulo: 'Empieza una nueva venta',
              descripcion:
                  'Selecciona productos del catálogo para agregarlos aquí.',
              accion: 'Elegir productos',
              onAccion: () =>
                  ref.read(tabProvider.notifier).seleccionar(Pestana.catalogo),
            ),
    );
  }
}

class _MensajeVentaVacia extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String? accion;
  final VoidCallback? onAccion;
  final bool cargando;

  const _MensajeVentaVacia({
    required this.titulo,
    required this.descripcion,
    this.accion,
    this.onAccion,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cargando)
                    const CircularProgressIndicator()
                  else
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (accion != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onAccion,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(accion!, textAlign: TextAlign.center),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
