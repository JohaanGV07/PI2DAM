import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Para generar códigos aleatorios

class PrizeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Añadir premio (desde la ruleta) - SE MANTIENE IGUAL
  Future<void> addPrizeToUser(String userId, String prizeName) async {
    if (prizeName.contains('Sigue intentando')) return; 

    try {
      await _firestore.collection('users').doc(userId).collection('my_prizes').add({
        'prizeName': prizeName,
        'awardedAt': FieldValue.serverTimestamp(),
        'isUsed': false,
      });
    } catch (e) {
      print("Error al guardar el premio: $e");
    }
  }

  // Obtener stream de premios - SE MANTIENE IGUAL
  Stream<QuerySnapshot> getPrizesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_prizes')
        .where('isUsed', isEqualTo: false)
        .orderBy('awardedAt', descending: true)
        .snapshots();
  }

  // --- NUEVO: Obtener stream de CUPONES del usuario ---
  Stream<QuerySnapshot> getUserCouponsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_coupons') // Nueva subcolección
        .where('isUsed', isEqualTo: false)
        .snapshots();
  }

  // --- NUEVO: Convertir Premio en Cupón ---
  Future<void> convertPrizeToCoupon(String userId, String prizeId, String prizeName) async {
    // 1. Extraer el porcentaje del texto (ej: "10% DTO" -> 10)
    int discount = 0;
    if (prizeName.contains('10%')) discount = 10;
    if (prizeName.contains('5%')) discount = 5;
    if (prizeName.contains('20%')) discount = 20;

    if (discount == 0) return; // No es un cupón válido

    // 2. Generar un código único
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final String randomCode = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    final String finalCode = 'GANADO-$discount-$randomCode'; // Ej: GANADO-10-A1B2C3

    final batch = _firestore.batch();

    // 3. Crear el cupón en la colección personal del usuario
    final newCouponRef = _firestore.collection('users').doc(userId).collection('my_coupons').doc();
    batch.set(newCouponRef, {
      'code': finalCode,
      'discountPercentage': discount,
      'isUsed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'Ruleta',
    });

    // 4. Marcar el premio original como usado (borrado lógico)
    final prizeRef = _firestore.collection('users').doc(userId).collection('my_prizes').doc(prizeId);
    batch.update(prizeRef, {'isUsed': true});

    await batch.commit();
  }

  // --- NUEVO: Marcar premio como canjeado (Producto Gratis) ---
  Future<void> markPrizeAsRedeemed(String userId, String prizeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('my_prizes')
        .doc(prizeId)
        .update({'isUsed': true});
  }
}