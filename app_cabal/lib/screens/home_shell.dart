import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tab_provider.dart';
import '../providers/ventas_registradas_provider.dart';
import 'catalogo_screen.dart';
import 'proximamente_screen.dart';
import 'registrar_venta_screen.dart';
import 'ventas_registradas_screen.dart';

/// Contenedor principal con la barra de navegacion inferior. Las pestanas
/// viven en un IndexedStack para que cada una conserve su estado (por
/// ejemplo el scroll) al cambiar de una a otra.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(tabProvider);

    // Las pestanas siguen montadas aunque no se vean, asi que las ventas se
    // vuelven a leer al entrar a ella (ej. una venta recien registrada).
    ref.listen(tabProvider, (_, nueva) {
      if (nueva == Pestana.ventas) {
        ref.invalidate(ventasRegistradasProvider);
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: actual.index,
        children: const [
          CatalogoScreen(),
          RegistrarVentaScreen(),
          VentasRegistradasScreen(),
          ProximamenteScreen(titulo: 'Cierre del día'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: actual.index,
        onDestinationSelected: (indice) =>
            ref.read(tabProvider.notifier).seleccionar(Pestana.values[indice]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Vender',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Cierre',
          ),
        ],
      ),
    );
  }
}
