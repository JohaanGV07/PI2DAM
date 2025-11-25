import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;
  
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    // Verificamos si está agotado
    final bool isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Si está agotado, le damos un tono ligeramente gris al fondo
      color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // --- IMAGEN CON ETIQUETA AGOTADO ---
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(product.imageUrl),
                  // Si está agotado, la imagen se ve más transparente
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: isOutOfStock ? Colors.white.withOpacity(0.5) : null,
                ),
                if (isOutOfStock)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: const Text(
                        "AGOTADO",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 16),
            
            // --- INFORMACIÓN ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                      color: isOutOfStock ? Colors.grey : Colors.black,
                    ),
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
                      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 16.0,
                    )
                  else
                    const Text("Sin valoraciones", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Text(
                        "${product.price.toStringAsFixed(2)} €",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(width: 10),
                      // Mostrar stock restante si es bajo (ej. menos de 5)
                      if (!isOutOfStock && product.stock < 5)
                        Text(
                          "¡Solo quedan ${product.stock}!",
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- BOTONES ---
            Column(
              children: [
                if (onToggleFavorite != null)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                
                // Botón Carrito (Deshabilitado si no hay stock)
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  color: isOutOfStock ? Colors.grey : Colors.blue,
                  onPressed: isOutOfStock ? null : onAddToCart, // Null deshabilita el botón
                  tooltip: isOutOfStock ? "Producto agotado" : "Añadir al carrito",
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}