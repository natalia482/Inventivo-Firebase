import 'package:flutter/material.dart';
import 'package:inventivo/models/remision.dart'; 
import 'package:inventivo/services/remisiones_service.dart';
import 'package:inventivo/core/utils/remision_pdf_generator.dart';
import 'package:inventivo/models/remision.dart'; // Importación de modelos (DetalleRemision, ProductoDisponible)

// 1. CLASE RemisionesScreen (Recibe la info de PlantasPage)
class RemisionesScreen extends StatefulWidget { 
  final int idSede; 
  final int idVendedor;
  final String? userRole; 
  final String nombreEmpresa; 
  final String direccionSede; 
  final String telefonoSede;

  const RemisionesScreen({ 
    super.key,
    required this.idSede, 
    required this.idVendedor,
    this.userRole, 
    required this.nombreEmpresa, // ✅ Parámetro requerido
    required this.direccionSede, // ✅ Parámetro requerido
    required this.telefonoSede,  // ✅ Parámetro requerido
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
    final data = await _service.listarRemisiones(widget.idSede); 
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
          idSede: widget.idSede, 
          idVendedor: widget.idVendedor,
        ),
      ),
    ).then((_) => cargarRemisiones());
  }
  
  Future<void> eliminarRemision(int id) async { 
    // Lógica de eliminación (omito para brevedad)
    final confirmar = await showDialog<bool?>( 
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Remisión'),
        content: const Text('¿Estás seguro? Esta acción devolverá el stock de los productos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar == true) { 
      final result = await _service.eliminarRemision(id, widget.idVendedor, widget.idSede); 
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Remisión eliminada correctamente')),);
        cargarRemisiones();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error al eliminar remisión')),);
      }
    }
  }

  // ✅ CORRECCIÓN CLAVE: Propagar la información de la empresa/sede
  void verDetalleRemision(Remision remision) { 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRemisionScreen(
            remision: remision, 
            nombreEmpresa: widget.nombreEmpresa, 
            direccionSede: widget.direccionSede, 
            telefonoSede: widget.telefonoSede,
        ), 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedRole = widget.userRole?.toUpperCase() ?? '';
    final bool canCreate = normalizedRole == 'PROPIETARIO' || normalizedRole == 'ADMINISTRADOR' || normalizedRole == 'TRABAJADOR'; 
    final bool canDelete = normalizedRole == 'PROPIETARIO' || normalizedRole == 'ADMINISTRADOR'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas de Remisiones'),
        foregroundColor: const Color(0xFFFFFFFF), 
        backgroundColor: const Color(0xFF265A27),
      ),
      floatingActionButton: canCreate ? FloatingActionButton.extended(
        onPressed: mostrarFormularioRemision,
        backgroundColor: const Color(0xFF265A27),
        foregroundColor: const Color(0xFFFFFFFF),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Remisión'), 
      ) : null,
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
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6,),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: const Color(0xFF265A27), child: const Icon(Icons.receipt, color: Colors.white),),
                          title: Text('Remisión #${remision.numeroFactura}', style: const TextStyle(fontWeight: FontWeight.bold),),
                          subtitle: Text('Total: \$${remision.total.toStringAsFixed(2)}\nFecha: ${remision.fechaEmision ?? 'N/A'}',),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => verDetalleRemision(remision),),
                              if (canDelete)
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => eliminarRemision(remision.id!),),
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

// Pantalla para crear remisión (se mantiene para completitud)
class CrearRemisionScreen extends StatefulWidget { 
  final int idSede; 
  final int idVendedor;

  const CrearRemisionScreen({ 
    super.key,
    required this.idSede, 
    required this.idVendedor,
  });

  @override
  State<CrearRemisionScreen> createState() => _CrearRemisionScreenState();
}

