// lib/admin_manage_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';

class AdminManageOrdersScreen extends StatefulWidget {
  const AdminManageOrdersScreen({super.key});

  @override
  State<AdminManageOrdersScreen> createState() => _AdminManageOrdersScreenState();
}

class _AdminManageOrdersScreenState extends State<AdminManageOrdersScreen> {
  final OrderService _orderService = OrderService();

  // Función para mostrar el diálogo de cambio de estado
  void _showUpdateStatusDialog(String orderId, String currentStatus) {
    String newStatus = currentStatus; // Estado seleccionado por defecto

    showDialog(
      context: context,
      builder: (context) {
        // Usamos un StatefulBuilder para que el Dropdown cambie visualmente
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
        // Usamos el método del servicio para obtener TODOS los pedidos
        stream: _orderService.getAllOrdersStream(),
        builder: (context, snapshot) {
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

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
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
                  // Al tocar el pedido, se abre el diálogo
                  onTap: () {
                    _showUpdateStatusDialog(orderDoc.id, status);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Funciones de ayuda para los colores e iconos del estado
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Preparación':
        return Colors.blue;
      case 'Listo':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente':
        return Icons.watch_later_outlined;
      case 'En Preparación':
        return Icons.kitchen;
      case 'Listo':
        return Icons.check_circle_outline;
      case 'Cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}