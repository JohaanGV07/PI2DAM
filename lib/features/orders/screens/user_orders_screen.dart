// lib/features/orders/screens/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. Imports necesarios ---
import 'package:flutter_firestore_login/core/services/pdf_service.dart'; // El servicio PDF
import 'package:flutter_firestore_login/shared/widgets/add_review_dialog.dart';
// (El OrderService no es estrictamente necesario aquí si solo leemos)
// import 'package:flutter_firestore_login/core/services/order_service.dart';


// --- 2. Convertido a StatefulWidget ---
class UserOrdersScreen extends StatefulWidget {
  final String username;
  final String userId; 

  const UserOrdersScreen({
    super.key,
    required this.username,
    required this.userId, 
  });

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  
  // --- 3. Instancia del servicio y estado de carga ---
  final PdfService _pdfService = PdfService();
  bool _isGeneratingPdf = false;
  String? _loadingOrderId; // Para saber qué pedido se está generando

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Pedidos")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('username', isEqualTo: widget.username) // <-- Usa widget.username
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar pedidos: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Todavía no has realizado ningún pedido.", style: TextStyle(fontSize: 16)),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index]; // Obtenemos el documento
              final orderData = orderDoc.data() as Map<String, dynamic>;
              // Añadimos el ID al mapa de datos para el PDF
              orderData['id'] = orderDoc.id; 

              final total = orderData['totalAmount'] ?? 0.0;
              final status = orderData['status'] ?? 'Desconocido';
              final timestamp = orderData['orderDate'] as Timestamp?;
              
              final date = timestamp?.toDate();
              final dateString = date != null ? '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : 'Fecha N/A';

              final bool isExpandable = (status == 'Listo' || status == 'Entregado');
              
              final leadingIcon = CircleAvatar(
                backgroundColor: _getStatusColor(status),
                child: Text((orders.length - index).toString()), // Numeración
              );
              final titleText = Text("Pedido del $dateString");
              final subtitleText = Text("Total: ${total.toStringAsFixed(2)} €");
              final trailingChip = Chip(
                label: Text(status),
                backgroundColor: _getStatusColor(status),
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: isExpandable
                    // SI ESTÁ LISTO: Devolvemos el ExpansionTile
                    ? ExpansionTile(
                        leading: leadingIcon,
                        title: titleText,
                        subtitle: subtitleText,
                        trailing: trailingChip,
                        children: [
                          // Mostramos los productos del pedido
                          ...(orderData['items'] as List<dynamic>).map((item) {
                            final itemData = item as Map<String, dynamic>;
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.shopping_basket_outlined),
                              title: Text(itemData['name'] ?? 'Producto'),
                              subtitle: Text("${itemData['quantity']} x ${itemData['price']?.toStringAsFixed(2)}€"),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.amber.shade100,
                                ),
                                child: const Text('Valorar ⭐️'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddReviewDialog(
                                      productId: itemData['id'],
                                      username: widget.username,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),

                          // --- 4. AÑADIDO: Botón de Descargar Recibo ---
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            // Comprobamos si este pedido en concreto se está generando
                            child: (_isGeneratingPdf && _loadingOrderId == orderDoc.id)
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : TextButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  label: const Text("Descargar Recibo", style: TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    setState(() {
                                      _isGeneratingPdf = true;
                                      _loadingOrderId = orderDoc.id; // Marcamos este pedido
                                    });
                                    try {
                                      // Pasamos el mapa de datos completo
                                      await _pdfService.generateAndDownloadReceipt(orderData);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error al generar PDF: $e"))
                                      );
                                    }
                                    setState(() {
                                      _isGeneratingPdf = false;
                                      _loadingOrderId = null; // Limpiamos
                                    });
                                  },
                                ),
                          )
                        ],
                      )
                    // SI ESTÁ PENDIENTE: Devolvemos un ListTile normal
                    : ListTile(
                        leading: leadingIcon,
                        title: titleText,
                        subtitle: subtitleText,
                        trailing: trailingChip,
                      ),
              );
            },
          );
        },
      ),
    );
  }
  
  // (La función _getStatusColor se queda igual)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente': return Colors.orange;
      case 'En Preparación': return Colors.blue; 
      case 'Listo': return Colors.green;
      case 'Entregado': return Colors.green.shade700;
      case 'Cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }
}