import 'dart:io';

import 'package:app_cabal/constants/app_routes.dart';
import 'package:app_cabal/constants/iconos_producto.dart';
import 'package:app_cabal/models/producto.dart';
import 'package:app_cabal/providers/imagen_producto_provider.dart';
import 'package:app_cabal/providers/producto_provider.dart';
import 'package:app_cabal/screens/agregar_producto_screen.dart';
import 'package:app_cabal/screens/catalogo_screen.dart';
import 'package:app_cabal/services/imagen_producto_service.dart';
import 'package:app_cabal/services/producto_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductoService extends ProductoService {
  _FakeProductoService([List<Producto> productos = const []])
    : _productos = [...productos];

  final List<Producto> _productos;
  bool fallarAlGuardar = false;

  Producto porId(String id) => _productos.firstWhere((p) => p.id == id);

  @override
  Future<List<Producto>> obtenerProductos() async => [..._productos];

  @override
  Future<void> crearProducto(Producto producto) async {
    if (fallarAlGuardar) throw Exception('disco lleno');
    _productos.add(producto);
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    if (fallarAlGuardar) throw Exception('disco lleno');
    _productos[_productos.indexWhere((p) => p.id == producto.id)] = producto;
  }
}

/// Entrega las fotos de [porElegir] en orden y anota lo que se borra.
class _FakeImagenService extends ImagenProductoService {
  _FakeImagenService({
    this.porElegir = const [],
    this.camara = false,
    this.fallarAlElegir = false,
    Directory? carpeta,
  }) : _carpetaFija = carpeta ?? Directory.systemTemp;

  final List<String> porElegir;
  final bool camara;
  final bool fallarAlElegir;
  final Directory _carpetaFija;
  final List<String> borrados = [];
  int _siguiente = 0;

  @override
  Future<Directory> carpeta() async => _carpetaFija;

  @override
  bool get admiteCamara => camara;

  @override
  Future<String?> elegir({bool camara = false}) async {
    if (fallarAlElegir) throw Exception('sin permiso');
    return porElegir[_siguiente++];
  }

  @override
  Future<void> borrar(String archivo) async => borrados.add(archivo);
}

