// lib/features/orders/screens/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Asegúrate de que estas rutas de import son correctas
import 'package:flutter_firestore_login/core/services/order_service.dart';
import 'package:flutter_firestore_login/shared/widgets/add_review_dialog.dart';

class UserOrdersScreen extends StatelessWidget {
  final String username;
  // --- 1. AÑADIDO: La variable de clase para userId ---
  final String userId; 
  
  const UserOrdersScreen({
    super.key,
    required this.username,
    // --- 2. CORREGIDO: El constructor ahora usa "this.userId" ---
    required this.userId, 
  });

  @override
  Widget build(BuildContext context) {
    // Esta línea la tenías, la dejamos aunque el Stream no la use
    final OrderService _orderService = OrderService();

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Pedidos")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('username', isEqualTo: username)
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
              final orderData = orders[index].data() as Map<String, dynamic>;
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
                                      username: username,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
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