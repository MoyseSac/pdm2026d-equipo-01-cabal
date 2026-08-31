import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../widgets/catalogo_vacio_widget.dart';

/// Pantalla de catalogo / home. Contenido real pendiente (lista de
/// productos) — este issue solo cubre que se pueda llegar y regresar de
/// aqui hacia el resto del flujo principal.
///
/// Nota: como todavia no existe una fuente de datos real de productos,
/// se muestra siempre el estado de catalogo vacio (comportamiento real
/// esperado en un catalogo sin productos) junto con un acceso de prueba
/// a "Registrar venta", para que ese tramo del flujo principal se pueda
/// navegar y verificar aunque el contenido real no exista todavia.
///
/// TODO(contenido-catalogo): reemplazar este acceso de prueba por la
/// lista real de productos una vez exista la fuente de datos.
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo')),
      body: Column(
        children: [
          Expanded(
            child: CatalogoVacioWidget(
              onAgregarProducto: () => Navigator.of(context)
                  .pushNamed(AppRoutes.agregarProducto),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              // Acceso de prueba: permite verificar el tramo
              // catalogo -> registrar venta -> confirmacion sin
              // depender de que existan productos reales todavia.
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.registrarVenta),
              child: const Text(
                'Probar registrar venta (placeholder producto)',
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cierre',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cierreDia),
        label: const Text('Cierre del dia'),
        icon: const Icon(Icons.summarize_outlined),
      ),
    );
  }
}