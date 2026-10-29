import 'package:sqflite/sqflite.dart';

import '../models/producto.dart';
import 'database_service.dart';

class ProductoService {
  final DatabaseService _databaseService;

  ProductoService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  Map<String, Object?> _toMap(Producto producto) {
    return {
      'id': producto.id,
      'nombre': producto.nombre,
      'precio': producto.precio,
      'imagen': producto.imagen,
      'icono': producto.icono,
    };
  }

  Producto _fromMap(Map<String, Object?> map) {
    return Producto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      imagen: map['imagen'] as String?,
      icono: map['icono'] as String?,
    );
  }

  Future<void> crearProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.insert(
      'producto',
      _toMap(producto),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await _databaseService.database;

    final resultado = await db.query(
      'producto',
      where: 'eliminado_en IS NULL',
      orderBy: 'nombre ASC',
    );

    return resultado.map(_fromMap).toList();
  }

  Future<void> actualizarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.update(
      'producto',
      _toMap(producto),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<void> eliminarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.update(
      'producto',
      {'eliminado_en': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  /// Deshace un borrado: el producto vuelve al catalogo con el mismo id,
  /// nombre y precio, sin tocar las ventas que lo mencionan.
  Future<void> restaurarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.update(
      'producto',
      {'eliminado_en': null},
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }
}
