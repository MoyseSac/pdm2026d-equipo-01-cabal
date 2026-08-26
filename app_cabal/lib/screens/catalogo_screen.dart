import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../widgets/catalogo_vacio_widget.dart';

/// Pantalla de catalogo / home. Contenido real pendiente (lista de
/// productos) — este issue solo cubre que se pueda llegar y regresar de
/// aqui hacia el resto del flujo principal.
///
/// TODO(contenido-catalogo): reemplazar `_hayProductos` por el estado real
/// una vez exista la fuente de datos de productos.
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  static const bool _hayProductos = false; // placeholder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo')),
      body: _hayProductos
          ? _buildListaProductos(context)
          : CatalogoVacioWidget(
              onAgregarProducto: () => Navigator.of(context)
                  .pushNamed(AppRoutes.agregarProducto),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'cierre',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.cierreDia),
            label: const Text('Cierre del dia'),
            icon: const Icon(Icons.summarize_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos(BuildContext context) {
    // Placeholder de lista con un solo item de ejemplo para poder probar
    // la navegacion hacia "Registrar venta".
    return ListView(
      children: [
        ListTile(
          title: const Text('Producto de ejemplo (placeholder)'),
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.registrarVenta),
        ),
      ],
    );
  }
}