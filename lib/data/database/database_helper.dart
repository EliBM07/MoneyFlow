
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('moneyflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
      UPDATE categorias
      SET nombre = REPLACE(nombre, 'Ã³', 'ó')
    ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icono TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        monto REAL NOT NULL CHECK(monto > 0),
        descripcion TEXT NOT NULL DEFAULT '',
        categoria_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (categoria_id)
          REFERENCES categorias(id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE presupuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id INTEGER NOT NULL,
        limite REAL NOT NULL CHECK(limite > 0),
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        FOREIGN KEY (categoria_id)
          REFERENCES categorias(id)
          ON DELETE CASCADE,
        CHECK(fecha_fin >= fecha_inicio)
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(DatabaseExecutor db) async {
    final categories = [
      {'nombre': 'Alimentación', 'icono': 'restaurant'},
      {'nombre': 'Transporte', 'icono': 'directions_car'},
      {'nombre': 'Salud', 'icono': 'medical_services'},
      {'nombre': 'Entretenimiento', 'icono': 'movie'},
      {'nombre': 'Educación', 'icono': 'school'},
      {'nombre': 'Otros', 'icono': 'category'},
    ];

    for (final category in categories) {
      await db.insert('categorias', category);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