class _CrearRemisionScreenState extends State<CrearRemisionScreen> {
  final RemisionService _service = RemisionService(); 
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _nombreClienteCtrl = TextEditingController();
  final TextEditingController _telefonoClienteCtrl = TextEditingController();
  List<ProductoDisponible> productosDisponibles = [];
  List<DetalleRemision> detalles = []; 
  bool isLoading = true;
  double total = 0.0;
  int? siguienteNumeroRemision; 

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarSiguienteNumeroRemision(); 
  }
  // ... (resto de CrearRemisionScreen omitido por ser código de input)
  Future<void> cargarSiguienteNumeroRemision() async { 
    final nextNumber = await _service.obtenerSiguienteNumeroFactura(widget.idSede); 
    setState(() {
      siguienteNumeroRemision = nextNumber;
    });
  }

  Future<void> cargarProductos() async {
    setState(() => isLoading = true);
    final productos = await _service.obtenerProductosDisponibles(widget.idSede); 
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
            detalles.add(detalle as DetalleRemision); 
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
  
  Future<void> guardarRemision() async { 
    if (!_formKey.currentState!.validate()) return; 
    if (detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto')),);
      return;
    }
    
    final remision = Remision( 
      numeroFactura: '', 
      idSede: widget.idSede, 
      idVendedor: widget.idVendedor,
      total: total,
      nombreCliente: _nombreClienteCtrl.text, 
      telefonoCliente: _telefonoClienteCtrl.text, 
      detalles: detalles,
    );
    
    final result = await _service.crearRemision(remision, widget.idVendedor); 

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Remisión creada exitosamente')),);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${result['message']}')),);
    }
  }

  Widget _buildInput(TextEditingController ctrl, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Remisión'), 
        backgroundColor: const Color(0xFF265A27),
        foregroundColor: const Color(0xFFFFFFFF),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: guardarRemision,),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form( 
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Datos del Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    _buildInput(_nombreClienteCtrl, 'Nombre del Cliente'),
                    _buildInput(_telefonoClienteCtrl, 'Teléfono del Cliente', type: TextInputType.phone),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFFE8F5E9),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(siguienteNumeroRemision == null ? 'Cargando número de remisión...' : 'Próxima Remisión: #${siguienteNumeroRemision!}', 
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),),
                        ElevatedButton.icon(
                          onPressed: agregarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF265A27), foregroundColor: Color(0xFFFFFFFF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (detalles.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No hay productos agregados', textAlign: TextAlign.center,),))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detalles.length,
                        itemBuilder: (context, index) {
                          final detalle = detalles[index];
                          final producto = productosDisponibles.firstWhere((p) => p.id == detalle.idProducto,);
                          return Card(
                            child: ListTile(
                              title: Text(producto.nombrePlantas),
                              subtitle: Text('Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}',),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${detalle.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => eliminarDetalle(index),),
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
                            const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green,),),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Dialog para agregar producto (se mantiene para completitud)
class AgregarProductoDialog extends StatefulWidget {
  final List<ProductoDisponible> productos;
  final Function(DetalleRemision) onAgregar; 

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un producto')),);
      return;
    }

    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;

    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida')),);
      return;
    }

    if (cantidad > productoSeleccionado!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock insuficiente. Disponible: ${productoSeleccionado!.stock}'),),);
      return;
    }

    final detalle = DetalleRemision( 
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
              decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder(),),
              items: widget.productos.map((p) {
                return DropdownMenuItem(value: p, child: Text('${p.nombrePlantas} (\$${p.precio})'),);
              }).toList(),
              onChanged: (value) {setState(() => productoSeleccionado = value);},
            ),
            const SizedBox(height: 16),
            if (productoSeleccionado != null)
              Text('Stock disponible: ${productoSeleccionado!.stock}',
                style: TextStyle(
                  color: productoSeleccionado!.stock > 10 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder(),),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'),),
        ElevatedButton(onPressed: agregar, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF265A27), foregroundColor: Color(0xFFFFFFFF)), child: const Text('Agregar'),),
      ],
    );
  }
}

// 2. CLASE DetalleRemisionScreen (Recibe la información de la Empresa/Sede)
class DetalleRemisionScreen extends StatefulWidget { 
  final Remision remision;
  final String nombreEmpresa; 
  final String direccionSede; 
  final String telefonoSede;

  const DetalleRemisionScreen({
    super.key, 
    required this.remision,
    required this.nombreEmpresa, 
    required this.direccionSede, 
    required this.telefonoSede,
  });

  @override
  State<DetalleRemisionScreen> createState() => _DetalleRemisionScreenState();
}

class _DetalleRemisionScreenState extends State<DetalleRemisionScreen> {
  final RemisionService _service = RemisionService(); 
  List<DetalleRemision> detalles = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  Future<void> cargarDetalle() async {
    setState(() => isLoading = true);
    final data = await _service.obtenerDetalleRemision(widget.remision.id!); 
    setState(() {
      detalles = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definimos la condición de visibilidad para el botón
    final bool canPrint = !isLoading && detalles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Remisión #${widget.remision.numeroFactura}'), 
        backgroundColor: const Color(0xFF265A27),
        foregroundColor: const Color(0xFFFFFFFF),
        actions: [
            // ✅ UBICACIÓN DEL BOTÓN DE IMPRIMIR
            if (canPrint) 
                IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'Imprimir / Compartir Remisión',
                    onPressed: () {
                        // Llama a la función que genera y comparte el PDF
                        shareRemision(
                            widget.remision, 
                            detalles,
                            widget.nombreEmpresa, 
                            widget.direccionSede, 
                            widget.telefonoSede, 
                        );
                    },
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remisión #${widget.remision.numeroFactura}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                          const SizedBox(height: 8),
                          Text('Cliente: ${widget.remision.nombreCliente ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('Teléfono: ${widget.remision.telefonoCliente ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Fecha: ${widget.remision.fechaEmision ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detalle de Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    itemBuilder: (context, index) {
                      final detalle = detalles[index];
                      return Card(
                        child: ListTile(
                          title: Text(detalle.nombreProducto ?? 'Producto sin nombre (ID: ${detalle.idProducto})',),
                          subtitle: Text('Cantidad: ${detalle.cantidad} x \$${detalle.precioUnitario.toStringAsFixed(2)}',),
                          trailing: Text('\$${detalle.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),),
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
                          const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                          Text('\$${widget.remision.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green,),),
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