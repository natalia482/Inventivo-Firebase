class Remision {
  final int? id;
  final String numeroFactura;
  final int idSede; // Modificado (no nullable)
  final int idVendedor; // Modificado (no nullable)
  final double total;
  final String? fechaEmision;
  final List<DetalleRemision> detalles;

  Remision({
    this.id,
    required this.numeroFactura,
    required this.idSede, // Modificado
    required this.idVendedor,
    required this.total,
    this.fechaEmision,
    this.detalles = const [],
  });
  
  factory Remision.fromJson(Map<String, dynamic> json) {
    return Remision(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      numeroFactura: json['numero_factura'] ?? '',
      
      // ✅ CORRECCIÓN: Añadir '?? 0' al final para asegurar un 'int' no nulo.
      idSede: int.tryParse(json['id_sede']?.toString() ?? '0') ?? 0,
      idVendedor: int.tryParse(json['id_vendedor']?.toString() ?? '0') ?? 0,
      
      fechaEmision: json['fecha_emision'],
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      detalles: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "numero_factura": numeroFactura.isEmpty ? null : numeroFactura,
      "id_sede": idSede, // Modificado
      "id_vendedor": idVendedor,
      "total": total,
      "detalles": detalles.map((d) => d.toJson()).toList(),
    };
  }
}

// Modelo para el Detalle de Remisión
class DetalleRemision {
  final int? id;
  final int? idRemision; // Modificado
  final int idProducto;
  final String? nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleRemision({
    this.id,
    this.idRemision, // Modificado
    required this.idProducto,
    this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleRemision.fromJson(Map<String, dynamic> json) {
    return DetalleRemision(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      idRemision: int.tryParse(json['id_remision']?.toString() ?? '0'), // Modificado
      idProducto: int.tryParse(json['id_producto']?.toString() ?? '0') ?? 0,
      nombreProducto: json['nombre_plantas'],
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id_producto": idProducto,
      "cantidad": cantidad,
      "precio_unitario": precioUnitario,
    };
  }
}

// Modelo para Productos (Plantas) Disponibles
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