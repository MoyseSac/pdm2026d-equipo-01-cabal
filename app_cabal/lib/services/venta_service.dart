import 'package:sqflite/sqflite.dart';

import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import 'database_service.dart';

class VentaService {
  final DatabaseService _databaseService;

  VentaService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  Future<void> registrarVenta(Venta venta) async {
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      await txn.insert(
        'venta',
        {
          'id': venta.id,
          'fecha_hora': venta.fechaHora.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final detalle in venta.detalles) {
        await txn.insert(
          'detalle_venta',
          {
            'venta_id': venta.id,
            'producto_id': detalle.producto.id,
            'cantidad': detalle.cantidad,
            'precio_al_momento': detalle.precioAlMomento,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<Venta?> obtenerVenta(String id) async {
    final db = await _databaseService.database;

    final ventas = await db.query(
      'venta',
      where: 'id = ?',
      whereArgs: [id],
    );

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
            nombre: producto['nombre'] as String,
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
