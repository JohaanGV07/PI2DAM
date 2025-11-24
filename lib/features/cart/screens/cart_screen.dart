import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/features/cart/screens/checkout_screen.dart';
import '../../../core/models/product_model.dart'; // Asegúrate de que esta ruta es correcta

class CartScreen extends StatefulWidget {
  final String username;
  final String userId;

  const CartScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  void _applyCoupon() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    // Pasamos el userId para que busque en la subcolección correcta
    cart.applyCoupon(_couponController.text, widget.userId); 
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Tu Carrito"),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar'),
                      content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
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
              // --- Panel Superior ---
              Card(
                margin: const EdgeInsets.all(15),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Campo de Cupón
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: const InputDecoration(
                                labelText: "Código de Cupón",
                                hintText: "Ej: GANADO-10-XYZ",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _applyCoupon,
                            child: const Text("Aplicar"),
                          ),
                        ],
                      ),
                      if (cart.couponStatusMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            cart.couponStatusMessage,
                            style: TextStyle(
                              color: cart.appliedCouponCode != null ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const Divider(height: 20),

                      // Desglose
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 16)),
                          Text('${cart.subtotalAmount.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      if (cart.appliedCouponCode != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Descuento (${cart.appliedCouponCode})', style: const TextStyle(fontSize: 16, color: Colors.green)),
                            Text('- ${cart.discountAmount.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, color: Colors.green)),
                          ],
                        ),
                      
                      const SizedBox(height: 10),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${cart.totalAmount.toStringAsFixed(2)} €',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Botón Pedir
                      ElevatedButton(
                        onPressed: (cart.items.isEmpty)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      username: widget.username,
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('PEDIR AHORA'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Lista de productos ---
              Expanded(
                child: cart.items.isEmpty
                    ? const Center(
                        child: Text('¡Tu carrito está vacío!', style: TextStyle(fontSize: 18)),
                      )
                    : ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) => CartListItem(item: cart.items[i]),
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}

// Widget interno para lista
class CartListItem extends StatelessWidget {
  final CartItem item;
  const CartListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

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
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    cart.removeSingleItem(item.id);
                  },
                ),
                Text('${item.quantity} x'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // *** AQUÍ ESTÁ LA CORRECCIÓN PARA EL MODELO ***
                    cart.addItem(
                      ProductModel(
                        id: item.id,
                        name: item.name,
                        description: '',
                        price: item.price,
                        imageUrl: '',
                        category: '',
                        isAvailable: true,
                        isFeatured: false,
                        ratingAvg: 0.0,
                        ratingCount: 0,
                        stock: 99, // <-- ¡FALTABA ESTE CAMPO!
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