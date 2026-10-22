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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE producto (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            eliminado_en TEXT
          )
        ''');

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
      },
    );
  }

  Future<void> close() async {
    final db = _database;

    if (db != null && db.isOpen) {
      await db.close();
    }

    _database = null;
  }
}
