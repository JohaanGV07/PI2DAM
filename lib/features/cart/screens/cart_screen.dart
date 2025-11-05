// lib/features/cart/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/features/cart/screens/checkout_screen.dart';

import '../../../core/models/product_model.dart';

class CartScreen extends StatelessWidget {
  final String username;
  const CartScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos la instancia del CartProvider
    // Esta vez 'listen' es true (por defecto) porque queremos que la UI
    // se reconstruya si el carrito cambia.
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Carrito"),
        actions: [
          // Botón para vaciar el carrito
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              // Mostramos un diálogo de confirmación
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirmar'),
                  content: const Text(
                    '¿Estás seguro de que quieres vaciar el carrito?',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('No'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Sí'),
                      onPressed: () {
                        cart.clearCart();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Vaciar carrito',
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. Panel Superior con el Total
          Card(
            margin: const EdgeInsets.all(15),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(), // Ocupa el espacio
                  Chip(
                    label: Text(
                      '${cart.totalAmount.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  // ... dentro del Row del Total en cart_screen.dart
                  ElevatedButton(
                    onPressed: (cart.items.isEmpty)
                        ? null
                        : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    username: username, // ¡Pasamos el username!
                                  ),
                                ),
                              );
                            },
                    child: const Text('PEDIR AHORA'),
                  ),
                  // ...
                ],
              ),
            ),
          ),

          // 3. Lista de productos en el carrito
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      '¡Tu carrito está vacío!',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) => CartListItem(item: cart.items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// Widget interno para mostrar cada ítem del carrito
// -----------------------------------------------------------------
class CartListItem extends StatelessWidget {
  final CartItem item;

  const CartListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Usamos Provider.of (listen: false) para llamar a las funciones
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Dismissible permite deslizar para borrar
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        // Llama a la función de eliminar completo
        cart.removeItem(item.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FittedBox(
                  child: Text('${item.price.toStringAsFixed(2)}€'),
                ),
              ),
            ),
            title: Text(item.name),
            subtitle: Text(
              'Total: ${(item.price * item.quantity).toStringAsFixed(2)} €',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de restar
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    cart.removeSingleItem(item.id);
                  },
                ),
                Text('${item.quantity} x'), // Cantidad
                // Botón de sumar
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Para añadir, simulamos que añadimos el producto de nuevo
                    // (Necesitamos el producto original, pero esto es un atajo)
                    // Lo ideal sería pasar el ProductModel al CartItem
                    cart.addItem(
                      ProductModel(
                        id: item.id,
                        name: item.name,
                        description: '', // No la necesitamos aquí
                        price: item.price,
                        imageUrl: '', // No la necesitamos aquí
                        category: '', // No la necesitamos aquí
                        isAvailable: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
