import 'package:flutter/material.dart';

class IconoProducto {
  const IconoProducto(this.etiqueta, this.asset, this.color);

  final String etiqueta;
  final String asset;
  final Color color;
}

/// Las claves se guardan en la base; cambiar el dibujo no cambia la categoria.
/// PNG de Icons8 Color, incluidos localmente para usarlos sin conexion.
const Map<String, IconoProducto> iconosProducto = {
  'bebida': IconoProducto(
    'Bebida',
    'assets/icons/productos/bebida.png',
    Color(0xFF1976D2),
  ),
  'licor': IconoProducto(
    'Licor',
    'assets/icons/productos/licor.png',
    Color(0xFF8E44AD),
  ),
  'golosinas': IconoProducto(
    'Golosinas',
    'assets/icons/productos/golosinas.png',
    Color(0xFFDB477B),
  ),
  'helados': IconoProducto(
    'Helados',
    'assets/icons/productos/helados.png',
    Color(0xFFE87732),
  ),
  'pan': IconoProducto(
    'Pan',
    'assets/icons/productos/pan.png',
    Color(0xFFBA7835),
  ),
  'lacteos': IconoProducto(
    'Lácteos y huevos',
    'assets/icons/productos/lacteos.png',
    Color(0xFF4188BD),
  ),
  'embutidos': IconoProducto(
    'Embutidos',
    'assets/icons/productos/embutidos.png',
    Color(0xFFC55353),
  ),
  'frutas_verduras': IconoProducto(
    'Frutas y verduras',
    'assets/icons/productos/frutas_verduras.png',
    Color(0xFF40934A),
  ),
  'abarrotes': IconoProducto(
    'Abarrotes',
    'assets/icons/productos/abarrotes.png',
    Color(0xFFB58730),
  ),
  'limpieza': IconoProducto(
    'Limpieza',
    'assets/icons/productos/limpieza.png',
    Color(0xFF299B9B),
  ),
  'higiene': IconoProducto(
    'Higiene',
    'assets/icons/productos/higiene.png',
    Color(0xFF498CC2),
  ),
  'medicinas': IconoProducto(
    'Medicinas',
    'assets/icons/productos/medicinas.png',
    Color(0xFF9C63B5),
  ),
  'bebe': IconoProducto(
    'Bebé',
    'assets/icons/productos/bebe.png',
    Color(0xFFDE8754),
  ),
  'mascotas': IconoProducto(
    'Mascotas',
    'assets/icons/productos/mascotas.png',
    Color(0xFFB98246),
  ),
  'papeleria': IconoProducto(
    'Papelería',
    'assets/icons/productos/papeleria.png',
    Color(0xFF577DC6),
  ),
};

const IconData iconoProductoGenerico = Icons.inventory_2_outlined;
