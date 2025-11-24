import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/favorite_service.dart';
import 'package:flutter_firestore_login/shared/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';

class FavoritesScreen extends StatelessWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final FavoriteService favService = FavoriteService();

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Favoritos ❤️")),
      body: StreamBuilder<QuerySnapshot>(
        stream: favService.getFavoritesListStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Aún no tienes favoritos.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Reconstruimos el modelo
              final product = ProductModel(
                id: docs[index].id,
                name: data['name'] ?? 'Desconocido',
                description: '...', 
                price: (data['price'] ?? 0.0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
                category: '',
                isAvailable: true,
                isFeatured: false,
                
                // --- CAMPOS NUEVOS AÑADIDOS PARA EVITAR ERROR ---
                ratingAvg: 0.0,  // No guardamos rating en favoritos, usamos 0
                ratingCount: 0,
                stock: 99,      // Asumimos stock para favoritos (se comprobará al añadir al carrito)
              );

              return ProductCard(
                product: product,
                isFavorite: true, 
                onToggleFavorite: () {
                  favService.toggleFavorite(userId, product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Eliminado de favoritos")),
                  );
                },
                onAddToCart: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Añadido al carrito")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}