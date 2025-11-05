// lib/core/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _ordersRef;

  OrderService() {
    _ordersRef = _firestore.collection('orders'); // Colección 'orders'
  }

  // Crear un nuevo pedido
  Future<void> createOrder({
    required String userId,
    required String username,
    required List<CartItem> cartItems,
    required double totalAmount,
  }) async {
    // 1. Convertir la lista de CartItem a un formato compatible con Firestore
    final List<Map<String, dynamic>> itemsList = cartItems
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            })
        .toList();

    // 2. Crear el documento del pedido
    try {
      await _ordersRef.add({
        'userId': userId,
        'username': username,
        'totalAmount': totalAmount,
        'status': 'Pendiente', // Estado inicial
        'items': itemsList,
        'orderDate': FieldValue.serverTimestamp(), // Marca de tiempo del servidor
      });
    } catch (e) {
      throw Exception('Error al crear el pedido: $e');
    }
  }

  // Obtener todos los pedidos en tiempo real (para el panel de administración, usado en AdminPage)
  Stream<QuerySnapshot> getAllOrdersStream() {
    return _ordersRef.orderBy('orderDate', descending: true).snapshots();
  }

  // Actualizar el estado de un pedido (usaremos esto después)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar el estado: $e');
    }
  }
}