Future<void> _abrir(
  WidgetTester tester,
  _FakeProductoService productos,
  _FakeImagenService imagenes,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productoServiceProvider.overrideWithValue(productos),
        imagenProductoServiceProvider.overrideWithValue(imagenes),
      ],
      child: MaterialApp(
        home: const CatalogoScreen(),
        routes: {
          AppRoutes.agregarProducto: (context) => const AgregarProductoScreen(),
          AppRoutes.editarProducto: (context) => AgregarProductoScreen(
            producto: ModalRoute.of(context)!.settings.arguments as Producto,
          ),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _imagenDeLaFila(String nombre, IconData icono) => find.descendant(
  of: find.ancestor(of: find.text(nombre), matching: find.byType(ListTile)),
  matching: find.byIcon(icono),
);

Future<void> _editar(WidgetTester tester, String nombre) async {
  await tester.longPress(find.text(nombre));
  await tester.pumpAndSettle();
}

Future<void> _usarIcono(WidgetTester tester, String etiqueta) async {
  await tester.tap(find.text('Usar icono'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(etiqueta));
  await tester.pumpAndSettle();
}

Future<void> _guardarCambios(WidgetTester tester) async {
  await tester.tap(find.text('Guardar cambios'));
  await tester.pumpAndSettle();
}

final _bebida = iconosProducto['bebida']!.icono;

void main() {
  testWidgets('crear con icono lo guarda y el catalogo lo muestra', (
    tester,
  ) async {
    final productos = _FakeProductoService();
    await _abrir(tester, productos, _FakeImagenService());

    await tester.tap(find.text('Agregar producto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Agua pura');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await _usarIcono(tester, 'Bebida');
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final creado = (await productos.obtenerProductos()).single;
    expect(creado.icono, 'bebida');
    expect(creado.imagen, isNull);
    expect(_imagenDeLaFila('Agua pura', _bebida), findsOneWidget);
  });

  testWidgets('un producto sin imagen muestra el icono generico', (
    tester,
  ) async {
    await _abrir(
      tester,
      _FakeProductoService([
        const Producto(id: 'p1', nombre: 'Pan', precio: 1),
      ]),
      _FakeImagenService(),
    );

    expect(_imagenDeLaFila('Pan', iconoProductoGenerico), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported), findsNothing);
  });

  testWidgets('elegir foto la guarda y deja el icono en null', (tester) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, icono: 'lacteos'),
    ]);
    await _abrir(tester, productos, _FakeImagenService(porElegir: ['n.jpg']));

    await _editar(tester, 'Leche');
    await tester.tap(find.text('Elegir foto'));
    await tester.pumpAndSettle();
    await _guardarCambios(tester);

    expect(productos.porId('p1').imagen, 'n.jpg');
    expect(productos.porId('p1').icono, isNull);
  });

  testWidgets('cambiar la foto por un icono borra el archivo de la foto', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'v.jpg'),
    ]);
    final imagenes = _FakeImagenService();
    await _abrir(tester, productos, imagenes);

    await _editar(tester, 'Leche');
    await _usarIcono(tester, 'Lácteos y huevos');
    await _guardarCambios(tester);

    expect(productos.porId('p1').imagen, isNull);
    expect(productos.porId('p1').icono, 'lacteos');
    expect(imagenes.borrados, ['v.jpg']);
  });

  testWidgets('si la base falla no se borra la foto que sigue guardada', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'v.jpg'),
    ])..fallarAlGuardar = true;
    final imagenes = _FakeImagenService();
    await _abrir(tester, productos, imagenes);

    await _editar(tester, 'Leche');
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();
    await _guardarCambios(tester);

    expect(productos.porId('p1').imagen, 'v.jpg');
    expect(imagenes.borrados, isEmpty);
  });

  testWidgets('editar sin tocar la imagen la conserva y no borra nada', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'v.jpg'),
      const Producto(id: 'p2', nombre: 'Pan', precio: 1, icono: 'pan'),
    ]);
    final imagenes = _FakeImagenService();
    await _abrir(tester, productos, imagenes);

    await _editar(tester, 'Leche');
    await tester.enterText(find.byType(TextFormField).at(0), 'Leche entera');
    await _guardarCambios(tester);
    await _editar(tester, 'Pan');
    await tester.enterText(find.byType(TextFormField).at(1), '1.50');
    await _guardarCambios(tester);

    expect(productos.porId('p1').imagen, 'v.jpg');
    expect(productos.porId('p2').icono, 'pan');
    expect(imagenes.borrados, isEmpty);
  });

  testWidgets('cambiar de foto dos veces borra la vieja y la descartada', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'v.jpg'),
    ]);
    final imagenes = _FakeImagenService(porElegir: ['a.jpg', 'b.jpg']);
    await _abrir(tester, productos, imagenes);

    await _editar(tester, 'Leche');
    await tester.tap(find.text('Elegir foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir foto'));
    await tester.pumpAndSettle();
    await _guardarCambios(tester);

    expect(productos.porId('p1').imagen, 'b.jpg');
    expect(imagenes.borrados, unorderedEquals(['a.jpg', 'v.jpg']));
  });

  testWidgets('salir sin guardar borra solo la foto recien elegida', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'v.jpg'),
    ]);
    final imagenes = _FakeImagenService(porElegir: ['a.jpg']);
    await _abrir(tester, productos, imagenes);

    await _editar(tester, 'Leche');
    await tester.tap(find.text('Elegir foto'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(productos.porId('p1').imagen, 'v.jpg');
    expect(imagenes.borrados, ['a.jpg']);
  });

  testWidgets('si elegir foto falla avisa y aun se puede guardar', (
    tester,
  ) async {
    final productos = _FakeProductoService([
      const Producto(id: 'p1', nombre: 'Pan', precio: 1),
    ]);
    await _abrir(tester, productos, _FakeImagenService(fallarAlElegir: true));

    await _editar(tester, 'Pan');
    await tester.tap(find.text('Elegir foto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo cargar la foto'), findsOneWidget);

    await _guardarCambios(tester);
    expect(find.text('Producto actualizado'), findsOneWidget);
  });

  testWidgets('sin camara no se ofrece tomar foto', (tester) async {
    await _abrir(tester, _FakeProductoService(), _FakeImagenService());
    await tester.tap(find.text('Agregar producto'));
    await tester.pumpAndSettle();
    expect(find.text('Tomar foto'), findsNothing);
  });

  testWidgets('con camara se ofrece tomar foto', (tester) async {
    await _abrir(
      tester,
      _FakeProductoService(),
      _FakeImagenService(camara: true),
    );
    await tester.tap(find.text('Agregar producto'));
    await tester.pumpAndSettle();
    expect(find.text('Tomar foto'), findsOneWidget);
  });

  testWidgets('si el archivo de la foto ya no existe se ve el generico', (
    tester,
  ) async {
    final carpeta = Directory.systemTemp.createTempSync('cabal_fotos_');
    addTearDown(() => carpeta.deleteSync(recursive: true));

    await tester.runAsync(
      () => _abrir(
        tester,
        _FakeProductoService([
          const Producto(id: 'p1', nombre: 'Leche', precio: 9, imagen: 'x.jpg'),
        ]),
        _FakeImagenService(carpeta: carpeta),
      ),
    );
    // La lectura del archivo es E/S real; hay que dejarla terminar fuera del
    // reloj falso del test para que llegue al errorBuilder.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(_imagenDeLaFila('Leche', iconoProductoGenerico), findsOneWidget);
  });
}
