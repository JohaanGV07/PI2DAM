// lib/core/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // La función principal que usa una transacción
  Future<void> addReview({
    required String productId,
    required String username,
    required double rating,
    required String comment,
  }) async {
    // 1. Referencia al documento del producto
    final productRef = _firestore.collection('products').doc(productId);
    
    // 2. Referencia a la nueva reseña (en la subcolección)
    final reviewRef = productRef.collection('reviews').doc(); // ID automático

    try {
      // 3. Ejecutar la transacción
      await _firestore.runTransaction((transaction) async {
        // Obtenemos los datos actuales del producto
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw Exception("El producto no existe");
        }
        
        // Obtenemos los contadores actuales
        final currentData = productSnapshot.data()!;
        int currentRatingCount = currentData['ratingCount'] ?? 0;
        double currentRatingAvg = (currentData['ratingAvg'] ?? 0.0).toDouble();

        // Calculamos la nueva media
        double newRatingAvg = 
            ((currentRatingAvg * currentRatingCount) + rating) / (currentRatingCount + 1);
        int newRatingCount = currentRatingCount + 1;

        // 4. Escribir la nueva reseña en la subcolección
        transaction.set(reviewRef, {
          'username': username,
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // 5. Actualizar el documento principal del producto
        transaction.update(productRef, {
          'ratingAvg': newRatingAvg,
          'ratingCount': newRatingCount,
        });
      });
    } catch (e) {
      throw Exception('Error al añadir la reseña: $e');
    }
  }
}