import 'package:flutter/material.dart';
import 'package:inventivo/models/remision.dart'; 
import 'package:inventivo/services/remisiones_service.dart';

class RemisionesScreen extends StatefulWidget { 
  final int idSede; // Modificado
  final int idVendedor;

  const RemisionesScreen({ 
    super.key,
    required this.idSede, // Modificado
    required this.idVendedor,
  });

  @override
  State<RemisionesScreen> createState() => _RemisionesScreenState();
}

class _RemisionesScreenState extends State<RemisionesScreen> {
  final RemisionService _service = RemisionService(); 
  List<Remision> remisiones = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarRemisiones();
  }

  Future<void> cargarRemisiones() async { 
    setState(() => isLoading = true);
    final data = await _service.listarRemisiones(widget.idSede); // Modificado
    setState(() {
      remisiones = data; 
      isLoading = false;
    });
  }

  void mostrarFormularioRemision() { 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearRemisionScreen( 
          idSede: widget.idSede, // Modificado
          idVendedor: widget.idVendedor,
        ),
      ),
    ).then((_) => cargarRemisiones());
  }

  Future<void> eliminarRemision(int id) async { 
    final confirmar = await showDialog<bool?>( // Aceptar bool?
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Remisión'),
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

    if (confirmar == true) { // Manejo seguro de bool?
      final result = await _service.eliminarRemision(id); 
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Remisión eliminada correctamente')),
        );
        cargarRemisiones();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al eliminar remisión')),
        );
      }
    }
  }

  void verDetalleRemision(Remision remision) { 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRemisionScreen(remision: remision), 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 Remisiones'), 
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarFormularioRemision,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Remisión'), 
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : remisiones.isEmpty
              ? const Center(child: Text('No hay remisiones registradas'))
              : RefreshIndicator(
                  onRefresh: cargarRemisiones,
                  child: ListView.builder(
                    itemCount: remisiones.length,
                    itemBuilder: (context, index) {
                      final remision = remisiones[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.receipt, color: Colors.white),
                          ),
                          title: Text(
                            // Si el número de factura no se corrige en el modelo, seguirá apareciendo Remisión #
                            'Remisión #${remision.numeroFactura}', 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Total: \$${remision.total.toStringAsFixed(2)}\nFecha: ${remision.fechaEmision ?? 'N/A'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.blue),
                                onPressed: () => verDetalleRemision(remision),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => eliminarRemision(remision.id!),
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

// Pantalla para crear remisión
class CrearRemisionScreen extends StatefulWidget { 
  final int idSede; // Modificado
  final int idVendedor;

  const CrearRemisionScreen({ 
    super.key,
    required this.idSede, // Modificado
    required this.idVendedor,
  });

  @override
  State<CrearRemisionScreen> createState() => _CrearRemisionScreenState();
}

class _CrearRemisionScreenState extends State<CrearRemisionScreen> {
  final RemisionService _service = RemisionService(); 
  
  List<ProductoDisponible> productosDisponibles = [];
  List<DetalleRemision> detalles = []; // Modificado
  bool isLoading = true;
  double total = 0.0;
  int? siguienteNumeroRemision; 

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarSiguienteNumeroRemision(); 
  }

  Future<void> cargarSiguienteNumeroRemision() async { 
    final nextNumber =
        await _service.obtenerSiguienteNumeroFactura(widget.idSede); // Modificado
    setState(() {
      siguienteNumeroRemision = nextNumber;
    });
  }

  Future<void> cargarProductos() async {
    setState(() => isLoading = true);
    final productos =
        await _service.obtenerProductosDisponibles(widget.idSede); // Modificado
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
            detalles.add(detalle as DetalleRemision); // Modificado
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

  Future<void> guardarRemision() async { // Renombrado
    if (detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    final remision = Remision( 
      numeroFactura: '', // El backend lo genera
      idSede: widget.idSede, // Modificado
      idVendedor: widget.idVendedor,
      total: total,
      detalles: detalles,
    );

    final result = await _service.crearRemision(remision); // Modificado

    if (result['success'] == true) {
      final nuevoNumeroFactura = result['numero_factura'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Remisión #$nuevoNumeroFactura creada exitosamente'), 
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
        title: const Text('Nueva Remisión'), // Título actualizado
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: guardarRemision,
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
                              siguienteNumeroRemision == null
                                  ? 'Cargando número de remisión...'
                                  : 'Próxima Remisión: #${siguienteNumeroRemision!}', 
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
  final Function(DetalleRemision) onAgregar; // Modificado

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

    final detalle = DetalleRemision( // Modificado
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

// Pantalla para ver detalle de remisión
class DetalleRemisionScreen extends StatefulWidget { // Renombrado
  final Remision remision; // Modificado

  const DetalleRemisionScreen({super.key, required this.remision});

  @override
  State<DetalleRemisionScreen> createState() => _DetalleRemisionScreenState();
}

class _DetalleRemisionScreenState extends State<DetalleRemisionScreen> {
  final RemisionService _service = RemisionService(); // Modificado
  List<DetalleRemision> detalles = []; // Modificado
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  Future<void> cargarDetalle() async {
    setState(() => isLoading = true);
    final data = await _service.obtenerDetalleRemision(widget.remision.id!); // Modificado
    setState(() {
      detalles = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remisión #${widget.remision.numeroFactura}'), // Título actualizado
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
                            'Remisión #${widget.remision.numeroFactura}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Fecha: ${widget.remision.fechaEmision ?? 'N/A'}'),
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
                          // La corrección aquí nos ayuda a ver si el nombre del producto es el problema:
                          title: Text(
                            detalle.nombreProducto ?? 'Producto sin nombre (ID: ${detalle.idProducto})',
                          ),
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
                            '\$${widget.remision.total.toStringAsFixed(2)}',
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