import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../models/producto.dart';
import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import '../utils/avisos.dart';
import '../utils/busqueda.dart';
import '../widgets/cantidad_producto_sheet.dart';
import '../widgets/catalogo_vacio_widget.dart';
import '../widgets/producto_imagen_widget.dart';
import '../widgets/fila_catalogo_animada.dart';
import 'archivados_screen.dart';
import 'acerca_de_screen.dart';

enum _AccionProducto { editar, eliminar }

// FAB de 56, margen inferior de 16 y separacion de 16 sobre el boton.
const _espacioInferiorCatalogo = 88.0;

class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  /// Productos ya borrados que aun pueden venir en la lista cargada. Un
  /// Dismissible descartado debe salir del arbol de inmediato, asi que la
  /// fila se oculta aqui sin esperar a que se vuelva a leer la base.
  final Set<String> _ocultos = {};
  Set<String>? _idsAnteriores;
  final Set<String> _entradasPendientes = {};
  final Map<String, GlobalKey<FilaCatalogoAnimadaState>> _clavesFilas = {};

  final _busquedaController = TextEditingController();
  final _scrollController = ScrollController();
  String _consulta = '';

  void _buscar(String texto) {
    setState(() => _consulta = texto);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    _buscar('');
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Borra el producto en la base ANTES de que la fila desaparezca. Si falla,
  /// devuelve false: la fila vuelve a su lugar y se avisa del error.
  Future<bool> _borrar(Producto producto) async {
    try {
      final servicio = ref.read(productoServiceProvider);
      final ventas = await servicio.ventasDeProducto(producto.id);
      if (ventas > 0) {
        // En uso: no se borra. La fila vuelve a su lugar y se ofrece archivar.
        if (mounted) await _ofrecerArchivar(producto, ventas);
        return false;
      }
      await servicio.eliminarProducto(producto);
      return true;
    } catch (_) {
      if (mounted) {
        mostrarAvisoTemporal(
          context,
          contenido: const Text(
            'No se pudo eliminar el producto. Intenta de nuevo.',
          ),
          error: true,
          margenInferior: _espacioInferiorCatalogo,
        );
      }
      return false;
    }
  }

  Future<void> _ofrecerArchivar(Producto producto, int ventas) async {
    limpiarAvisosTemporales(context);
    final archivar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se puede borrar'),
        content: Text(
          '${producto.nombre} aparece en $ventas '
          '${ventas == 1 ? 'venta' : 'ventas'}. '
          'Archívalo para dejar de verlo sin perder tu historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (archivar != true || !mounted) return;

    await ref.read(productoServiceProvider).archivarProducto(producto);
    ref.invalidate(catalogoProductosProvider);
  }

  /// La fila ya salio de la pantalla: se oculta y se ofrece deshacer.
  void _alDescartar(Producto producto) {
    setState(() => _ocultos.add(producto.id));
    ref.invalidate(catalogoProductosProvider);

    mostrarAvisoTemporal(
      context,
      contenido: const Text('Producto eliminado'),
      accion: SnackBarAction(
        label: 'Deshacer',
        onPressed: () => _restaurar(producto),
      ),
      margenInferior: _espacioInferiorCatalogo,
    );
  }

  Future<void> _restaurar(Producto producto) async {
    try {
      await ref.read(productoServiceProvider).restaurarProducto(producto);
    } catch (_) {
      if (mounted) {
        mostrarAvisoTemporal(
          context,
          contenido: const Text(
            'No se pudo restaurar el producto. Intenta de nuevo.',
          ),
          error: true,
          margenInferior: _espacioInferiorCatalogo,
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _ocultos.remove(producto.id));
    ref.invalidate(catalogoProductosProvider);
  }

  /// Pide la cantidad en una hoja y agrega el producto a la venta en curso
  /// sin salir del catalogo. La hoja y el contador confirman el cambio.
  Future<void> _agregarALaVenta(Producto producto) async {
    FocusScope.of(context).unfocus();
    limpiarAvisosTemporales(context);
    final yaEnVenta = ref
        .read(ventaProvider)
        .detalles
        .where((d) => d.producto.id == producto.id)
        .fold<int>(0, (suma, d) => suma + d.cantidad);

    final cantidad = await mostrarCantidadProducto(
      context,
      producto,
      yaEnVenta: yaEnVenta,
    );
    if (cantidad == null || !mounted) return;

    if (!ref.read(ventaProvider.notifier).agregarProducto(producto, cantidad)) {
      return;
    }
  }

  /// Abre el formulario con el producto. Se invalida siempre al volver porque
  /// el catalogo lee el servicio directo y no se entera de la edicion solo.
  Future<void> _editarProducto(Producto producto) async {
    limpiarAvisosTemporales(context);
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.editarProducto, arguments: producto);

    if (!mounted) return;

    ref.invalidate(catalogoProductosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(catalogoProductosProvider);
    final colores = Theme.of(context).colorScheme;
    final activos = catalogo.valueOrNull
        ?.where((producto) => !_ocultos.contains(producto.id))
        .toList();
    final mostrarVacio = catalogo.when(
      skipLoadingOnReload: catalogo.hasValue,
      loading: () => false,
      error: (_, _) => false,
      data: (_) => activos!.isEmpty,
    );

    Future<void> abrirAgregarProducto() async {
      limpiarAvisosTemporales(context);
      await Navigator.of(context).pushNamed(AppRoutes.agregarProducto);

      if (!context.mounted) return;

      // Actualiza el catálogo al regresar del formulario.
      ref.invalidate(catalogoProductosProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Acerca de Cabal',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              limpiarAvisosTemporales(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AcercaDeScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Archivados',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              limpiarAvisosTemporales(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ArchivadosScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Manejo de los cuatro estados del catálogo.
      body: catalogo.when(
        // Al volver a leer con datos ya cargados (borrar o deshacer) no se
        // reemplaza la lista por el indicador de carga.
        skipLoadingOnReload: catalogo.hasValue,

        // ESTADO 1: CARGANDO
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando productos...'),
            ],
          ),
        ),

        // ESTADO 2: ERROR
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron cargar los productos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(catalogoProductosProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),

        // ESTADOS 3 Y 4: VACÍO O DATOS
        data: (lista) {
          final ids = activos!.map((p) => p.id).toSet();
          if (_idsAnteriores != null) {
            _entradasPendientes.addAll(ids.difference(_idsAnteriores!));
          }
          _idsAnteriores = ids;
          _clavesFilas.removeWhere(
            (id, clave) => !ids.contains(id) && clave.currentState == null,
          );

          // También es el estado vacío cuando se borran todos los productos.
          if (mostrarVacio) {
            return CatalogoVacioWidget(onAgregarProducto: abrirAgregarProducto);
          }

          final consulta = normalizarBusqueda(_consulta);
          final productos = activos
              .where(
                (producto) =>
                    normalizarBusqueda(producto.nombre).contains(consulta),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _busquedaController,
                  onChanged: _buscar,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto',
                    constraints: const BoxConstraints(minHeight: 56),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colores.surfaceContainer,
                    hintStyle: TextStyle(color: colores.onSurfaceVariant),
                    prefixIconColor: colores.onSurfaceVariant,
                    suffixIconColor: colores.onSurfaceVariant,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _consulta.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.close),
                            onPressed: _limpiarBusqueda,
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colores.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colores.primary, width: 2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: productos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No encontramos productos con «${_consulta.trim()}»',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _limpiarBusqueda,
                                child: const Text('Limpiar búsqueda'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          _espacioInferiorCatalogo,
                        ),
                        itemCount: productos.length,
                        findChildIndexCallback: (key) {
                          final indice = productos.indexWhere(
                            (p) => _clavesFilas[p.id] == key,
                          );
                          return indice < 0 ? null : indice;
                        },
                        itemBuilder: (context, index) {
                          final producto = productos[index];

                          // La key es el id del producto, nunca el indice: al borrar una
                          // fila las demas conservan su estado en lugar de heredar el de
                          // la fila anterior.
                          final claveFila = _clavesFilas.putIfAbsent(
                            producto.id,
                            () => GlobalKey<FilaCatalogoAnimadaState>(),
                          );
                          return FilaCatalogoAnimada(
                            key: claveFila,
                            animarEntrada: _entradasPendientes.remove(
                              producto.id,
                            ),
                            child: Dismissible(
                              key: ValueKey(producto.id),
                              movementDuration:
                                  MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              resizeDuration:
                                  MediaQuery.disableAnimationsOf(context)
                                  ? null
                                  : const Duration(milliseconds: 220),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _borrar(producto),
                              onDismissed: (_) => _alDescartar(producto),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  onTap: () => _agregarALaVenta(producto),
                                  // Atajo para quien lo descubra; el icono es la via visible.
                                  onLongPress: () => _editarProducto(producto),
                                  leading: ProductoImagenWidget(
                                    imagen: producto.imagenProducto,
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    4,
                                    8,
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      formatearQuetzales(producto.precio),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton.filledTonal(
                                        tooltip: 'Agregar a la venta',
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        onPressed: () =>
                                            _agregarALaVenta(producto),
                                        icon: const Icon(Icons.add),
                                      ),
                                      PopupMenuButton<_AccionProducto>(
                                        tooltip: 'Opciones de producto',
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (accion) async {
                                          switch (accion) {
                                            case _AccionProducto.editar:
                                              await _editarProducto(producto);
                                            case _AccionProducto.eliminar:
                                              if (await _borrar(producto) &&
                                                  mounted) {
                                                await claveFila.currentState
                                                    ?.retirar();
                                                if (mounted) {
                                                  _alDescartar(producto);
                                                }
                                              }
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: _AccionProducto.editar,
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.edit_outlined,
                                              ),
                                              title: Text('Editar producto'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: _AccionProducto.eliminar,
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.delete_outline,
                                              ),
                                              title: Text('Eliminar producto'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: mostrarVacio
          ? null
          : FloatingActionButton.extended(
              heroTag: 'agregar',
              onPressed: abrirAgregarProducto,
              label: const Text('Agregar producto'),
              icon: const Icon(Icons.add),
            ),
    );
  }
}
