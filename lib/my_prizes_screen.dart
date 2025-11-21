import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/prize_service.dart';

// --- 1. IMPORTS NUEVOS NECESARIOS ---
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class MyPrizesScreen extends StatefulWidget {
  final String userId;
  
  const MyPrizesScreen({super.key, required this.userId});

  @override
  State<MyPrizesScreen> createState() => _MyPrizesScreenState();
}

class _MyPrizesScreenState extends State<MyPrizesScreen> {
  final PrizeService _prizeService = PrizeService();

  // --- 2. FUNCIÓN ACTUALIZADA PARA GESTIONAR EL PREMIO ---
  void _usePrize(String prizeId, String prizeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar canjeo"),
        content: Text("¿Quieres canjear '$prizeName' ahora?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar diálogo

              // A) SI ES UN CUPÓN (Tiene %)
              if (prizeName.contains('%') || prizeName.contains('DTO')) {
                await _prizeService.convertPrizeToCoupon(widget.userId, prizeId, prizeName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Cupón guardado en 'Mis Cupones'!"))
                  );
                }
              } 
              // B) SI ES UN PRODUCTO (Café, Postre, etc.)
              else {
                // 1. Obtener el carrito
                final cart = Provider.of<CartProvider>(context, listen: false);
                
                // 2. Crear un producto "falso" con precio 0
                final freeProduct = ProductModel(
                  id: "prize_$prizeId", // ID único para que no se mezcle
                  name: prizeName,
                  description: "Premio de Ruleta (Gratis)",
                  price: 0.0, // ¡GRATIS!
                  imageUrl: 'https://cdn-icons-png.flaticon.com/512/2531/2531115.png', // Icono genérico de regalo
                  category: 'Premios',
                  isAvailable: true,
                  isFeatured: false,
                  ratingAvg: 5.0,
                  ratingCount: 1,
                );

                // 3. Añadir al carrito
                cart.addItem(freeProduct);

                // 4. Marcar como usado en la base de datos
                await _prizeService.markPrizeAsRedeemed(widget.userId, prizeId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Producto añadido al carrito GRATIS!"),
                      backgroundColor: Colors.green,
                    )
                  );
                }
              }
            },
            child: const Text("Sí, canjear"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Premios"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _prizeService.getPrizesStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes premios pendientes.\n¡Prueba la ruleta!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  );
                }
      
                final prizes = snapshot.data!.docs;
      
                return ListView.builder(
                  itemCount: prizes.length,
                  itemBuilder: (context, index) {
                    final prizeDoc = prizes[index];
                    final prizeData = prizeDoc.data() as Map<String, dynamic>;
                    final prizeName = prizeData['prizeName'] ?? 'Premio';
      
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          prizeName.contains('DTO') ? Icons.percent : Icons.card_giftcard,
                          color: Colors.amber.shade700,
                          size: 40,
                        ),
                        title: Text(prizeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Toca para canjear"),
                        trailing: ElevatedButton(
                          child: const Text("CANJEAR"),
                          onPressed: () {
                            // Pasamos el ID y el NOMBRE a la función
                            _usePrize(prizeDoc.id, prizeName);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}