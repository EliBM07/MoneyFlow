
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/presupuesto.dart';

class PresupuestoRepository {
  final DatabaseHelper databaseHelper;

  PresupuestoRepository({DatabaseHelper? databaseHelper})
      : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Obtener todos los presupuestos.
  Future<List<Presupuesto>> obtenerPresupuestos() async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'presupuestos',
      orderBy: 'fecha_inicio DESC',
    );

    return resultado
        .map((map) => Presupuesto.fromMap(map))
        .toList();
  }

  // Crear presupuesto.
  Future<int> crearPresupuesto(Presupuesto presupuesto) async {
    final db = await databaseHelper.database;

    final datos = presupuesto.toMap()..remove('id');

    return await db.insert(
      'presupuestos',
      datos,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Actualizar presupuesto.
  Future<int> actualizarPresupuesto(
      Presupuesto presupuesto,
      ) async {
    if (presupuesto.id == null) {
      throw ArgumentError('El presupuesto necesita un ID');
    }

    final db = await databaseHelper.database;
    final datos = presupuesto.toMap()..remove('id');

    return await db.update(
      'presupuestos',
      datos,
      where: 'id = ?',
      whereArgs: [presupuesto.id],
    );
  }

  // Eliminar presupuesto.
  Future<int> eliminarPresupuesto(int id) async {
    final db = await databaseHelper.database;

    return await db.delete(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Calcular cuánto se ha gastado en una categoría.
  Future<double> calcularGastado({
    required int categoriaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final db = await databaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(monto), 0) AS total
      FROM gastos
      WHERE categoria_id = ?
      AND fecha >= ?
      AND fecha <= ?
      ''',
      [
        categoriaId,
        fechaInicio.toIso8601String(),
        fechaFin.toIso8601String(),
      ],
    );

    return (resultado.first['total'] as num).toDouble();
  }
}
