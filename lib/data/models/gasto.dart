
class Gasto {
  final int? id;
  final String titulo;
  final double monto;
  final String descripcion;
  final int categoriaId;
  final DateTime fecha;

  Gasto({
    this.id,
    required this.titulo,
    required this.monto,
    required this.descripcion,
    required this.categoriaId,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      monto: (map['monto'] as num).toDouble(),
      descripcion: map['descripcion'] as String,
      categoriaId: map['categoria_id'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}
