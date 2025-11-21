import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'price': price, 'quantity': quantity
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    id: map['id'], name: map['name'], price: map['price'], quantity: map['quantity']
  );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _appliedCouponCode;
  int _discountPercentage = 0;
  String _couponStatusMessage = '';
  // Guardamos la referencia del documento del cupón para marcarlo como usado al pagar
  DocumentReference? _appliedCouponRef; 

  CartProvider() {
    _loadCartFromPrefs();
  }

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  String? get appliedCouponCode => _appliedCouponCode;
  String get couponStatusMessage => _couponStatusMessage;

  double get subtotalAmount {
    var total = 0.0;
    _items.forEach((key, item) => total += item.price * item.quantity);
    return total;
  }
  double get discountAmount => subtotalAmount * (_discountPercentage / 100);
  double get totalAmount => subtotalAmount - discountAmount;

  // --- Añadir Producto (Soporta Gratis) ---
  void addItem(ProductModel product) {
    // Si es gratis (precio 0), generamos un ID único para que no se agrupe
    String productId = product.price == 0 ? "${product.id}_free_${DateTime.now().millisecondsSinceEpoch}" : product.id;

    if (_items.containsKey(productId)) {
      _items.update(productId, (existing) => CartItem(
        id: existing.id,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + 1,
      ));
    } else {
      _items.putIfAbsent(productId, () => CartItem(
        id: productId,
        name: product.name,
        price: product.price, // Será 0.0 si es premio
        quantity: 1,
      ));
    }
    _resetCoupon(); 
    _saveCartToPrefs();
    notifyListeners();
  }
  
  // (removeSingleItem, removeItem, clearCart se mantienen igual, llamando a _saveCartToPrefs)
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => CartItem(
          id: existing.id, name: existing.name, price: existing.price, quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    _saveCartToPrefs(); notifyListeners();
  }
  void removeItem(String id) { _items.remove(id); _saveCartToPrefs(); notifyListeners(); }
  void clearCart() { _items.clear(); _resetCoupon(); _saveCartToPrefs(); notifyListeners(); }


  // --- LÓGICA DE CUPONES AVANZADA ---
  Future<void> applyCoupon(String code, String userId) async {
    final codeTrimmed = code.trim().toUpperCase();
    _resetCoupon(); // Limpiamos previos

    if (codeTrimmed.isEmpty) {
      _couponStatusMessage = "Introduce un código.";
      notifyListeners();
      return;
    }

    try {
      // 1. Buscar en Cupones Personales (Mis Cupones)
      final personalQuery = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('my_coupons')
          .where('code', isEqualTo: codeTrimmed)
          .where('isUsed', isEqualTo: false)
          .limit(1).get();

      if (personalQuery.docs.isNotEmpty) {
        final data = personalQuery.docs.first.data();
        _setCoupon(codeTrimmed, data['discountPercentage'], personalQuery.docs.first.reference);
        return;
      }

      // 2. Buscar en Cupones Globales (Admin)
      final globalQuery = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: codeTrimmed)
          .where('isActive', isEqualTo: true)
          .limit(1).get();

      if (globalQuery.docs.isNotEmpty) {
        final doc = globalQuery.docs.first;
        final data = doc.data();
        
        // Comprobar si el usuario ya lo usó (Lista 'usedBy')
        List<dynamic> usedBy = data['usedBy'] ?? [];
        if (usedBy.contains(userId)) {
          _couponStatusMessage = "Ya has usado este cupón.";
        } else {
          _setCoupon(codeTrimmed, data['discountPercentage'], doc.reference);
        }
        return;
      }

      _couponStatusMessage = "Cupón no válido o expirado.";

    } catch (e) {
      _couponStatusMessage = "Error al validar: $e";
    }
    notifyListeners();
  }

  // Método auxiliar para aplicar los datos
  void _setCoupon(String code, int percent, DocumentReference ref) {
    _appliedCouponCode = code;
    _discountPercentage = percent;
    _appliedCouponRef = ref;
    _couponStatusMessage = "¡$percent% de descuento aplicado!";
    notifyListeners();
  }

  void _resetCoupon() {
    _appliedCouponCode = null;
    _discountPercentage = 0;
    _appliedCouponRef = null;
    _couponStatusMessage = '';
  }

  // --- Método para "Gastar" el cupón tras el checkout ---
  Future<void> markCouponAsUsed(String userId) async {
    if (_appliedCouponRef == null) return;

    try {
      // Si es personal (está en 'users/...')
      if (_appliedCouponRef!.path.contains('users')) {
        await _appliedCouponRef!.update({'isUsed': true});
      } 
      // Si es global (está en 'coupons/...')
      else {
        await _appliedCouponRef!.update({
          'usedBy': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      print("Error marcando cupón como usado: $e");
    }
    _resetCoupon();
  }

  // (Persistencia: _saveCartToPrefs y _loadCartFromPrefs se quedan igual)
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = json.encode(_items.map((k, v) => MapEntry(k, v.toMap())));
    await prefs.setString('cartItems', cartString);
  }
  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('cartItems')) return;
    final cartMap = json.decode(prefs.getString('cartItems')!);
    _items = cartMap.map<String, CartItem>((k, v) => MapEntry(k, CartItem.fromMap(v)));
    notifyListeners();
  }
}