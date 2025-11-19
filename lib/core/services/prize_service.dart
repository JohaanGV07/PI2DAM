// lib/core/services/prize_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PrizeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Añade un premio a la subcolección del usuario
  Future<void> addPrizeToUser(String userId, String prizeName) async {
    print("INTENTANDO GUARDAR PREMIO: $prizeName para el usuario $userId"); // <-- LOG 1

    // No guardamos los premios "malos"
    if (prizeName.contains('Sigue intentando')) {
      print("El premio es 'Sigue intentando', no se guarda."); // <-- LOG 2
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
      
      print("¡Premio guardado con éxito en Firestore!"); // <-- LOG 3
      
    } catch (e) {
      print("Error CRÍTICO al guardar el premio: $e"); // <-- LOG DE ERROR
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