
class Presupuesto {
  final int? id;
  final int categoriaId;
  final double limite;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  Presupuesto({
    this.id,
    required this.categoriaId,
    required this.limite,
    required this.fechaInicio,
    required this.fechaFin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'limite': limite,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
    };
  }

  factory Presupuesto.fromMap(Map<String, dynamic> map) {
    return Presupuesto(
      id: map['id'] as int?,
      categoriaId: map['categoria_id'] as int,
      limite: (map['limite'] as num).toDouble(),
      fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
      fechaFin: DateTime.parse(map['fecha_fin'] as String),
    );
  }
}
