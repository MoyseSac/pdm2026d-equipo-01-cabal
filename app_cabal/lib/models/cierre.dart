/// Un producto vendido dentro de un cierre: cuanto salio de el ese dia.
class CierreProducto {
  final String productoId;

  /// Nombre copiado al momento del cierre; no cambia si despues se renombra
  /// o se borra el producto.
  final String nombre;
  final int unidades;
  final double subtotal;

  const CierreProducto({
    required this.productoId,
    required this.nombre,
    required this.unidades,
    required this.subtotal,
  });
}

/// Resumen de un dia de ventas. Si [id] y [cerradoEn] son nulos es solo el
/// calculo en vivo; si vienen, es la foto guardada al cerrar el dia.
class Cierre {
  final String? id;

  /// Dia al que pertenece, a la medianoche local.
  final DateTime dia;
  final DateTime? cerradoEn;
  final int numeroVentas;
  final double total;

  /// Productos que se vendieron ese dia, del que mas salio al que menos.
  final List<CierreProducto> productos;

  const Cierre({
    this.id,
    required this.dia,
    this.cerradoEn,
    required this.numeroVentas,
    required this.total,
    required this.productos,
  });

  bool get guardado => id != null;
}

/// Lo que necesita la pantalla del cierre de hoy: el calculo en vivo y, si
/// ya se cerro, la foto guardada.
class CierreHoy {
  final Cierre enVivo;
  final Cierre? guardado;

  const CierreHoy({required this.enVivo, this.guardado});

  bool get hayVentas => enVivo.numeroVentas > 0;

  bool get cerrado => guardado != null;

  /// Se vendio algo despues de cerrar. Las ventas no se borran, asi que
  /// basta comparar cuantas hay.
  bool get hayVentasNuevas =>
      guardado != null && enVivo.numeroVentas > guardado!.numeroVentas;

  /// Se puede (volver a) cerrar: hay ventas y el dia no esta cerrado, o se
  /// vendio algo despues del cierre.
  bool get puedeCerrar => hayVentas && (!cerrado || hayVentasNuevas);

  /// Si ya esta cerrado y nada cambio se muestra la foto guardada; si no, el
  /// calculo en vivo.
  Cierre get vista => cerrado && !hayVentasNuevas ? guardado! : enVivo;
}
