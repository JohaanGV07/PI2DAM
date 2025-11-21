import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/services/prize_service.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class MyPrizesScreen extends StatelessWidget {
  final String userId;
  
  const MyPrizesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final PrizeService prizeService = PrizeService();

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Premios (Sin canjear)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: prizeService.getPrizesStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final prizes = snapshot.data!.docs;
          if (prizes.isEmpty) return const Center(child: Text("No tienes premios pendientes."));

          return ListView.builder(
            itemCount: prizes.length,
            itemBuilder: (context, index) {
              final prizeDoc = prizes[index];
              final data = prizeDoc.data() as Map<String, dynamic>;
              final prizeName = data['prizeName'] as String;
              final bool isCoupon = prizeName.contains("DTO");

              return Card(
                child: ListTile(
                  leading: Icon(isCoupon ? Icons.percent : Icons.coffee, color: Colors.blue),
                  title: Text(prizeName),
                  subtitle: Text(isCoupon ? "Guardar en Mis Cupones" : "Añadir al Carrito (Gratis)"),
                  trailing: ElevatedButton(
                    child: const Text("CANJEAR"),
                    onPressed: () async {
                      if (isCoupon) {
                        // Lógica Cupón: Convertir y Mover
                        await prizeService.convertPrizeToCoupon(userId, prizeDoc.id, prizeName);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("¡Cupón movido a 'Mis Cupones'!")),
                        );
                      } else {
                        // Lógica Producto: Añadir al CartProvider
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        
                        // Creamos un producto temporal con precio 0
                        final freeProduct = ProductModel(
                          id: "prize_${prizeDoc.id}", // ID único
                          name: prizeName,
                          description: "Premio de Ruleta",
                          price: 0.0, // ¡GRATIS!
                          imageUrl: 'https://picsum.photos/200', 
                          category: 'Premios',
                          isAvailable: true,
                          isFeatured: false,
                          ratingAvg: 5.0, ratingCount: 1
                        );
                        
                        cart.addItem(freeProduct);
                        await prizeService.markPrizeAsRedeemed(userId, prizeDoc.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("¡Producto añadido al carrito!")),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}