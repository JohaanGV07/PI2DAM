import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;
  
  // --- NUEVOS PARÁMETROS ---
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.isFavorite = false, // Por defecto falso
    this.onToggleFavorite,   // Opcional (para admin no lo usaremos)
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagen
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(product.imageUrl),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Estrellas
                  if (product.ratingCount > 0)
                    RatingBarIndicator(
                      rating: product.ratingAvg,
                      itemBuilder: (context, index) => const Icon(
                         Icons.star,
                         color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 16.0,
                    )
                  else
                    const Text(
                      "Sin valoraciones",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  
                  const SizedBox(height: 4),
                  Text(
                    "${product.price.toStringAsFixed(2)} €",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),
            
            // --- BOTONES DE ACCIÓN ---
            Column(
              children: [
                // Botón Favorito
                if (onToggleFavorite != null)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: isFavorite ? "Quitar de favoritos" : "Añadir a favoritos",
                  ),
                
                // Botón Carrito
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  onPressed: onAddToCart,
                  tooltip: "Añadir al carrito",
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}