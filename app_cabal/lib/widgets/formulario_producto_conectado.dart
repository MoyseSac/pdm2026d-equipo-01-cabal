import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';
import '../screens/agregar_producto_screen.dart';

/// Conecta el formulario con el servicio: es el unico que conoce providers.
/// Despues de guardar invalida la lista en vez de modificarla a mano.
class FormularioProductoConectado extends ConsumerWidget {
  const FormularioProductoConectado({super.key, this.producto});

  final Producto? producto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AgregarProductoScreen(
      producto: producto,
      onGuardar: (guardado) async {
        final servicio = ref.read(productoServiceProvider);
        if (producto == null) {
          await servicio.crearProducto(guardado);
        } else {
          await servicio.actualizarProducto(guardado);
        }
        ref.invalidate(catalogoProductosProvider);
      },
    );
  }
}
