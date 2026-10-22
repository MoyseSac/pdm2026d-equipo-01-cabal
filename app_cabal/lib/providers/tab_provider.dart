import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Destinos de la barra de navegacion inferior, en el orden en que se
/// muestran.
enum Pestana { catalogo, vender, ventas, cierre }

/// Pestana activa. Vive en un provider para poder cambiarla desde
/// cualquier pantalla (por ejemplo "Ver ventas" tras confirmar una venta)
/// sin pasar funciones por constructores.
final tabProvider = NotifierProvider<TabNotifier, Pestana>(TabNotifier.new);

class TabNotifier extends Notifier<Pestana> {
  @override
  Pestana build() => Pestana.catalogo;

  void seleccionar(Pestana pestana) => state = pestana;
}
