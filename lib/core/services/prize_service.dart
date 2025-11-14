import 'package:cloud_firestore/cloud_firestore.dart';

class PrizeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Añade un premio a la subcolección del usuario
  Future<void> addPrizeToUser(String userId, String prizeName) async {
    // No guardamos los premios "malos"
    if (prizeName.contains('Sigue intentando')) {
      return; 
    }

    try {
      // Referencia a la subcolección 'my_prizes' del usuario
      final prizeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('my_prizes');
          
      await prizeRef.add({
        'prizeName': prizeName,
        'awardedAt': FieldValue.serverTimestamp(), // Fecha en que se ganó
        'isUsed': false, // Marcado como no usado
      });
      
    } catch (e) {
      print("Error al guardar el premio: $e");
    }
  }

  // Obtiene el stream de premios de un usuario
  Stream<QuerySnapshot> getPrizesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_prizes')
        .where('isUsed', isEqualTo: false) // Mostramos solo los no usados
        .orderBy('awardedAt', descending: true)
        .snapshots();
  }

  // (Función futura para marcar un premio como usado)
  Future<void> usePrize(String userId, String prizeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('my_prizes')
          .doc(prizeId)
          .update({'isUsed': true});
    } catch (e) {
      print("Error al usar el premio: $e");
    }
  }
}