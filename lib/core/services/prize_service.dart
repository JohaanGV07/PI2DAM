import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Para generar códigos aleatorios
import 'package:flutter/foundation.dart'; // <-- 1. Necesario para debugPrint

class PrizeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. LÓGICA DE LA RULETA ---
  
  // Añade un premio a la subcolección del usuario
  Future<void> addPrizeToUser(String userId, String prizeName) async {
    // No guardamos los premios "malos"
    if (prizeName.contains('Sigue intentando')) return; 

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('my_prizes')
          .add({
        'prizeName': prizeName,
        'awardedAt': FieldValue.serverTimestamp(),
        'isUsed': false,
      });
    } catch (e) {
      // 2. Usamos debugPrint en lugar de print
      debugPrint("Error al guardar el premio: $e");
    }
  }

  // --- 2. LÓGICA DE MIS PREMIOS ---

  // Obtiene el stream de premios de un usuario
  Stream<QuerySnapshot> getPrizesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_prizes')
        .where('isUsed', isEqualTo: false) // Solo los no usados
        .orderBy('awardedAt', descending: true)
        .snapshots();
  }

  // Marca un premio como usado (Para compatibilidad con tu código actual)
  Future<void> usePrize(String userId, String prizeId) async {
    await markPrizeAsRedeemed(userId, prizeId);
  }

  // --- 3. LÓGICA DE CUPONES Y CANJEO ---

  // Obtener stream de CUPONES del usuario
  Stream<QuerySnapshot> getUserCouponsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_coupons')
        .where('isUsed', isEqualTo: false)
        .snapshots();
  }

  // Convertir Premio en Cupón (y moverlo de colección)
  Future<void> convertPrizeToCoupon(String userId, String prizeId, String prizeName) async {
    // Extraer porcentaje
    int discount = 0;
    if (prizeName.contains('10%')) discount = 10;
    if (prizeName.contains('5%')) discount = 5;
    if (prizeName.contains('20%')) discount = 20;

    if (discount == 0) return;

    // Generar código único
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final String randomCode = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    final String finalCode = 'GANADO-$discount-$randomCode';

    final batch = _firestore.batch();

    // Crear cupón
    final newCouponRef = _firestore.collection('users').doc(userId).collection('my_coupons').doc();
    batch.set(newCouponRef, {
      'code': finalCode,
      'discountPercentage': discount,
      'isUsed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'Ruleta',
    });

    // Marcar premio original como usado
    final prizeRef = _firestore.collection('users').doc(userId).collection('my_prizes').doc(prizeId);
    batch.update(prizeRef, {'isUsed': true});

    await batch.commit();
  }

  // Marcar premio como canjeado (Producto Gratis)
  Future<void> markPrizeAsRedeemed(String userId, String prizeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('my_prizes')
          .doc(prizeId)
          .update({'isUsed': true});
    } catch (e) {
      // 2. Usamos debugPrint en lugar de print
      debugPrint("Error al usar el premio: $e");
    }
  }
}