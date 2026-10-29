import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';
import '../models/producto.dart';
import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/tab_provider.dart';
import '../providers/venta_provider.dart';
import '../utils/moneda.dart';
import '../widgets/cantidad_producto_sheet.dart';
import '../widgets/catalogo_vacio_widget.dart';

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

  /// Borra el producto en la base ANTES de que la fila desaparezca. Si falla,
  /// devuelve false: la fila vuelve a su lugar y se avisa del error.
  Future<bool> _borrar(Producto producto) async {
    try {
      await ref.read(productoProvider.notifier).eliminarProducto(producto);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo eliminar el producto. Intenta de nuevo.',
              ),
            ),
          );
      }
      return false;
    }
  }

  /// La fila ya salio de la pantalla: se oculta y se ofrece deshacer.
  void _alDescartar(Producto producto) {
    setState(() => _ocultos.add(producto.id));
    ref.invalidate(catalogoProductosProvider);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Producto eliminado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restaurar(producto),
          ),
        ),
      );
  }

  Future<void> _restaurar(Producto producto) async {
    try {
      await ref.read(productoProvider.notifier).restaurarProducto(producto);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo restaurar el producto. Intenta de nuevo.',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _ocultos.remove(producto.id));
    ref.invalidate(catalogoProductosProvider);
  }

  /// Pide la cantidad en una hoja y agrega el producto a la venta en curso
  /// sin salir del catalogo. El aviso ofrece ir a la venta si se quiere.
  Future<void> _agregarALaVenta(Producto producto) async {
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$cantidad × ${producto.nombre} agregado a la venta'),
          action: SnackBarAction(
            label: 'Ver venta',
            onPressed: () =>
                ref.read(tabProvider.notifier).seleccionar(Pestana.vender),
          ),
        ),
      );
  }

  /// Abre el formulario con el producto. Se invalida siempre al volver porque
  /// el catalogo lee el servicio directo y no se entera de la edicion solo.
  Future<void> _editarProducto(Producto producto) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.editarProducto, arguments: producto);

    if (!mounted) return;

    ref.invalidate(catalogoProductosProvider);

    if (result == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Producto actualizado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(catalogoProductosProvider);

    Future<void> abrirAgregarProducto() async {
      final result = await Navigator.of(
        context,
      ).pushNamed(AppRoutes.agregarProducto);

      if (!context.mounted) return;

      // Actualiza el catálogo al regresar del formulario.
      ref.invalidate(catalogoProductosProvider);

      if (result == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto agregado')));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),

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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No se pudieron cargar los productos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
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
          final productos = lista
              .where((producto) => !_ocultos.contains(producto.id))
              .toList();

          // También es el estado vacío cuando se borran todos los productos.
          if (productos.isEmpty) {
            return CatalogoVacioWidget(onAgregarProducto: abrirAgregarProducto);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];

              // La key es el id del producto, nunca el indice: al borrar una
              // fila las demas conservan su estado en lugar de heredar el de
              // la fila anterior.
              return Dismissible(
                key: ValueKey(producto.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _borrar(producto),
                onDismissed: (_) => _alDescartar(producto),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  child: ListTile(
                    onTap: () => _agregarALaVenta(producto),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatearQuetzales(producto.precio),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar producto',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarProducto(producto),
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

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agregar',
        onPressed: abrirAgregarProducto,
        label: const Text('Agregar producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
