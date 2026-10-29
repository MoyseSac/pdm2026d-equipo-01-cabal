import 'package:flutter/material.dart';

class IconoProducto {
  const IconoProducto(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}

/// Iconos de categoria que se pueden asignar a un producto. La clave es lo
/// que se guarda en la base, asi que no se debe renombrar una existente.
const Map<String, IconoProducto> iconosProducto = {
  'bebida': IconoProducto('Bebida', Icons.local_drink),
  'licor': IconoProducto('Licor', Icons.liquor),
  'golosinas': IconoProducto('Golosinas', Icons.cookie),
  'helados': IconoProducto('Helados', Icons.icecream),
  'pan': IconoProducto('Pan', Icons.bakery_dining),
  'lacteos': IconoProducto('Lácteos y huevos', Icons.egg_alt),
  'embutidos': IconoProducto('Embutidos', Icons.restaurant),
  'frutas_verduras': IconoProducto('Frutas y verduras', Icons.eco),
  'abarrotes': IconoProducto('Abarrotes', Icons.shopping_basket),
  'limpieza': IconoProducto('Limpieza', Icons.cleaning_services),
  'higiene': IconoProducto('Higiene', Icons.soap),
  'medicinas': IconoProducto('Medicinas', Icons.medication),
  'bebe': IconoProducto('Bebé', Icons.child_friendly),
  'mascotas': IconoProducto('Mascotas', Icons.pets),
  'papeleria': IconoProducto('Papelería', Icons.menu_book),
};

const IconData iconoProductoGenerico = Icons.inventory_2_outlined;
