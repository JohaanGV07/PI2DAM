// lib/core/providers/cart_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

// ---------------------------------------------
// 1. Modelo para los ítems del carrito
// ---------------------------------------------
class CartItem {
  final String id; // Usaremos el ID del producto
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

// ---------------------------------------------
// 2. El Provider (El "cerebro" del carrito)
// ---------------------------------------------
class CartProvider with ChangeNotifier {
  // Mapa privado de los ítems en el carrito
  // Usamos un Mapa para acceder fácilmente a los ítems por su ID
  final Map<String, CartItem> _items = {};

  // Getter público para obtener la lista de ítems
  List<CartItem> get items {
    return _items.values.toList();
  }

  // Getter para saber cuántos ítems únicos hay en el carrito
  int get itemCount {
    return _items.length;
  }

  // Getter para el precio total
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // --- Métodos para modificar el carrito ---

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      // Si ya está en el carrito, solo aumenta la cantidad
      _items.update(
        product.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1, // Aumenta en 1
        ),
      );
    } else {
      // Si es nuevo, lo añade al mapa
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          name: product.name,
          price: product.price,
          quantity: 1, // Cantidad inicial 1
        ),
      );
    }
    // ¡Importante! Avisa a todos los widgets que están escuchando
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      // Si hay más de 1, reduce la cantidad
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
      // Si solo queda 1, elimina el ítem completo
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    // Elimina el ítem completamente, sin importar la cantidad
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}