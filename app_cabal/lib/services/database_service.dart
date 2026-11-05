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
      version: 5,
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

        await _crearTablasCierre(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Cada paso se puede repetir: una base con un user_version menor al
        // que le corresponden sus columnas (por ejemplo, de una compilacion
        // intermedia) no debe fallar por algo que ya existe.
        if (oldVersion < 2) {
          await _agregarColumna(db, 'producto', 'eliminado_en', 'TEXT');
          await _agregarColumna(db, 'detalle_venta', 'nombre_producto', 'TEXT');
          // Solo rellena los que no tienen nombre, para no pisar el nombre
          // historico de una columna que ya existia.
          await db.execute('''
            UPDATE detalle_venta
            SET nombre_producto = (
              SELECT nombre FROM producto WHERE producto.id = detalle_venta.producto_id
            )
            WHERE nombre_producto IS NULL
          ''');
        }
        if (oldVersion < 3) {
          await _agregarColumna(db, 'producto', 'imagen', 'TEXT');
          await _agregarColumna(db, 'producto', 'icono', 'TEXT');
        }
        if (oldVersion < 4) {
          await _agregarColumna(db, 'producto', 'archivado_en', 'TEXT');
          await _renombrarNombresRepetidos(db);
          await db.execute(_indiceNombreUnico);
        }
        if (oldVersion < 5) {
          await _crearTablasCierre(db);
        }
      },
    );
  }

  /// Tablas del cierre del dia. Un cierre es una foto: por eso
  /// `cierre_producto` copia el nombre y los montos, y no tiene llave foranea
  /// hacia `producto` (el producto se puede archivar o borrar despues sin
  /// tocar el cierre). El dinero va en centavos enteros.
  ///
  /// Todo usa IF NOT EXISTS para que se pueda repetir sin fallar.
  Future<void> _crearTablasCierre(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cierre (
        id TEXT PRIMARY KEY,
        dia TEXT NOT NULL,
        cerrado_en TEXT NOT NULL,
        numero_ventas INTEGER NOT NULL,
        total_centavos INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_cierre_dia
      ON cierre(dia)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cierre_producto (
        cierre_id TEXT NOT NULL,
        producto_id TEXT NOT NULL,
        nombre_producto TEXT NOT NULL,
        unidades INTEGER NOT NULL,
        subtotal_centavos INTEGER NOT NULL,

        PRIMARY KEY (cierre_id, producto_id),

        FOREIGN KEY (cierre_id)
          REFERENCES cierre(id)
          ON DELETE CASCADE
      )
    ''');
  }

  /// Agrega la columna solo si la tabla todavia no la tiene.
  Future<void> _agregarColumna(
    Database db,
    String tabla,
    String columna,
    String tipo,
  ) async {
    final columnas = await db.rawQuery('PRAGMA table_info($tabla)');
    if (columnas.any((c) => c['name'] == columna)) return;
    await db.execute('ALTER TABLE $tabla ADD COLUMN $columna $tipo');
  }

  /// Un nombre no se repite entre los productos del catalogo, sin importar
  /// mayusculas. Los borrados quedan fuera para poder reusar su nombre.
  static const _indiceNombreUnico = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_producto_nombre
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
