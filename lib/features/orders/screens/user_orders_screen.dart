// lib/features/orders/screens/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Asegúrate de que estos imports son correctos
import 'package:flutter_firestore_login/core/services/order_service.dart';
import 'package:flutter_firestore_login/shared/widgets/add_review_dialog.dart';


class UserOrdersScreen extends StatelessWidget {
  final String username;
  const UserOrdersScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // El OrderService no es necesario aquí si solo leemos
    // final OrderService _orderService = OrderService();

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

              // *** ¡AQUÍ ESTÁ LA LÓGICA CLAVE! ***
              // Usamos un ExpansionTile para mostrar los productos dentro
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Text((orders.length - index).toString()), // Numeración
                  ),
                  title: Text("Pedido del $dateString"),
                  subtitle: Text("Total: ${total.toStringAsFixed(2)} €"),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  
                  // --- ESTO SE MUESTRA AL EXPANDIR ---
                  children: [
                    // Mostramos los productos del pedido
                    ...(orderData['items'] as List<dynamic>).map((item) {
                      final itemData = item as Map<String, dynamic>;
                      return ListTile(
                        dense: true, // Más compacto
                        leading: const Icon(Icons.shopping_basket_outlined),
                        title: Text(itemData['name'] ?? 'Producto'),
                        subtitle: Text("${itemData['quantity']} x ${itemData['price']?.toStringAsFixed(2)}€"),
                        
                        // *** ¡EL BOTÓN DE VALORAR! ***
                        // Se muestra solo si el estado es el correcto
                        trailing: (status == 'Listo' || status == 'Entregado')
                            ? TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.amber.shade100,
                                ),
                                child: const Text('Valorar ⭐️'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddReviewDialog(
                                      // Pasamos el ID del producto (no del pedido)
                                      productId: itemData['id'],
                                      username: username,
                                    ),
                                  );
                                },
                              )
                            : null, // Si no está listo, no muestra nada
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
  
  // Función de ayuda para dar color al estado
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Preparación':
        return Colors.blue; // (Lo cambié de naranja a azul para diferenciar)
      case 'Listo':
        return Colors.green;
      case 'Entregado':
        return Colors.green.shade700;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}