// lib/features/cart/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';
import 'package:flutter_firestore_login/login_page.dart';

class CheckoutScreen extends StatefulWidget {
  // *** AÑADIMOS EL USERNAME ***
  final String username;

  const CheckoutScreen({
    super.key,
    required this.username, // Hacemos que sea obligatorio
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _addressController = TextEditingController(
      text: "Camins al Grau, 46023 Valencia");
  
  bool _isProcessing = false;

  Future<void> _placeOrder(CartProvider cart) async {
    if (_isProcessing || cart.items.isEmpty) return;

    setState(() => _isProcessing = true);

    // *************************************************************
    // ** USAMOS EL USERNAME RECIBIDO Y UN ID TEMPORAL/ESTÁTICO **
    // *************************************************************
    // Usamos el username real para el campo 'username' en Firestore
    final String currentUsername = widget.username;
    // Como no tenemos UID de Firebase Auth, usamos un ID genérico
    const String currentUserId = 'ID_DEL_USUARIO_ACTUAL'; 

    try {
      await _orderService.createOrder(
        userId: currentUserId,
        username: currentUsername, // ¡Usamos el username!
        cartItems: cart.items,
        totalAmount: cart.totalAmount,
      );

      // Limpiar carrito tras el éxito
      cart.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Pedido enviado con éxito!")),
        );
        // Volver a la lista de productos o a la home
        Navigator.of(context).popUntil((route) => route.isFirst); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar el pedido: $e")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Confirmar Pedido")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la Orden
            Text('Resumen de la Orden (${cart.itemCount} items)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity} x ${item.name}'),
                  Text('${(item.price * item.quantity).toStringAsFixed(2)} €'),
                ],
              ),
            )),
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL A PAGAR:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('${cart.totalAmount.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Dirección de Entrega
            const Text('Dirección de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Dirección",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 40),

            // Botón de Confirmar
            ElevatedButton.icon(
              onPressed: cart.items.isEmpty || _isProcessing
                  ? null
                  : () => _placeOrder(cart),
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle),
              label: Text(_isProcessing ? 'Procesando...' : 'Confirmar y Enviar Pedido'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}