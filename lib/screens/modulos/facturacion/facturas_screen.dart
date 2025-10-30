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
    // Solo cargamos la lista de facturas. El número siguiente se carga en la pantalla de creación.
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
    // Cuando la pantalla de creación se cierre (pop), recargamos la lista de facturas
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
        title: const Text('Eliminar Factura'),
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
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Factura eliminada correctamente')),
        );
        cargarFacturas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al eliminar factura')),
        );
      }
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
      appBar: AppBar(
        title: const Text('📄 Facturas'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarFormularioFactura,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : facturas.isEmpty
              ? const Center(child: Text('No hay facturas registradas'))
              : RefreshIndicator(
                  onRefresh: cargarFacturas,
                  child: ListView.builder(
                    itemCount: facturas.length,
                    itemBuilder: (context, index) {
                      final factura = facturas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child:
                                const Icon(Icons.receipt, color: Colors.white),
                          ),
                          title: Text(
                            'Factura #${factura.numeroFactura}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Total: \$${factura.total.toStringAsFixed(2)}\nFecha: ${factura.fechaEmision ?? 'N/A'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.blue),
                                onPressed: () => verDetalleFactura(factura),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => eliminarFactura(factura.id!),
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

// Pantalla para crear factura
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
  int? siguienteNumeroFactura; // Estado para el número de factura

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarSiguienteNumeroFactura(); // Cargar el siguiente número
  }

  // Método para cargar el siguiente número de factura
  Future<void> cargarSiguienteNumeroFactura() async {
    final nextNumber =
        await _service.obtenerSiguienteNumeroFactura(widget.idEmpresa);
    setState(() {
      siguienteNumeroFactura = nextNumber;
    });
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
      numeroFactura: '', // El backend lo ignora y lo genera
      idEmpresa: widget.idEmpresa,
      idVendedor: widget.idVendedor,
      total: total,
      detalles: detalles,
    );

    final result = await _service.crearFactura(factura);

    if (result['success'] == true) {
      // Capturar el número de factura generado por el backend
      final nuevoNumeroFactura = result['numero_factura'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Factura #$nuevoNumeroFactura creada exitosamente'), // Usar el número capturado
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
      appBar: AppBar(
        title: const Text('Nueva Factura'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: guardarFactura,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: const Color(0xFFE8F5E9),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              siguienteNumeroFactura == null
                                  ? 'Cargando número de factura...'
                                  : 'Próxima Factura: #${siguienteNumeroFactura!}', // Muestra el número siguiente
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
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
                      const Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: agregarProducto,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (detalles.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No hay productos agregados',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detalles.length,
                      itemBuilder: (context, index) {
                        final detalle = detalles[index];
                        final producto = productosDisponibles.firstWhere(
                          (p) => p.id == detalle.idProducto,
                        );

                        return Card(
                          child: ListTile(
                            title: Text(producto.nombrePlantas),
                            subtitle: Text(
                              'Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${detalle.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => eliminarDetalle(index),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
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

// Dialog para agregar producto
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
            'Stock insuficiente. Disponible: ${productoSeleccionado!.stock}',
          ),
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
      title: const Text('Agregar Producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProductoDisponible>(
              value: productoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: widget.productos.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.nombrePlantas} (\$${p.precio})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => productoSeleccionado = value);
              },
            ),
            const SizedBox(height: 16),
            if (productoSeleccionado != null)
              Text(
                'Stock disponible: ${productoSeleccionado!.stock}',
                style: TextStyle(
                  color: productoSeleccionado!.stock > 10
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: agregar,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// Pantalla para ver detalle de factura
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
      appBar: AppBar(
        title: Text('Factura #${widget.factura.numeroFactura}'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura #${widget.factura.numeroFactura}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Fecha: ${widget.factura.fechaEmision ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detalle de Productos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final detalle = detalles[index];
                      return Card(
                        child: ListTile(
                          title: Text(detalle.nombreProducto ?? 'Producto'),
                          subtitle: Text(
                            'Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            '\$${detalle.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${widget.factura.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
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