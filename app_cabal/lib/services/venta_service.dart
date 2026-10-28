import 'package:sqflite/sqflite.dart';

import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import 'database_service.dart';

class VentaService {
  final DatabaseService _databaseService;

  VentaService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  /// Registra una venta junto con todos sus detalles.
  /// Se utiliza una transaccion para evitar registros incompletos.
  Future<void> registrarVenta(Venta venta) async {
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      await txn.insert('venta', {
        'id': venta.id,
        'fecha_hora': venta.fechaHora.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      for (final detalle in venta.detalles) {
        await txn.insert('detalle_venta', {
          'venta_id': venta.id,
          'producto_id': detalle.producto.id,
          'nombre_producto': detalle.producto.nombre,
          'cantidad': detalle.cantidad,
          'precio_al_momento': detalle.precioAlMomento,
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }

  /// Obtiene las ventas registradas.
  ///
  /// Si no se recibe un rango, devuelve todas las ventas.
  /// Si existe un rango, consulta únicamente las ventas
  /// comprendidas entre [desde] (inclusivo) y
  /// [hastaExclusivo] (exclusivo).
  ///
  /// Las fechas se almacenan como texto ISO 8601.
  Future<List<Venta>> obtenerVentas({
    DateTime? desde,
    DateTime? hastaExclusivo,
  }) async {
    final db = await _databaseService.database;

    final condiciones = <String>[];
    final argumentos = <Object?>[];

    if (desde != null) {
      condiciones.add('fecha_hora >= ?');
      argumentos.add(desde.toIso8601String());
    }

    if (hastaExclusivo != null) {
      condiciones.add('fecha_hora < ?');
      argumentos.add(hastaExclusivo.toIso8601String());
    }

    final where = condiciones.isEmpty ? null : condiciones.join(' AND ');

    // Filtra las ventas directamente en SQLite.
    final filasVenta = await db.query(
      'venta',
      where: where,
      whereArgs: argumentos.isEmpty ? null : argumentos,
      orderBy: 'fecha_hora DESC, id DESC',
    );

    if (filasVenta.isEmpty) {
      return [];
    }

    // Filtra también los detalles mediante la fecha
    // de su venta correspondiente.
    final condicionesDetalle = <String>[];

    if (desde != null) {
      condicionesDetalle.add('v.fecha_hora >= ?');
    }

    if (hastaExclusivo != null) {
      condicionesDetalle.add('v.fecha_hora < ?');
    }

    final whereDetalle = condicionesDetalle.isEmpty
        ? ''
        : 'WHERE ${condicionesDetalle.join(' AND ')}';

    final filasDetalle = await db.rawQuery('''
      SELECT
        d.venta_id,
        d.cantidad,
        d.precio_al_momento,
        p.id AS producto_id,
        COALESCE(d.nombre_producto, p.nombre) AS nombre,
        p.precio
      FROM detalle_venta d
      JOIN venta v ON v.id = d.venta_id
      JOIN producto p ON p.id = d.producto_id
      $whereDetalle
      ORDER BY nombre ASC
      ''', argumentos);

    // Agrupa los detalles según el identificador de la venta.
    final detallesPorVenta = <String, List<DetalleVenta>>{};

    for (final fila in filasDetalle) {
      final ventaId = fila['venta_id'] as String;

      detallesPorVenta
          .putIfAbsent(ventaId, () => [])
          .add(
            DetalleVenta(
              producto: Producto(
                id: fila['producto_id'] as String,
                nombre: fila['nombre'] as String,
                precio: (fila['precio'] as num).toDouble(),
              ),
              cantidad: fila['cantidad'] as int,
              precioAlMomento: (fila['precio_al_momento'] as num).toDouble(),
            ),
          );
    }

    // Construye los objetos Venta completos.
    return filasVenta.map((fila) {
      final id = fila['id'] as String;

      return Venta(
        id: id,
        fechaHora: DateTime.parse(fila['fecha_hora'] as String),
        detalles: detallesPorVenta[id] ?? [],
      );
    }).toList();
  }

  /// Obtiene una venta específica por su identificador.
  /// Conserva la lógica original del proyecto.
  Future<Venta?> obtenerVenta(String id) async {
    final db = await _databaseService.database;

    final ventas = await db.query('venta', where: 'id = ?', whereArgs: [id]);

    if (ventas.isEmpty) {
      return null;
    }

    final filasDetalle = await db.query(
      'detalle_venta',
      where: 'venta_id = ?',
      whereArgs: [id],
    );

    final detalles = <DetalleVenta>[];

    for (final fila in filasDetalle) {
      final productos = await db.query(
        'producto',
        where: 'id = ?',
        whereArgs: [fila['producto_id']],
      );

      final producto = productos.first;

      detalles.add(
        DetalleVenta(
          producto: Producto(
            id: producto['id'] as String,
            nombre: (fila['nombre_producto'] ?? producto['nombre']) as String,
            precio: (producto['precio'] as num).toDouble(),
          ),
          cantidad: fila['cantidad'] as int,
          precioAlMomento: (fila['precio_al_momento'] as num).toDouble(),
        ),
      );
    }

    return Venta(
      id: ventas.first['id'] as String,
      fechaHora: DateTime.parse(ventas.first['fecha_hora'] as String),
      detalles: detalles,
    );
  }
}
