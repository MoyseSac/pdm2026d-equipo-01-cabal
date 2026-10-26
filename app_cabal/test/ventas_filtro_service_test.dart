import 'dart:io';

import 'package:app_cabal/models/detalle_venta.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/models/venta.dart';
import 'package:app_cabal/providers/ventas_filtro_provider.dart';
import 'package:app_cabal/services/database_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:app_cabal/services/venta_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _producto = Producto(id: 'p1', nombre: 'Producto prueba', precio: 10);

final _ahora = DateTime(2026, 10, 26, 12);

void main() {
  late Directory carpeta;
  late VentaService servicio;

  // Base SQLite temporal independiente.
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    carpeta = Directory.systemTemp.createTempSync('cabal_filtro_ventas_');

    await databaseFactory.setDatabasesPath(carpeta.path);
  });

  Future<void> insertarVenta(String id, DateTime fecha) async {
    await servicio.registrarVenta(
      Venta(
        id: id,
        fechaHora: fecha,
        detalles: const [
          DetalleVenta(producto: _producto, cantidad: 1, precioAlMomento: 10),
        ],
      ),
    );
  }

  Future<List<Venta>> consultar(Periodo periodo) {
    final filtro = VentasFiltro(periodo: periodo);
    final rango = filtro.calcularRango(_ahora);

    return servicio.obtenerVentas(
      desde: rango?.desde,
      hastaExclusivo: rango?.hastaExclusivo,
    );
  }

  Set<String> ids(List<Venta> ventas) {
    return ventas.map((venta) => venta.id).toSet();
  }

  setUp(() async {
    await DatabaseService.instance.close();

    await deleteDatabase('${carpeta.path}/cabal.db');

    servicio = VentaService();

    final productos = ProductoService();
    await productos.crearProducto(_producto);

    // Venta del mes anterior.
    await insertarVenta('septiembre', DateTime(2026, 9, 30, 23, 59, 59));

    // Primer instante del mes.
    await insertarVenta('octubre_inicio', DateTime(2026, 10, 1));

    // Un instante antes de los ultimos 7 dias.
    await insertarVenta('antes_7_dias', DateTime(2026, 10, 19, 23, 59, 59));

    // Inicio exacto del periodo de 7 dias.
    await insertarVenta('inicio_7_dias', DateTime(2026, 10, 20));

    // Venta de ayer.
    await insertarVenta('ayer', DateTime(2026, 10, 25, 18, 30));

    // Inicio exacto de hoy.
    await insertarVenta('hoy_medianoche', DateTime(2026, 10, 26));

    // Venta durante el dia.
    await insertarVenta('hoy_mediodia', DateTime(2026, 10, 26, 11, 30));

    // Ultimo segundo del dia.
    await insertarVenta('hoy_final', DateTime(2026, 10, 26, 23, 59, 59));

    // Primer instante de manana.
    await insertarVenta('manana', DateTime(2026, 10, 27));

    // Primer instante del mes siguiente.
    await insertarVenta('noviembre', DateTime(2026, 11, 1));
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();

    if (carpeta.existsSync()) {
      carpeta.deleteSync(recursive: true);
    }
  });

  group('Filtro de ventas con SQLite real', () {
    test('Todas devuelve todas las ventas', () async {
      final resultado = await consultar(Periodo.todas);

      expect(resultado, hasLength(10));

      expect(
        ids(resultado),
        containsAll([
          'septiembre',
          'octubre_inicio',
          'hoy_medianoche',
          'noviembre',
        ]),
      );
    });

    test('Hoy incluye medianoche y excluye manana', () async {
      final resultado = await consultar(Periodo.hoy);

      expect(
        ids(resultado),
        equals({'hoy_medianoche', 'hoy_mediodia', 'hoy_final'}),
      );

      // Las ventas deben recuperar sus detalles.
      for (final venta in resultado) {
        expect(venta.detalles, hasLength(1));
        expect(venta.detalles.first.precioAlMomento, 10);
      }
    });

    test('Ultimos 7 dias incluye el limite inicial', () async {
      final resultado = await consultar(Periodo.ultimos7Dias);

      expect(
        ids(resultado),
        equals({
          'inicio_7_dias',
          'ayer',
          'hoy_medianoche',
          'hoy_mediodia',
          'hoy_final',
        }),
      );

      expect(ids(resultado), isNot(contains('antes_7_dias')));

      expect(ids(resultado), isNot(contains('manana')));
    });

    test('Este mes incluye octubre y excluye otros meses', () async {
      final resultado = await consultar(Periodo.esteMes);

      expect(
        ids(resultado),
        equals({
          'octubre_inicio',
          'antes_7_dias',
          'inicio_7_dias',
          'ayer',
          'hoy_medianoche',
          'hoy_mediodia',
          'hoy_final',
          'manana',
        }),
      );

      expect(ids(resultado), isNot(contains('septiembre')));

      expect(ids(resultado), isNot(contains('noviembre')));
    });

    test('Un rango sin coincidencias devuelve lista vacia', () async {
      final resultado = await servicio.obtenerVentas(
        desde: DateTime(2026, 12, 1),
        hastaExclusivo: DateTime(2027, 1, 1),
      );

      expect(resultado, isEmpty);
    });

    test('Las ventas se ordenan de reciente a antigua', () async {
      final resultado = await consultar(Periodo.hoy);

      expect(resultado.map((venta) => venta.id).toList(), [
        'hoy_final',
        'hoy_mediodia',
        'hoy_medianoche',
      ]);
    });
  });

  group('Calculo de periodos', () {
    test('Todas no genera rango de fechas', () {
      const filtro = VentasFiltro(periodo: Periodo.todas);

      expect(filtro.calcularRango(_ahora), isNull);
    });

    test('Los ultimos 7 dias cruzan correctamente el mes', () {
      const filtro = VentasFiltro(periodo: Periodo.ultimos7Dias);

      final rango = filtro.calcularRango(DateTime(2026, 11, 3, 12))!;

      expect(rango.desde, DateTime(2026, 10, 28));

      expect(rango.hastaExclusivo, DateTime(2026, 11, 4));
    });

    test('Este mes reconoce el inicio del mes siguiente', () {
      const filtro = VentasFiltro(periodo: Periodo.esteMes);

      final rango = filtro.calcularRango(DateTime(2026, 12, 15))!;

      expect(rango.desde, DateTime(2026, 12, 1));

      expect(rango.hastaExclusivo, DateTime(2027, 1, 1));
    });
  });
}
