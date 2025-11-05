// lib/features/menu/screens/product_list_screen.dart

import 'package:flutter/material.dart';

import 'package.flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';
import 'package:flutter_firestore_login/shared/widgets/product_card.dart';

// --- 1. Importa Provider y el CartProvider ---
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
// TODO: Importa tu cart_screen.dart (lo crearemos después)
import 'package:flutter_firestore_login/features/cart/screens/cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String username;
  const ProductListScreen({super.key, required this.username});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  // (El resto de controladores y la función _filterAndSortProducts se quedan igual)
  String _sortValue = 'name_asc';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<ProductModel> _filterAndSortProducts(List<ProductModel> products) {
    List<ProductModel> filteredProducts = List.from(products);
    final double? minPrice = double.tryParse(_minPriceController.text);
    final double? maxPrice = double.tryParse(_maxPriceController.text);

    if (minPrice != null && minPrice > 0) {
      filteredProducts = filteredProducts
          .where((p) => p.price >= minPrice)
          .toList();
    }
    if (maxPrice != null && maxPrice > 0) {
      filteredProducts = filteredProducts
          .where((p) => p.price <= maxPrice)
          .toList();
    }

    switch (_sortValue) {
      case 'name_asc':
        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return filteredProducts;
  }
  // --- Fin de la lógica de filtros ---

  // --- 2. Función _onAddToCart ACTUALIZADA ---
  void _onAddToCart(ProductModel product) {
    // Usamos Provider.of para encontrar el CartProvider
    // listen: false porque estamos en una función, no en el build
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product); // <-- ¡Llamamos al método del provider!

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product.name} añadido al carrito"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuestro Catálogo"),
        actions: [
          Consumer<CartProvider>(
            builder: (ctx, cart, child) => Stack(
              // ... (el contador rojo se queda igual) ...
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      username: widget.username, // ¡Pasamos el username!
                    ),
                  ),
                );
              },
            ),
            // ...
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSortPanel(), // Panel de filtros (se queda igual)

          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No hay productos disponibles."),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final processedProducts = _filterAndSortProducts(
                  snapshot.data!,
                );

                if (processedProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay productos que coincidan con los filtros.",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: processedProducts.length,
                  itemBuilder: (context, index) {
                    final product = processedProducts[index];
                    return ProductCard(
                      // El widget de tarjeta que ya teníamos
                      product: product,
                      onAddToCart: () => _onAddToCart(product),
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

  // (La función _buildFilterSortPanel() se queda exactamente igual)
  Widget _buildFilterSortPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _sortValue,
            decoration: const InputDecoration(
              labelText: "Ordenar por",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'name_asc', child: Text("Nombre (A-Z)")),
              DropdownMenuItem(value: 'name_desc', child: Text("Nombre (Z-A)")),
              DropdownMenuItem(
                value: 'price_asc',
                child: Text("Precio (Menor a Mayor)"),
              ),
              DropdownMenuItem(
                value: 'price_desc',
                child: Text("Precio (Mayor a Menor)"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortValue = value);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(labelText: "Precio Mín."),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  decoration: const InputDecoration(labelText: "Precio Máx."),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
