// lib/admin_manage_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';
import 'package:flutter_firestore_login/product_reviews_screen.dart'; // <-- 1. Importa la nueva pantalla

class AdminManageOrdersScreen extends StatefulWidget {
  const AdminManageOrdersScreen({super.key});

  @override
  State<AdminManageOrdersScreen> createState() => _AdminManageOrdersScreenState();
}

class _AdminManageOrdersScreenState extends State<AdminManageOrdersScreen> {
  final OrderService _orderService = OrderService();

  // (La función _showUpdateStatusDialog se queda exactamente igual)
  void _showUpdateStatusDialog(String orderId, String currentStatus) {
    String newStatus = currentStatus; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Actualizar Estado del Pedido"),
              content: DropdownButton<String>(
                value: newStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Pendiente', child: Text("Pendiente")),
                  DropdownMenuItem(value: 'En Preparación', child: Text("En Preparación")),
                  DropdownMenuItem(value: 'Listo', child: Text("Listo")),
                  DropdownMenuItem(value: 'Cancelado', child: Text("Cancelado")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      newStatus = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _orderService.updateOrderStatus(orderId, newStatus);
                    Navigator.pop(context);
                  },
                  child: const Text("Actualizar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Pedidos"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _orderService.getAllOrdersStream(),
        builder: (context, snapshot) {
          // ... (el código de waiting, error, y no data se queda igual)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar pedidos: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No hay pedidos para gestionar.", style: TextStyle(fontSize: 16)),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;
              
              final total = orderData['totalAmount'] ?? 0.0;
              final status = orderData['status'] ?? 'Desconocido';
              final username = orderData['username'] ?? 'Cliente N/A';
              final timestamp = orderData['orderDate'] as Timestamp?;
              
              final date = timestamp?.toDate();
              final dateString = date != null ? '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : 'Fecha N/A';

              // --- 2. Convertido a ExpansionTile ---
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Icon(_getStatusIcon(status), color: Colors.white),
                  ),
                  title: Text("Pedido de: $username"),
                  subtitle: Text("$dateString - Total: ${total.toStringAsFixed(2)} €"),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  ),
                  
                  // --- 3. Contenido expandido (Productos del pedido) ---
                  children: [
                    // Botón para cambiar el estado general del pedido
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text("Cambiar Estado del Pedido"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        onPressed: () {
                           _showUpdateStatusDialog(orderDoc.id, status);
                        },
                      ),
                    ),

                    // Lista de productos en el pedido
                    ...(orderData['items'] as List<dynamic>).map((item) {
                      final itemData = item as Map<String, dynamic>;
                      final productName = itemData['name'] ?? 'Producto';
                      final productId = itemData['id'] ?? '';

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.shopping_basket_outlined),
                        title: Text(productName),
                        subtitle: Text("${itemData['quantity']} x ${itemData['price']?.toStringAsFixed(2)}€"),
                        
                        // --- 4. Botón para ver reseñas de ESTE producto ---
                        trailing: IconButton(
                          icon: const Icon(Icons.reviews_outlined, color: Colors.blue),
                          tooltip: "Ver reseñas de $productName",
                          onPressed: () {
                            // Comprobamos que el producto tenga ID (pedidos antiguos quizás no)
                            if (productId.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Este producto no tiene ID (pedido antiguo)"))
                               );
                               return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductReviewsScreen(
                                  productId: productId,
                                  productName: productName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // (Las funciones _getStatusColor y _getStatusIcon se quedan igual)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente': return Colors.orange;
      case 'En Preparación': return Colors.blue;
      case 'Listo': return Colors.green;
      case 'Cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente': return Icons.watch_later_outlined;
      case 'En Preparación': return Icons.kitchen;
      case 'Listo': return Icons.check_circle_outline;
      case 'Cancelado': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }
}