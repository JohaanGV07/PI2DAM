// lib/core/services/pdf_service.dart

import 'dart:typed_data'; // Corregido (para Uint8List)
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html; // Para la descarga web

class PdfService {

  // Función principal que genera y descarga el PDF
  Future<void> generateAndDownloadReceipt(Map<String, dynamic> orderData) async {
    final pdf = pw.Document();

    // Datos del pedido
    final orderId = orderData['id'] ?? 'N/A';
    final username = orderData['username'] ?? 'Cliente';
    final total = (orderData['totalAmount'] ?? 0.0).toStringAsFixed(2);
    final status = orderData['status'] ?? 'N/A';
    final items = orderData['items'] as List<dynamic>;

    // 1. Construir la página del PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Text("Recibo de Pedido - Cafetería", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              
              // Info del Pedido
              pw.Text("Cliente: $username"),
              pw.Text("Estado: $status"),
              pw.Text("ID del Pedido: $orderId"),
              pw.SizedBox(height: 20),

              // Tabla de Productos
              pw.Text("Productos:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Producto', 'Cant.', 'Precio Unit.', 'Total'],
                data: items.map((item) {
                  final itemData = item as Map<String, dynamic>;
                  final name = itemData['name'] ?? 'N/A';
                  final qty = (itemData['quantity'] ?? 0).toString();
                  final price = (itemData['price'] ?? 0.0).toStringAsFixed(2);
                  final itemTotal = ((itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 0)).toStringAsFixed(2);
                  return [name, qty, "$price €", "$itemTotal €"];
                }).toList(),
              ),
              
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Total Final
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL PAGADO: $total €",
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2. Guardar el PDF y preparar la descarga
    final bytes = await pdf.save();

    // 3. Usar 'universal_html' para la descarga en Web
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Creamos un enlace invisible y hacemos clic en él
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "recibo_pedido_$orderId.pdf")
      ..click();
      
    // Limpiamos la URL
    html.Url.revokeObjectUrl(url);
  }
}