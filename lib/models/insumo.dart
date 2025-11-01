class Insumo {
  final int? id;
  final String nombreInsumo;
  final String categoria;
  final double precio;
  final String medida;
  final double cantidad; // Modificado a double
  final int idSede; // Modificado
  final String fechaRegistro;
  final String estado; // Añadido

  Insumo({
    this.id,
    required this.nombreInsumo,
    required this.categoria,
    required this.precio,
    required this.medida,
    required this.cantidad,
    required this.idSede, // Modificado
    required this.fechaRegistro,
    required this.estado, // Añadido
  });

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: int.tryParse(json['id'].toString()),
      nombreInsumo: json['nombre_insumo'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      medida: json['medida'] ?? '',
      cantidad: double.tryParse(json['cantidad'].toString()) ?? 0.0, // Modificado
      idSede: int.tryParse(json['id_sede'].toString()) ?? 0, // Modificado
      fechaRegistro: json['fecha_registro'] ?? '',
      estado: json['estado'] ?? 'DISPONIBLE', // Añadido
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_insumo': nombreInsumo,
      'categoria': categoria,
      'precio': precio.toString(),
      'medida': medida,
      'cantidad': cantidad.toString(),
      'id_sede': idSede, // Modificado
      'fecha_registro': fechaRegistro,
    };
  }
}