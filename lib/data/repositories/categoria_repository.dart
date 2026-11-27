
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final DatabaseHelper databaseHelper;

  CategoriaRepository({DatabaseHelper? databaseHelper})
      : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Categoria>> obtenerCategorias() async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'categorias',
      orderBy: 'nombre ASC',
    );

    return resultado.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<int> crearCategoria(Categoria categoria) async {
    final db = await databaseHelper.database;

    final datos = categoria.toMap()..remove('id');

    return await db.insert(
      'categorias',
      datos,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> actualizarCategoria(Categoria categoria) async {
    if (categoria.id == null) {
      throw ArgumentError('La categoría necesita un ID para actualizarse');
    }

    final db = await databaseHelper.database;
    final datos = categoria.toMap()..remove('id');

    return await db.update(
      'categorias',
      datos,
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> eliminarCategoria(int id) async {
    final db = await databaseHelper.database;

    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
