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
    };
  }

  Producto _fromMap(Map<String, Object?> map) {
    return Producto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
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

    await db.delete(
      'producto',
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }
}