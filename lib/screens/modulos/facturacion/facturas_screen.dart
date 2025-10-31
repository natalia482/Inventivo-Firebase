import 'package:flutter/material.dart';
import 'package:inventivo/models/factura.dart';
import 'package:inventivo/services/factura_service.dart';

class FacturasScreen extends StatefulWidget {
  final int idEmpresa;
  final int idVendedor;

  const FacturasScreen({
    super.key,
    required this.idEmpresa,
    required this.idVendedor,
  });

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  final FacturaService _service = FacturaService();
  List<Factura> facturas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarFacturas();
  }

  Future<void> cargarFacturas() async {
    setState(() => isLoading = true);
    final data = await _service.listarFacturas(widget.idEmpresa);
    setState(() {
      facturas = data;
      isLoading = false;
    });
  }

  void mostrarFormularioFactura() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearFacturaScreen(
          idEmpresa: widget.idEmpresa,
          idVendedor: widget.idVendedor,
        ),
      ),
    ).then((_) => cargarFacturas());
  }

  Future<void> eliminarFactura(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Factura',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro? Esta acción devolverá el stock de los productos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final result = await _service.eliminarFactura(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result
              ? '✅ Factura eliminada correctamente'
              : '❌ Error al eliminar factura'),
        ),
      );
      cargarFacturas();
    }
  }

  void verDetalleFactura(Factura factura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleFacturaScreen(factura: factura),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 2,
        title: const Text("📄 Facturas", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: mostrarFormularioFactura,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Factura",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : facturas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay facturas registradas',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarFacturas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: facturas.length,
                    itemBuilder: (context, index) {
                      final factura = facturas[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF2E7D32),
                            child:
                                Icon(Icons.receipt_long, color: Colors.white),
                          ),
                          title: Text(
                            'Factura #${factura.numeroFactura}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32)),
                          ),
                          subtitle: Text(
                            'Total: \$${factura.total.toStringAsFixed(2)}\nFecha: ${factura.fechaEmision ?? 'N/A'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.blueAccent),
                                onPressed: () => verDetalleFactura(factura),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    eliminarFactura(factura.id ?? 0),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// 🧾 Crear Factura
class CrearFacturaScreen extends StatefulWidget {
  final int idEmpresa;
  final int idVendedor;

  const CrearFacturaScreen({
    super.key,
    required this.idEmpresa,
    required this.idVendedor,
  });

  @override
  State<CrearFacturaScreen> createState() => _CrearFacturaScreenState();
}

class _CrearFacturaScreenState extends State<CrearFacturaScreen> {
  final FacturaService _service = FacturaService();

  List<ProductoDisponible> productosDisponibles = [];
  List<DetalleFactura> detalles = [];
  bool isLoading = true;
  double total = 0.0;
  int? siguienteNumeroFactura;

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarSiguienteNumeroFactura();
  }

  Future<void> cargarSiguienteNumeroFactura() async {
    final nextNumber =
        await _service.obtenerSiguienteNumeroFactura(widget.idEmpresa);
    setState(() => siguienteNumeroFactura = nextNumber);
  }

  Future<void> cargarProductos() async {
    setState(() => isLoading = true);
    final productos =
        await _service.obtenerProductosDisponibles(widget.idEmpresa);
    setState(() {
      productosDisponibles = productos;
      isLoading = false;
    });
  }

  void agregarProducto() {
    showDialog(
      context: context,
      builder: (context) => AgregarProductoDialog(
        productos: productosDisponibles,
        onAgregar: (detalle) {
          setState(() {
            detalles.add(detalle);
            calcularTotal();
          });
        },
      ),
    );
  }

  void calcularTotal() {
    total = detalles.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void eliminarDetalle(int index) {
    setState(() {
      detalles.removeAt(index);
      calcularTotal();
    });
  }

  Future<void> guardarFactura() async {
    if (detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    final factura = Factura(
      numeroFactura: '',
      idEmpresa: widget.idEmpresa,
      idVendedor: widget.idVendedor,
      total: total,
      detalles: detalles,
    );

    final result = await _service.crearFactura(factura);
    if (result['success'] == true) {
      final nuevoNumeroFactura = result['numero_factura'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ Factura #$nuevoNumeroFactura creada exitosamente'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text("Nueva Factura"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: guardarFactura),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: const Color(0xFFE8F5E9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              siguienteNumeroFactura == null
                                  ? 'Cargando número de factura...'
                                  : 'Próxima Factura: #${siguienteNumeroFactura!}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Productos",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: agregarProducto,
                        icon: const Icon(Icons.add),
                        label: const Text("Agregar"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  detalles.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("No hay productos agregados",
                                textAlign: TextAlign.center),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: detalles.length,
                          itemBuilder: (context, index) {
                            final detalle = detalles[index];
                            final producto = productosDisponibles.firstWhere(
                                (p) => p.id == detalle.idProducto);
                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(producto.nombrePlantas),
                                subtitle: Text(
                                    'Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${detalle.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          eliminarDetalle(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL:",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 🌿 Diálogo para agregar producto
class AgregarProductoDialog extends StatefulWidget {
  final List<ProductoDisponible> productos;
  final Function(DetalleFactura) onAgregar;

  const AgregarProductoDialog({
    super.key,
    required this.productos,
    required this.onAgregar,
  });

  @override
  State<AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<AgregarProductoDialog> {
  ProductoDisponible? productoSeleccionado;
  final TextEditingController _cantidadCtrl = TextEditingController();

  void agregar() {
    if (productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }

    if (cantidad > productoSeleccionado!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stock insuficiente. Disponible: ${productoSeleccionado!.stock}'),
        ),
      );
      return;
    }

    final detalle = DetalleFactura(
      idProducto: productoSeleccionado!.id,
      cantidad: cantidad,
      precioUnitario: productoSeleccionado!.precio,
      subtotal: cantidad * productoSeleccionado!.precio,
    );

    widget.onAgregar(detalle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Agregar Producto',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ProductoDisponible>(
            value: productoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Producto',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: widget.productos.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text('${p.nombrePlantas} (\$${p.precio})'),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              productoSeleccionado = value;
            }),
          ),
          const SizedBox(height: 15),
          if (productoSeleccionado != null)
            Text('Stock: ${productoSeleccionado!.stock}',
                style: TextStyle(
                    color: productoSeleccionado!.stock > 10
                        ? Colors.green
                        : Colors.orange)),
          const SizedBox(height: 15),
          TextField(
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: agregar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32)),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// 🌱 Detalle de Factura
class DetalleFacturaScreen extends StatefulWidget {
  final Factura factura;

  const DetalleFacturaScreen({super.key, required this.factura});

  @override
  State<DetalleFacturaScreen> createState() => _DetalleFacturaScreenState();
}

class _DetalleFacturaScreenState extends State<DetalleFacturaScreen> {
  final FacturaService _service = FacturaService();
  List<DetalleFactura> detalles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  Future<void> cargarDetalle() async {
    setState(() => isLoading = true);
    final data = await _service.obtenerDetalleFactura(widget.factura.id!);
    setState(() {
      detalles = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text('Factura #${widget.factura.numeroFactura}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Factura #${widget.factura.numeroFactura}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF2E7D32))),
                            const SizedBox(height: 8),
                            Text(
                                'Fecha: ${widget.factura.fechaEmision ?? 'N/A'}'),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detalle de Productos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final detalle = detalles[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(detalle.nombreProducto ?? 'Producto'),
                          subtitle: Text(
                              'Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}'),
                          trailing: Text(
                            '\$${detalle.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL:',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                              '\$${widget.factura.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
