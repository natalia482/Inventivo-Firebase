class Planta {
  final int? id;
  final String nombrePlantas;
  final String numeroBolsa;
  final double precio;
  final String categoria;
  final int stock;
  final String estado;
  final String fechaCreacion;
  final int idEmpresa;

  Planta({
    this.id,
    required this.nombrePlantas,
    required this.numeroBolsa,
    required this.precio,
    required this.categoria,
    required this.stock,
    required this.estado,
    required this.fechaCreacion,
    required this.idEmpresa,
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: int.tryParse(json['id'].toString()),
      nombrePlantas: json['nombre_plantas'] ?? '',
      numeroBolsa: json['numero_bolsa'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      categoria: json['categoria'] ?? '',
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      estado: json['estado'] ?? 'disponible',
      fechaCreacion: json['fecha_creacion'] ?? '',
      idEmpresa: int.tryParse(json['id_empresa'].toString()) ?? 0,
    );
  }
}
