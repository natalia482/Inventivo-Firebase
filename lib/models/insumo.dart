class Insumo {
  final int? id;
  final String nombreInsumo;
  final String categoria;
  final double precio;
  final String medida;
  final int cantidad;
  final int idEmpresa;
  final String fechaRegistro;

  Insumo({
    this.id,
    required this.nombreInsumo,
    required this.categoria,
    required this.precio,
    required this.medida,
    required this.cantidad,
    required this.idEmpresa,
    required this.fechaRegistro,
  });

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: int.tryParse(json['id'].toString()),
      nombreInsumo: json['nombre_insumo'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      medida: json['medida'] ?? '',
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      idEmpresa: int.tryParse(json['id_empresa'].toString()) ?? 0,
      fechaRegistro: json['fecha_registro'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_insumo': nombreInsumo,
      'categoria': categoria,
      'precio': precio,
      'medida': medida,
      'cantidad': cantidad,
      'id_empresa': idEmpresa,
      'fecha_registro': fechaRegistro,
    };
  }
}
