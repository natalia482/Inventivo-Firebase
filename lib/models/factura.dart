class Factura {
  final int? id;
  final String numeroFactura;
  final int idEmpresa;
  final int idVendedor;
  final String? fechaEmision;
  final double total;
  final List<DetalleFactura> detalles;

  Factura({
    this.id,
    required this.numeroFactura,
    required this.idEmpresa,
    required this.idVendedor,
    this.fechaEmision,
    required this.total,
    required this.detalles,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      numeroFactura: json['numero_factura'] ?? '',
      idEmpresa: int.tryParse(json['id_empresa']?.toString() ?? '0') ?? 0,
      idVendedor: int.tryParse(json['id_vendedor']?.toString() ?? '0') ?? 0,
      fechaEmision: json['fecha_emision'],
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      detalles: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero_factura': numeroFactura.isEmpty ? null : numeroFactura, // Si está vacío, enviar null
      'id_empresa': idEmpresa,
      'id_vendedor': idVendedor,
      'total': total,
      'detalles': detalles.map((d) => d.toJson()).toList(),
    };
  }
}

class DetalleFactura {
  final int? id;
  final int? idFactura;
  final int idProducto;
  final String? nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleFactura({
    this.id,
    this.idFactura,
    required this.idProducto,
    this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleFactura.fromJson(Map<String, dynamic> json) {
    return DetalleFactura(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      idFactura: int.tryParse(json['id_factura']?.toString() ?? '0'),
      idProducto: int.tryParse(json['id_producto']?.toString() ?? '0') ?? 0,
      nombreProducto: json['nombre_plantas'],
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}

class ProductoDisponible {
  final int id;
  final String nombrePlantas;
  final String categoria;
  final double precio;
  final int stock;
  final String estado;

  ProductoDisponible({
    required this.id,
    required this.nombrePlantas,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.estado,
  });

  factory ProductoDisponible.fromJson(Map<String, dynamic> json) {
    return ProductoDisponible(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombrePlantas: json['nombre_plantas'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      estado: json['estado'] ?? '',
    );
  }
}