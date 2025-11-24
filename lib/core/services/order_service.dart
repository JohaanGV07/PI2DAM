import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _ordersRef;

  OrderService() {
    _ordersRef = _firestore.collection('orders');
  }

  // Crear pedido con TRANSACCIÓN para restar stock
  Future<void> createOrder({
    required String userId,
    required String username,
    required List<CartItem> cartItems,
    required double totalAmount,
  }) async {
    
    // Usamos runTransaction para asegurar que el stock se resta correctamente
    // y que no vendemos más de lo que hay.
    return _firestore.runTransaction((transaction) async {
      
      // 1. Leer todos los productos para comprobar stock actual
      for (var item in cartItems) {
        // Si es un premio (ID empieza por "prize_"), saltamos la comprobación de stock
        if (item.id.startsWith("prize_")) continue;

        DocumentReference productRef = _firestore.collection('products').doc(item.id);
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("El producto ${item.name} ya no existe.");
        }

        int currentStock = productSnapshot.get('stock') ?? 0;
        if (currentStock < item.quantity) {
          throw Exception("No hay suficiente stock de ${item.name}. Quedan $currentStock.");
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

      DocumentReference newOrderRef = _ordersRef.doc(); // ID automático para el pedido
      transaction.set(newOrderRef, {
        'userId': userId,
        'username': username,
        'totalAmount': totalAmount,
        'status': 'Pendiente',
        'items': itemsList,
        'orderDate': FieldValue.serverTimestamp(),
      });
    });
  }

  // (Resto de funciones se mantienen igual)
  Stream<QuerySnapshot> getAllOrdersStream() {
    return _ordersRef.orderBy('orderDate', descending: true).snapshots();
  }

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