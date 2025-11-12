import 'package:flutter/material.dart';

// (El resto de tus imports, como 'shared_preferences', 'dart:convert', etc.)
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// (La clase CartItem se queda exactamente igual)
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}

// ---------------------------------------------
// 2. El Provider (Actualizado)
// ---------------------------------------------
class CartProvider with ChangeNotifier {
  
  Map<String, CartItem> _items = {};

  // --- 2. Nuevas variables para Descuentos ---
  String? _appliedCouponCode;
  int _discountPercentage = 0;
  String _couponStatusMessage = '';

  CartProvider() {
    _loadCartFromPrefs();
  }

  // --- Getters (Modificados) ---
  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;
  String? get appliedCouponCode => _appliedCouponCode;
  String get couponStatusMessage => _couponStatusMessage;

  // El subtotal (precio antes de descuentos)
  double get subtotalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // El descuento calculado
  double get discountAmount {
    return subtotalAmount * (_discountPercentage / 100);
  }

  // El total final (con descuento)
  double get totalAmount {
    return subtotalAmount - discountAmount;
  }

  // --- Métodos del Carrito (Modificados) ---
  // (addItem, removeSingleItem, removeItem, clearCart)
  // Se modifican para que también reseteen el cupón si el carrito cambia.

  void addItem(ProductModel product) {
    // ... (lógica de añadir item se queda igual) ...
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    }
    _resetCoupon(); // <-- Resetea el cupón si se añaden items
    _saveCartToPrefs();
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    // ... (lógica de quitar item se queda igual) ...
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    _resetCoupon(); // <-- Resetea el cupón si se quitan items
    _saveCartToPrefs();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _resetCoupon(); // <-- Resetea el cupón
    _saveCartToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _resetCoupon(); // <-- Resetea el cupón
    _saveCartToPrefs();
    notifyListeners();
  }

  // --- 3. Nuevas Funciones de Cupones ---

  // Valida y aplica un cupón de Firestore
  Future<void> applyCoupon(String code) async {
    final codeTrimmed = code.trim().toUpperCase();
    if (codeTrimmed.isEmpty) {
      _couponStatusMessage = "Introduce un código.";
      notifyListeners();
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: codeTrimmed)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // No se encontró o no está activo
        _discountPercentage = 0;
        _appliedCouponCode = null;
        _couponStatusMessage = "Cupón no válido o expirado.";
      } else {
        // ¡Cupón encontrado!
        final couponData = query.docs.first.data();
        _discountPercentage = couponData['discountPercentage'] ?? 0;
        _appliedCouponCode = codeTrimmed;
        _couponStatusMessage = "¡${_discountPercentage}% de descuento aplicado!";
      }
    } catch (e) {
      _couponStatusMessage = "Error al validar el cupón.";
    }
    
    notifyListeners();
  }

  // Resetea el cupón (privado)
  void _resetCoupon() {
    _appliedCouponCode = null;
    _discountPercentage = 0;
    _couponStatusMessage = '';
  }

  // --- Funciones de Guardado/Carga (se quedan igual) ---
  Future<void> _saveCartToPrefs() async {
    // ... (tu código de saveCart se queda igual)
    final prefs = await SharedPreferences.getInstance();
    final cartMap = _items.map((key, item) => MapEntry(key, item.toMap()));
    final String cartString = json.encode(cartMap);
    await prefs.setString('cartItems', cartString);
  }

  Future<void> _loadCartFromPrefs() async {
    // ... (tu código de loadCart se queda igual)
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('cartItems')) return;
    final String? cartString = prefs.getString('cartItems');
    if (cartString == null) return;
    final Map<String, dynamic> cartMap = json.decode(cartString);
    _items = cartMap.map((key, itemData) => MapEntry(key, CartItem.fromMap(itemData)));
    notifyListeners();
  }
}