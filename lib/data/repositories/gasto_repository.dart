
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/gasto.dart';

class GastoRepository {
  final DatabaseHelper databaseHelper;

  GastoRepository({DatabaseHelper? databaseHelper})
      : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // CREATE: Registrar un gasto.
  Future<int> crearGasto(Gasto gasto) async {
    final db = await databaseHelper.database;

    return await db.insert(
      'gastos',
      gasto.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ: Consultar todos los gastos.
  Future<List<Gasto>> obtenerGastos() async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'gastos',
      orderBy: 'fecha DESC, id DESC',
    );

    return resultado.map((map) => Gasto.fromMap(map)).toList();
  }

  // READ: Consultar un gasto por su ID.
  Future<Gasto?> obtenerGastoPorId(int id) async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) return null;

    return Gasto.fromMap(resultado.first);
  }

  // UPDATE: Actualizar un gasto.
  Future<int> actualizarGasto(Gasto gasto) async {
    if (gasto.id == null) {
      throw ArgumentError('El gasto necesita un ID para actualizarse');
    }

    final db = await databaseHelper.database;

    final datos = gasto.toMap()..remove('id');

    return await db.update(
      'gastos',
      datos,
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  // DELETE: Eliminar un gasto.
  Future<int> eliminarGasto(int id) async {
    final db = await databaseHelper.database;

    return await db.delete(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
