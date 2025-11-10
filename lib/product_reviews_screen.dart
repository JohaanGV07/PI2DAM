// lib/product_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductReviewsScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reseñas de $productName"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Lee la subcolección 'reviews' DENTRO del 'productId'
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .collection('reviews') // <-- Lee aquí
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar reseñas: ${snapshot.error}"));
          }
          
          // 2. Comprueba si la instantánea tiene datos Y si la lista de documentos no está vacía
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Este producto todavía no tiene valoraciones.",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          // 3. Si todo va bien, muestra las reseñas
          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final reviewData = reviews[index].data() as Map<String, dynamic>;
              final double rating = (reviewData['rating'] ?? 0.0).toDouble();
              final String comment = reviewData['comment'] ?? 'Sin comentario';
              final String username = reviewData['username'] ?? 'Anónimo';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 18.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment.isEmpty ? "(Sin comentario)" : comment,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: comment.isEmpty ? FontStyle.italic : FontStyle.normal,
                          color: comment.isEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
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