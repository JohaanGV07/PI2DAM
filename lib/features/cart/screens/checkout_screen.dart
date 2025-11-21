import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';

// Imports para el mapa
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_firestore_login/address_picker_map_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String username;
  final String userId;

  const CheckoutScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _addressController = TextEditingController();
  
  // Ubicación por defecto de la cafetería
  LatLng _selectedDeliveryLocation = LatLng(39.458090, -0.350943);
  
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    // Al iniciar, convertimos la ubicación por defecto en texto
    _getAddressFromLatLng(_selectedDeliveryLocation, isDefault: true);
  }

  // Navegar al mapa y esperar el resultado
  Future<void> _openMapSelector() async {
    FocusScope.of(context).unfocus();

    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressPickerMapScreen(
          initialLocation: _selectedDeliveryLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDeliveryLocation = result;
      });
      _getAddressFromLatLng(result);
    }
  }

  // Convertir LatLng a Dirección (Reverse Geocoding)
  Future<void> _getAddressFromLatLng(LatLng coords, {bool isDefault = false}) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final String address = "${p.street}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.postalCode ?? ''}";
        
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      setState(() {
         _addressController.text = "Lat: ${coords.latitude.toStringAsFixed(4)}, Lng: ${coords.longitude.toStringAsFixed(4)}";
      });
    }
  }

  // Lógica para enviar el pedido
  Future<void> _placeOrder(CartProvider cart) async {
    if (_isProcessing || cart.items.isEmpty) return;
    setState(() => _isProcessing = true);

    final String currentUserId = widget.userId;
    final String currentUsername = widget.username; 
    
    // Obtenemos la dirección del controlador
    // (Puedes añadir esto al createOrder si modificas el servicio más adelante)
    // final String deliveryAddress = _addressController.text;

    try {
      await _orderService.createOrder(
        userId: currentUserId,
        username: currentUsername,
        cartItems: cart.items,
        totalAmount: cart.totalAmount,
      );

      // Quemar cupón si se usó
      await cart.markCouponAsUsed(widget.userId);
      
      cart.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Pedido enviado con éxito!")),
        );
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
            
            // --- CAMPO DE DIRECCIÓN (CORREGIDO) ---
            const Text('Dirección de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: InputDecoration( // <--- Sin 'const' aquí
                labelText: "Dirección seleccionada",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map), // <--- CORREGIDO: Icons.map existe (map_search no)
                  onPressed: _openMapSelector,
                  tooltip: "Seleccionar en el mapa",
                ),
              ),
              maxLines: 2,
              readOnly: true, 
              onTap: _openMapSelector,
            ),
            
            const SizedBox(height: 40),

            // --- BOTÓN CONFIRMAR ---
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