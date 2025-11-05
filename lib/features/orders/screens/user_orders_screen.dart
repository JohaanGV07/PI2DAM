// lib/features/orders/screens/user_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';

class UserOrdersScreen extends StatelessWidget {
  // Necesitamos el username para filtrar los pedidos en Firestore
  final String username;

  const UserOrdersScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final OrderService _orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Usamos la referencia directa, ya que OrderService no tiene un método de filtrado por username específico
        // Filtramos: orders donde el campo 'username' sea igual al 'username' que tenemos.
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('username', isEqualTo: username)
            .orderBy('orderDate', descending: true) // Ordenar por fecha, el más nuevo arriba
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
              
              // Formatear la fecha (simple)
              final date = timestamp?.toDate();
              final dateString = date != null ? '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : 'Fecha N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(orders.length.toString()), // Número de pedido
                  ),
                  title: Text("Pedido del $dateString"),
                  subtitle: Text("Total: ${total.toStringAsFixed(2)} €"),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // TODO: Navegar a OrderDetailScreen (para ver la lista de items)
                  },
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
      case 'En Preparación': // Usamos el mismo color para simplificar
        return Colors.orange.shade700;
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