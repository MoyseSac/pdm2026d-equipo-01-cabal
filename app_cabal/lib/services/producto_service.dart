import 'package:sqflite/sqflite.dart';

import '../models/producto.dart';
import 'database_service.dart';

/// Ya hay otro producto del catalogo con ese nombre.
class NombreRepetidoException implements Exception {
  const NombreRepetidoException();

  @override
  String toString() => 'Ya tienes un producto con ese nombre.';
}

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

    await _sinNombreRepetido(
      () => db.insert(
        'producto',
        _toMap(producto),
        conflictAlgorithm: ConflictAlgorithm.abort,
      ),
    );
  }

  /// Convierte el error UNIQUE de SQLite en uno que el tendero entienda.
  Future<T> _sinNombreRepetido<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw const NombreRepetidoException();
      rethrow;
    }
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await _databaseService.database;

    final resultado = await db.query(
      'producto',
      where: 'eliminado_en IS NULL AND archivado_en IS NULL',
      orderBy: 'nombre ASC',
    );

    return resultado.map(_fromMap).toList();
  }

  Future<List<Producto>> obtenerArchivados() async {
    final db = await _databaseService.database;

    final resultado = await db.query(
      'producto',
      where: 'eliminado_en IS NULL AND archivado_en IS NOT NULL',
      orderBy: 'nombre ASC',
    );

    return resultado.map(_fromMap).toList();
  }

  /// En cuantas ventas aparece el producto. Si es mayor que 0 no se borra.
  Future<int> ventasDeProducto(String productoId) async {
    final db = await _databaseService.database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM detalle_venta WHERE producto_id = ?',
      [productoId],
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> archivarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.update(
      'producto',
      {'archivado_en': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<void> desarchivarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await db.update(
      'producto',
      {'archivado_en': null},
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<void> actualizarProducto(Producto producto) async {
    final db = await _databaseService.database;

    await _sinNombreRepetido(
      () => db.update(
        'producto',
        _toMap(producto),
        where: 'id = ?',
        whereArgs: [producto.id],
      ),
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

    await _sinNombreRepetido(
      () => db.update(
        'producto',
        {'eliminado_en': null},
        where: 'id = ?',
        whereArgs: [producto.id],
      ),
    );
  }
}
