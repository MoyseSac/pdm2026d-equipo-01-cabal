/// Nombres de ruta centralizados. Solo constantes, sin depender de
/// Flutter ni de las pantallas, para que este archivo pueda vivir junto
/// al resto de constants/ sin generar dependencias circulares. Quien
/// conecta estos nombres con los widgets de pantalla es app.dart.
class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String catalogo = '/catalogo';
  static const String agregarProducto = '/agregar-producto';
  static const String registrarVenta = '/registrar-venta';
  static const String confirmacionVenta = '/confirmacion-venta';
  static const String cierreDia = '/cierre-dia';
}