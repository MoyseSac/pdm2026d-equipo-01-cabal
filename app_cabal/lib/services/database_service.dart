import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'cabal.db');

    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE producto (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            eliminado_en TEXT,
            imagen TEXT,
            icono TEXT,
            archivado_en TEXT
          )
        ''');
        await db.execute(_indiceNombreUnico);

        await db.execute('''
          CREATE TABLE venta (
            id TEXT PRIMARY KEY,
            fecha_hora TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE detalle_venta (
            venta_id TEXT NOT NULL,
            producto_id TEXT NOT NULL,
            nombre_producto TEXT,
            cantidad INTEGER NOT NULL,
            precio_al_momento REAL NOT NULL,

            PRIMARY KEY (venta_id, producto_id),

            FOREIGN KEY (venta_id)
              REFERENCES venta(id),

            FOREIGN KEY (producto_id)
              REFERENCES producto(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE producto ADD COLUMN eliminado_en TEXT');
          await db.execute(
            'ALTER TABLE detalle_venta ADD COLUMN nombre_producto TEXT',
          );
          await db.execute('''
            UPDATE detalle_venta
            SET nombre_producto = (
              SELECT nombre FROM producto WHERE producto.id = detalle_venta.producto_id
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE producto ADD COLUMN imagen TEXT');
          await db.execute('ALTER TABLE producto ADD COLUMN icono TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE producto ADD COLUMN archivado_en TEXT');
          await _renombrarNombresRepetidos(db);
          await db.execute(_indiceNombreUnico);
        }
      },
    );
  }

  /// Un nombre no se repite entre los productos del catalogo, sin importar
  /// mayusculas. Los borrados quedan fuera para poder reusar su nombre.
  static const _indiceNombreUnico = '''
    CREATE UNIQUE INDEX idx_producto_nombre
    ON producto(nombre COLLATE NOCASE)
    WHERE eliminado_en IS NULL
  ''';

  /// Antes de crear el indice unico, un telefono con nombres repetidos los
  /// conserva todos: el segundo pasa a "Nombre (2)", el tercero a "(3)".
  Future<void> _renombrarNombresRepetidos(Database db) async {
    final filas = await db.query(
      'producto',
      columns: ['id', 'nombre'],
      where: 'eliminado_en IS NULL',
      orderBy: 'rowid ASC',
    );
    final usados = <String>{};
    for (final fila in filas) {
      final base = fila['nombre'] as String;
      var nombre = base;
      var n = 2;
      while (!usados.add(nombre.toLowerCase())) {
        nombre = '$base ($n)';
        n++;
      }
      if (nombre != base) {
        await db.update(
          'producto',
          {'nombre': nombre},
          where: 'id = ?',
          whereArgs: [fila['id']],
        );
      }
    }
  }

  Future<void> close() async {
    final db = _database;

    if (db != null && db.isOpen) {
      await db.close();
    }

    _database = null;
  }
}
