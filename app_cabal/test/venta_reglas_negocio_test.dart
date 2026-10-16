import 'dart:async';

import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/venta_provider.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cola = Producto(id: 'p1', nombre: 'Coca Cola', precio: 10.5);
const _pan = Producto(id: 'p2', nombre: 'Pan dulce', precio: 2.5);

/// Servicio de ventas en memoria para probar las reglas sin base de datos.
class _VentaServiceFalso extends VentaService {
  final List<Venta> guardadas = [];
  Object? error;
  Completer<void>? espera;
  int llamadas = 0;

  @override
  Future<void> registrarVenta(Venta venta) async {
    llamadas++;
    if (espera != null) await espera!.future;
    if (error != null) throw error!;
    guardadas.add(venta);
  }
}

DetalleVenta _detalle(double precio, int cantidad) => DetalleVenta(
      producto: Producto(id: 'x$precio', nombre: 'P', precio: precio),
      cantidad: cantidad,
      precioAlMomento: precio,
    );

void main() {
  late _VentaServiceFalso servicio;
  late ProviderContainer container;
  late VentaNotifier notifier;

  VentaState estado() => container.read(ventaProvider);

  setUp(() {
    servicio = _VentaServiceFalso();
    container = ProviderContainer(
      overrides: [ventaServiceProvider.overrideWithValue(servicio)],
    );
    addTearDown(container.dispose);
    notifier = container.read(ventaProvider.notifier);
  });

  group('una venta debe tener al menos un producto', () {
    test('confirmar sin productos se rechaza y no llama al servicio',
        () async {
      final ok = await notifier.confirmarVenta();

      expect(ok, isFalse);
      expect(estado().estado, EstadoRegistroVenta.error);
      expect(estado().mensajeError, mensajeVentaSinProductos);
      expect(servicio.llamadas, 0);
      expect(estado().ventaConfirmada, isNull);
    });

    test('confirmar tras quitar todos los productos también se rechaza',
        () async {
      notifier.agregarProducto(_cola, 1);
      notifier.quitarProducto(_cola.id);

      final ok = await notifier.confirmarVenta();

      expect(ok, isFalse);
      expect(estado().mensajeError, mensajeVentaSinProductos);
      expect(servicio.llamadas, 0);
    });

    test('con un producto la venta sí se guarda', () async {
      notifier.agregarProducto(_cola, 1);

      expect(await notifier.confirmarVenta(), isTrue);
      expect(servicio.guardadas, hasLength(1));
    });
  });

  group('cantidades inválidas', () {
    for (final cantidad in [0, -1, -10]) {
      test('agregarProducto rechaza la cantidad $cantidad', () {
        expect(notifier.agregarProducto(_cola, cantidad), isFalse);

        expect(estado().estado, EstadoRegistroVenta.error);
        expect(estado().mensajeError, mensajeCantidadInvalida);
        expect(estado().detalles, isEmpty);
      });

      test('establecerCantidad rechaza $cantidad y conserva la anterior', () {
        notifier.agregarProducto(_cola, 2);

        expect(notifier.establecerCantidad(_cola.id, cantidad), isFalse);

        expect(estado().mensajeError, mensajeCantidadInvalida);
        expect(estado().detalles.single.cantidad, 2);
      });
    }

    test('una cantidad inválida no modifica un producto ya agregado', () {
      notifier.agregarProducto(_cola, 3);
      notifier.agregarProducto(_cola, 0);

      expect(estado().detalles.single.cantidad, 3);
    });

    test('una cantidad válida después de un error limpia el error', () {
      notifier.agregarProducto(_cola, 0);
      expect(estado().estado, EstadoRegistroVenta.error);

      expect(notifier.agregarProducto(_cola, 1), isTrue);

      expect(estado().estado, EstadoRegistroVenta.inactivo);
      expect(estado().mensajeError, isNull);
    });

    test('establecerCantidad sobre un producto ausente no cambia nada', () {
      expect(notifier.establecerCantidad('p-ausente', 2), isFalse);
      expect(estado().detalles, isEmpty);
    });
  });

  group('subtotales y total general', () {
    test('subtotal = cantidad x precio', () {
      expect(subtotalDe(_detalle(10.5, 2)), 21.0);
      expect(subtotalDe(_detalle(2.5, 3)), 7.5);
      expect(subtotalDe(_detalle(8, 1)), 8.0);
      expect(subtotalDe(_detalle(0.01, 1)), 0.01);
    });

    test('el subtotal no arrastra errores de representación', () {
      expect(subtotalDe(_detalle(0.1, 3)), 0.3);
      expect(subtotalDe(_detalle(19.99, 3)), 59.97);
      expect(subtotalDe(_detalle(1.15, 100)), 115.0);
    });

    test('el total es la suma de los subtotales', () {
      expect(totalDe([_detalle(10.5, 2), _detalle(2.5, 3)]), 28.5);
      expect(totalDe([_detalle(0.1, 1), _detalle(0.2, 1)]), 0.3);
      expect(
        totalDe([_detalle(0.1, 1), _detalle(0.2, 1), _detalle(0.3, 1)]),
        0.6,
      );
    });

    test('el total de una lista vacía es cero', () {
      expect(totalDe(const []), 0);
    });

    test('el total del estado se actualiza al agregar, cambiar y quitar', () {
      expect(estado().total, 0);

      notifier.agregarProducto(_cola, 2);
      expect(estado().total, 21.0);

      notifier.agregarProducto(_pan, 3);
      expect(estado().total, 28.5);

      notifier.establecerCantidad(_pan.id, 1);
      expect(estado().total, 23.5);

      notifier.quitarProducto(_cola.id);
      expect(estado().total, 2.5);
    });
  });

  group('productos repetidos y precio al momento', () {
    test('un producto repetido suma cantidades en un solo detalle', () {
      notifier.agregarProducto(_cola, 2);
      notifier.agregarProducto(_cola, 1);

      expect(estado().detalles, hasLength(1));
      expect(estado().detalles.single.cantidad, 3);
    });

    test('el detalle conserva el precio con el que se agregó', () {
      notifier.agregarProducto(_cola, 1);

      // El catálogo cambia de precio mientras la venta sigue en curso.
      notifier.agregarProducto(_cola.copyWith(precio: 15), 1);

      final detalle = estado().detalles.single;
      expect(detalle.cantidad, 2);
      expect(detalle.precioAlMomento, 10.5);
      expect(estado().total, 21.0);
    });

    test('la venta guardada conserva el precio del momento', () async {
      notifier.agregarProducto(_cola, 2);
      await notifier.confirmarVenta();

      final guardada = servicio.guardadas.single;
      expect(guardada.detalles.single.precioAlMomento, 10.5);
      expect(totalDe(guardada.detalles), 21.0);
    });

    test('al guardar se envía un detalle por producto con sus cantidades',
        () async {
      notifier.agregarProducto(_cola, 2);
      notifier.agregarProducto(_pan, 3);
      await notifier.confirmarVenta();

      final guardada = servicio.guardadas.single;
      expect(guardada.detalles, hasLength(2));
      expect(guardada.detalles.map((d) => d.producto.id), ['p1', 'p2']);
      expect(guardada.detalles.map((d) => d.cantidad), [2, 3]);
      expect(guardada.id, isNotEmpty);
    });
  });

  group('errores del servicio de ventas', () {
    test('si falla se informa el error y se conserva la venta en curso',
        () async {
      servicio.error = Exception('fallo simulado');
      notifier.agregarProducto(_cola, 2);
      notifier.agregarProducto(_pan, 1);

      final ok = await notifier.confirmarVenta();

      expect(ok, isFalse);
      expect(estado().estado, EstadoRegistroVenta.error);
      expect(estado().mensajeError, mensajeErrorGuardado);
      expect(estado().detalles, hasLength(2));
      expect(estado().total, 23.5);
      expect(estado().guardando, isFalse);
      expect(estado().ventaConfirmada, isNull);
    });

    test('cualquier tipo de error produce el mismo mensaje al usuario',
        () async {
      for (final error in <Object>[
        StateError('x'),
        ArgumentError('x'),
        'texto',
      ]) {
        servicio.error = error;
        notifier.limpiar();
        notifier.agregarProducto(_cola, 1);

        expect(await notifier.confirmarVenta(), isFalse);
        expect(estado().mensajeError, mensajeErrorGuardado);
      }
    });

    test('tras un fallo se puede reintentar y guardar', () async {
      servicio.error = Exception('fallo simulado');
      notifier.agregarProducto(_cola, 2);
      expect(await notifier.confirmarVenta(), isFalse);

      servicio.error = null;
      final ok = await notifier.confirmarVenta();

      expect(ok, isTrue);
      expect(servicio.llamadas, 2);
      expect(servicio.guardadas, hasLength(1));
      expect(estado().estado, EstadoRegistroVenta.exito);
      expect(estado().detalles, isEmpty);
      expect(estado().mensajeError, isNull);
    });

    test('un fallo no deja una venta confirmada anterior', () async {
      notifier.agregarProducto(_cola, 1);
      await notifier.confirmarVenta();
      expect(estado().ventaConfirmada, isNotNull);

      servicio.error = Exception('fallo simulado');
      notifier.agregarProducto(_pan, 1);
      await notifier.confirmarVenta();

      expect(estado().ventaConfirmada, isNull);
    });

    test('mientras se guarda se ignoran confirmaciones y cambios', () async {
      servicio.espera = Completer<void>();
      notifier.agregarProducto(_cola, 1);

      final primera = notifier.confirmarVenta();
      expect(estado().guardando, isTrue);

      expect(await notifier.confirmarVenta(), isFalse);
      expect(notifier.agregarProducto(_pan, 1), isFalse);
      expect(notifier.establecerCantidad(_cola.id, 5), isFalse);
      notifier.quitarProducto(_cola.id);
      notifier.limpiar();
      expect(estado().detalles.single.cantidad, 1);

      servicio.espera!.complete();
      expect(await primera, isTrue);
      expect(servicio.llamadas, 1);
      expect(servicio.guardadas, hasLength(1));
    });
  });

  group('venta confirmada', () {
    test('tras guardar la venta en curso queda vacía', () async {
      notifier.agregarProducto(_cola, 2);

      await notifier.confirmarVenta();

      expect(estado().detalles, isEmpty);
      expect(estado().total, 0);
      expect(estado().ventaConfirmada, isNotNull);
      expect(totalDe(estado().ventaConfirmada!.detalles), 21.0);
    });

    test('la fecha de la venta es la del momento de confirmar', () async {
      final antes = DateTime.now();
      notifier.agregarProducto(_cola, 1);
      await notifier.confirmarVenta();
      final despues = DateTime.now();

      final fecha = servicio.guardadas.single.fechaHora;
      expect(fecha.isBefore(antes), isFalse);
      expect(fecha.isAfter(despues), isFalse);
    });

    test('dos ventas seguidas tienen ids distintos', () async {
      notifier.agregarProducto(_cola, 1);
      await notifier.confirmarVenta();
      // El id sale del reloj en microsegundos; en uso real pasan segundos
      // entre ventas, pero en una prueba automatizada hay que dejar avanzar
      // el reloj para no chocar con el id anterior.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      notifier.agregarProducto(_cola, 1);
      await notifier.confirmarVenta();

      expect(servicio.guardadas, hasLength(2));
      expect(servicio.guardadas[0].id, isNot(servicio.guardadas[1].id));
    });
  });
}
