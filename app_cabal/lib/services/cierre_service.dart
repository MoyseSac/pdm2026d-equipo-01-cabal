import 'package:sqflite/sqflite.dart';

import '../models/cierre.dart';
import 'database_service.dart';

/// Se intento cerrar un dia en el que no hubo ventas.
class CierreSinVentasException implements Exception {
  const CierreSinVentasException();

  @override
  String toString() => 'No se puede cerrar un dia sin ventas.';
}

class CierreService {
  final DatabaseService _databaseService;

  CierreService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  /// Calcula el resumen del dia sin guardar nada.
  ///
  /// Toda la suma se hace en SQL con enteros (centavos): sumar `REAL` acumula
  /// errores de representacion (0.1 + 0.2 no es 0.3). Solo al final se pasa
  /// a `double` para mostrar.
  Future<Cierre> calcularDia(DateTime dia) async {
    final db = await _databaseService.database;
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = DateTime(dia.year, dia.month, dia.day + 1);
    final rango = [inicio.toIso8601String(), fin.toIso8601String()];

    final totales = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT v.id) AS numero_ventas,
        COALESCE(SUM(d.cantidad * $_centavosDelDetalle), 0) AS total_centavos
      FROM venta v
      LEFT JOIN detalle_venta d ON d.venta_id = v.id
      WHERE v.fecha_hora >= ? AND v.fecha_hora < ?
      ''', rango);

    // Con MAX() SQLite toma las demas columnas de la fila que tiene el
    // maximo: asi el nombre es el de la venta mas reciente del dia, aunque
    // el producto se haya renombrado entre dos ventas.
    final filas = await db.rawQuery('''
      SELECT
        d.producto_id AS producto_id,
        COALESCE(d.nombre_producto, p.nombre) AS nombre,
        SUM(d.cantidad) AS unidades,
        SUM(d.cantidad * $_centavosDelDetalle) AS subtotal_centavos,
        MAX(v.fecha_hora) AS ultima_venta
      FROM detalle_venta d
      JOIN venta v ON v.id = d.venta_id
      JOIN producto p ON p.id = d.producto_id
      WHERE v.fecha_hora >= ? AND v.fecha_hora < ?
      GROUP BY d.producto_id
      ORDER BY subtotal_centavos DESC, nombre ASC
      ''', rango);

    final productos = [
      for (final f in filas)
        CierreProducto(
          productoId: f['producto_id'] as String,
          nombre: f['nombre'] as String,
          unidades: f['unidades'] as int,
          subtotal: (f['subtotal_centavos'] as int) / 100,
        ),
    ];

    return Cierre(
      dia: inicio,
      numeroVentas: totales.single['numero_ventas'] as int,
      total: (totales.single['total_centavos'] as int) / 100,
      productos: productos,
    );
  }

  /// Guarda el cierre del dia. Si ese dia ya estaba cerrado lo reemplaza, asi
  /// que repetir la operacion siempre deja un solo cierre con la foto mas
  /// reciente.
  ///
  /// El calculo se hace antes de abrir la transaccion: dentro de ella solo se
  /// puede usar `txn`, no `db`.
  Future<Cierre> cerrarDia(DateTime dia, {DateTime? cerradoEn}) async {
    final resumen = await calcularDia(dia);
    if (resumen.numeroVentas == 0) throw const CierreSinVentasException();

    final ahora = cerradoEn ?? DateTime.now();
    final id = ahora.microsecondsSinceEpoch.toString();
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      // Las filas de cierre_producto se borran en cascada.
      await txn.delete(
        'cierre',
        where: 'dia = ?',
        whereArgs: [_claveDia(resumen.dia)],
      );
      await txn.insert('cierre', {
        'id': id,
        'dia': _claveDia(resumen.dia),
        'cerrado_en': ahora.toIso8601String(),
        'numero_ventas': resumen.numeroVentas,
        'total_centavos': _centavos(resumen.total),
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      for (final producto in resumen.productos) {
        await txn.insert('cierre_producto', {
          'cierre_id': id,
          'producto_id': producto.productoId,
          'nombre_producto': producto.nombre,
          'unidades': producto.unidades,
          'subtotal_centavos': _centavos(producto.subtotal),
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });

    return Cierre(
      id: id,
      dia: resumen.dia,
      cerradoEn: ahora,
      numeroVentas: resumen.numeroVentas,
      total: resumen.total,
      productos: resumen.productos,
    );
  }

  /// El cierre guardado de ese dia, o null si no se cerro.
  Future<Cierre?> obtenerCierre(DateTime dia) async {
    final db = await _databaseService.database;

    final cierres = await db.query(
      'cierre',
      where: 'dia = ?',
      whereArgs: [_claveDia(dia)],
    );
    if (cierres.isEmpty) return null;
    final fila = cierres.single;

    final productos = await db.query(
      'cierre_producto',
      where: 'cierre_id = ?',
      whereArgs: [fila['id']],
      orderBy: 'subtotal_centavos DESC, nombre_producto ASC',
    );

    return Cierre(
      id: fila['id'] as String,
      dia: DateTime(dia.year, dia.month, dia.day),
      cerradoEn: DateTime.parse(fila['cerrado_en'] as String),
      numeroVentas: fila['numero_ventas'] as int,
      total: (fila['total_centavos'] as int) / 100,
      productos: [
        for (final p in productos)
          CierreProducto(
            productoId: p['producto_id'] as String,
            nombre: p['nombre_producto'] as String,
            unidades: p['unidades'] as int,
            subtotal: (p['subtotal_centavos'] as int) / 100,
          ),
      ],
    );
  }

  /// Subtotal de un detalle en centavos enteros, calculado en SQL.
  static const _centavosDelDetalle =
      'CAST(ROUND(d.precio_al_momento * 100) AS INTEGER)';

  /// aaaa-mm-dd en hora local: la clave del dia que va en la columna `dia`.
  static String _claveDia(DateTime dia) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dia.year.toString().padLeft(4, '0')}-${dos(dia.month)}-${dos(dia.day)}';
  }

  /// Los montos del modelo ya son multiplos de 0.01; redondear evita que
  /// 10.299999 se guarde como 1029.
  static int _centavos(double monto) => (monto * 100).round();
}
