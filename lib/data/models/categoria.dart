
class Categoria {
  final int? id;
  final String nombre;
  final String icono;

  Categoria({
    this.id,
    required this.nombre,
    required this.icono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      icono: map['icono'] as String,
    );
  }
}
