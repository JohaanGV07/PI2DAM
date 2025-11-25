import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _ordersRef;

  OrderService() {
    _ordersRef = _firestore.collection('orders');
  }

  // Crear pedido con TRANSACCIÓN para restar stock de forma segura
  Future<void> createOrder({
    required String userId,
    required String username,
    required List<CartItem> cartItems,
    required double totalAmount,
    String? deliveryAddress, // Opcional: para guardar la dirección
  }) async {
    
    return _firestore.runTransaction((transaction) async {
      
      // 1. Leer todos los productos para comprobar stock actual
      for (var item in cartItems) {
        
        // *** PROTECCIÓN DE PREMIOS ***
        // Si es un premio (ID empieza por "prize_"), no tiene ficha en 'products',
        // así que nos saltamos la comprobación de stock.
        if (item.id.startsWith("prize_")) {
          continue; 
        }

        DocumentReference productRef = _firestore.collection('products').doc(item.id);
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("El producto '${item.name}' ya no existe en el catálogo.");
        }

        // Lectura segura del stock (si no existe el campo, asumimos 0)
        final data = productSnapshot.data() as Map<String, dynamic>;
        int currentStock = data['stock'] ?? 0;

        if (currentStock < item.quantity) {
          throw Exception("No hay suficiente stock de '${item.name}'. Quedan $currentStock.");
        }

        // 2. Restar el stock en la transacción
        transaction.update(productRef, {'stock': currentStock - item.quantity});
      }

      // 3. Crear el pedido
      final List<Map<String, dynamic>> itemsList = cartItems
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
              })
          .toList();

      DocumentReference newOrderRef = _ordersRef.doc(); // ID automático
      
      transaction.set(newOrderRef, {
        'userId': userId,
        'username': username,
        'totalAmount': totalAmount,
        'status': 'Pendiente',
        'items': itemsList,
        'deliveryAddress': deliveryAddress ?? 'Recoger en local',
        'orderDate': FieldValue.serverTimestamp(),
      });
    });
  }

  // Obtener todos los pedidos (para el panel de Admin)
  Stream<QuerySnapshot> getAllOrdersStream() {
    return _ordersRef.orderBy('orderDate', descending: true).snapshots();
  }

  // Actualizar estado del pedido (Admin)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error al actualizar estado: $e");
      throw Exception('Error al actualizar el estado');
    }
  }
}