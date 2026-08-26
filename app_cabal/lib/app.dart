import 'package:flutter/material.dart';

import 'constants/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/agregar_producto_screen.dart';
import 'screens/registrar_venta_screen.dart';
import 'screens/confirmacion_venta_screen.dart';
import 'screens/cierre_dia_screen.dart';

/// Configuracion principal de la app: tema, pantalla inicial y rutas.
/// El mapa de rutas vive aqui (no en constants/) porque necesita conocer
/// los widgets de pantalla; constants/app_routes.dart solo aporta los
/// nombres para que el resto del codigo no use strings sueltos.
class CabalApp extends StatelessWidget {
  const CabalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabal',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.catalogo: (context) => const CatalogoScreen(),
        AppRoutes.agregarProducto: (context) =>
            const AgregarProductoScreen(),
        AppRoutes.registrarVenta: (context) => const RegistrarVentaScreen(),
        AppRoutes.confirmacionVenta: (context) =>
            const ConfirmacionVentaScreen(),
        AppRoutes.cierreDia: (context) => const CierreDiaScreen(),
      },
      // No se necesita configuracion extra para el boton de retroceso:
      // Navigator maneja el stack automaticamente y el sistema (Android)
      // ya dispara pop() sobre la ruta actual por defecto.
    );
  }
}