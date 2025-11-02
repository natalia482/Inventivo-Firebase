import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart'; // Necesario para BuildContext
import 'package:inventivo/models/remision.dart'; 
import 'package:inventivo/core/utils/numberFormat.dart'; 

// Colores del tema (Definidos a partir de tu tema verde)
final PdfColor primaryColor = PdfColor.fromHex('2E7D32');
final PdfColor accentColor = PdfColor.fromHex('4CAF50'); 
final PdfColor lightGreen = PdfColor.fromHex('E8F5E9');

// 1. FUNCIÓN PRINCIPAL: Genera el documento completo.
Future<Uint8List> generateRemisionPdf(
  Remision remision, 
  List<DetalleRemision> detalles,
  String nombreEmpresa,  
  String direccionSede,  
  String telefonoSede,   
) async {
  final pdf = pw.Document(title: 'Remisión #${remision.numeroFactura}');
  
  final boldFont = await PdfGoogleFonts.nunitoExtraBold(); 
  final regularFont = await PdfGoogleFonts.nunitoExtraLight(); 
  
  // Datos de la Remisión
  final String clienteNombre = remision.nombreCliente ?? 'Cliente Final';
  final String clienteTelefono = remision.telefonoCliente ?? 'N/A';
  final String fecha = remision.fechaEmision?.substring(0, 10) ?? 'N/A';

  // ✅ VALIDACIÓN DE DATOS DE EMPRESA (Evita mostrar 'Cargando...' o vacíos)
  final String defaultText = 'Información No Disponible';
  final String empresaDisplay = (nombreEmpresa.isNotEmpty && nombreEmpresa != 'Cargando...') ? nombreEmpresa : defaultText;
  final String direccionDisplay = (direccionSede.isNotEmpty && direccionSede != 'Cargando...') ? direccionSede : 'Dirección No Especificada';
  final String telefonoDisplay = (telefonoSede.isNotEmpty && telefonoSede != 'N/A') ? 'Tel: $telefonoSede' : 'Teléfono No Especificado';


  // Cuerpo del PDF
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Caja Verde Oscuro con datos de la Empresa)
            pw.Container(
              color: primaryColor,
              padding: const pw.EdgeInsets.all(16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       // ✅ INFORMACIÓN DE LA EMPRESA
                       pw.Text(empresaDisplay, style: pw.TextStyle(fontSize: 24, font: boldFont, color: PdfColors.white)), 
                       pw.Text(direccionDisplay, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)), 
                       pw.Text(telefonoDisplay, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ]
                  ),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                          pw.Text('NOTA DE REMISIÓN', style: pw.TextStyle(fontSize: 18, font: boldFont, color: PdfColors.white)),
                          pw.Text('ID Vendedor: ${remision.idVendedor}', style: pw.TextStyle(fontSize: 10, color: PdfColors.white)), 
                      ]
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 2. DETALLES DE LA TRANSACCIÓN Y EL CLIENTE
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Info Remisión
                _buildInfoBox('N° REMISIÓN', remision.numeroFactura, boldFont, isPrimary: true),
                pw.SizedBox(width: 15),
                // Info Cliente
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: pw.BorderRadius.circular(5)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATOS DEL CLIENTE', style: pw.TextStyle(font: boldFont, fontSize: 10, color: accentColor)),
                        pw.Divider(height: 5, color: PdfColors.grey200),
                        pw.SizedBox(height: 5),
                        pw.Text('Nombre: $clienteNombre'),
                        pw.Text('Teléfono: $clienteTelefono'),
                        pw.Text('Fecha: $fecha'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 25),

            // 3. TÍTULO DE LA TABLA
            pw.Text('DETALLE DE PRODUCTOS', style: pw.TextStyle(fontSize: 14, font: boldFont, color: primaryColor)),
            pw.SizedBox(height: 10),

            // 4. Tabla de Detalles (Mejorada)
            _buildProductsTable(detalles, boldFont, regularFont),

            pw.Spacer(),

            // 5. TOTAL Y PIE DE PÁGINA
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                            pw.Text('Gracias por su compra.', style: pw.TextStyle(font: boldFont)),
                            pw.Text('Vendedor ID: ${remision.idVendedor}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                        ]
                    ),
                    // Caja de Total Final
                    pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: pw.BoxDecoration(
                            color: primaryColor, 
                            borderRadius: pw.BorderRadius.circular(8)
                        ),
                        child: pw.Text(
                            'TOTAL: ${formatCurrency(remision.total)}', 
                            style: pw.TextStyle(fontSize: 18, font: boldFont, color: PdfColors.white),
                        ),
                    ),
                ]
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// Widget Helper para la caja de información
pw.Widget _buildInfoBox(String title, String value, pw.Font boldFont, {bool isPrimary = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: isPrimary ? lightGreen : PdfColors.white,
      border: pw.Border.all(color: primaryColor, width: isPrimary ? 1.5 : 0.5),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 9, color: isPrimary ? primaryColor : PdfColors.black)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 18, color: isPrimary ? primaryColor : PdfColors.black)),
      ],
    ),
  );
}


// Helper para construir la tabla con filas alternas
pw.Widget _buildProductsTable(List<DetalleRemision> detalles, pw.Font boldFont, pw.Font regularFont) {
  final tableHeaders = ['Producto', 'Cantidad', 'P. Unitario', 'Subtotal'];
  
  final data = detalles.map((d) {
    return [
      d.nombreProducto ?? 'Producto N/A',
      d.cantidad.toString(),
      formatCurrency(d.precioUnitario),
      formatCurrency(d.subtotal),
    ];
  }).toList();

  return pw.Table.fromTextArray(
    headers: tableHeaders,
    data: data,
    cellStyle: pw.TextStyle(fontSize: 10, font: regularFont, color: PdfColors.black),
    headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: primaryColor),
    border: null, 
    rowDecoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
    ),
    cellDecoration: (context, row, column) { 
        if (row is int && row % 2 != 0) { 
            return pw.BoxDecoration(color: PdfColors.grey100);
        }
        return const pw.BoxDecoration();
    },
    columnWidths: {
      0: const pw.FlexColumnWidth(3.5),
      1: const pw.FlexColumnWidth(1.5),
      2: const pw.FlexColumnWidth(2.5),
      3: const pw.FlexColumnWidth(2.5),
    },
    // Añadir padding a las celdas
    cellAlignment: pw.Alignment.centerLeft,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
  );
}


// Funciones de impresión (Adaptadas para recibir los datos de la empresa)
Future<void> printRemision(
  BuildContext context, 
  Remision remision, 
  List<DetalleRemision> detalles,
  String nombreEmpresa,  
  String direccionSede,  
  String telefonoSede,   
) async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) => generateRemisionPdf(
      remision, 
      detalles, 
      nombreEmpresa, 
      direccionSede, 
      telefonoSede
    ),
  );
}

Future<void> shareRemision(
  Remision remision, 
  List<DetalleRemision> detalles,
  String nombreEmpresa,  
  String direccionSede,  
  String telefonoSede,   
) async {
  final bytes = await generateRemisionPdf(
    remision, 
    detalles, 
    nombreEmpresa, 
    direccionSede, 
    telefonoSede
  );
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'Remision_${remision.numeroFactura}.pdf',
  );
}