import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Alternar favorito (Añadir si no existe, Borrar si existe)
  Future<void> toggleFavorite(String userId, ProductModel product) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(product.id);

    final doc = await docRef.get();

    if (doc.exists) {
      // Si existe, lo borramos
      await docRef.delete();
    } else {
      // Si no existe, lo añadimos (guardamos datos básicos para mostrar la lista rápido)
      await docRef.set({
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Obtener stream de los IDs de favoritos (para saber cuál marcar en el catálogo)
  Stream<List<String>> getFavoriteIdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Obtener stream de los productos favoritos (para la pantalla Mis Favoritos)
  Stream<QuerySnapshot> getFavoritesListStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}