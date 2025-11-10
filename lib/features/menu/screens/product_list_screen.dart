// lib/features/menu/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';
import 'package:flutter_firestore_login/shared/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/features/cart/screens/cart_screen.dart';


class ProductListScreen extends StatefulWidget {
  final String username;
  const ProductListScreen({super.key, required this.username});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  String _sortValue = 'name_asc';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<ProductModel> _filterAndSortProducts(List<ProductModel> products) {
    // (Lógica de filtrado y ordenación se mantiene igual)
    List<ProductModel> filteredProducts = List.from(products);
    final double? minPrice = double.tryParse(_minPriceController.text);
    final double? maxPrice = double.tryParse(_maxPriceController.text);

    if (minPrice != null && minPrice > 0) {
      filteredProducts = filteredProducts.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null && maxPrice > 0) {
      filteredProducts = filteredProducts.where((p) => p.price <= maxPrice).toList();
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
  
  void _onAddToCart(ProductModel product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product); 

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
        // El actions de la AppBar se elimina, usamos el FAB
      ),
      
      body: Column(
        children: [
          _buildFilterSortPanel(), // Panel de filtros
          
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay productos disponibles."));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Aplicamos filtros y ordenación
                final processedProducts = _filterAndSortProducts(snapshot.data!);
                
                // *** 1. SEPARAMOS DESTACADOS DEL RESTO ***
                final featuredProducts = processedProducts.where((p) => p.isFeatured).toList();
                final regularProducts = processedProducts.where((p) => !p.isFeatured).toList();

                if (processedProducts.isEmpty) {
                  return const Center(child: Text("No hay productos que coincidan con los filtros."));
                }

                // *** 2. USAMOS LISTVIEW PARA MOSTRAR SECCIONES ***
                return ListView(
                  children: [
                    // --- SECCIÓN DE DESTACADOS ---
                    if (featuredProducts.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          "⭐️ Productos Destacados",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Creamos la lista de destacados
                      ...featuredProducts.map((product) {
                        return ProductCard(
                          product: product,
                          onAddToCart: () => _onAddToCart(product),
                        );
                      }).toList(),
                      const Divider(thickness: 2, height: 20, indent: 16, endIndent: 16),
                    ],

                    // --- SECCIÓN NORMAL ---
                    // Añadimos un título si también hay destacados
                    if (featuredProducts.isNotEmpty && regularProducts.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          "Menú Completo",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    
                    // Creamos la lista de regulares
                    ...regularProducts.map((product) {
                      return ProductCard(
                        product: product,
                        onAddToCart: () => _onAddToCart(product),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // El FloatingActionButton se mantiene igual
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final itemCount = cartProvider.itemCount; 

          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    username: widget.username,
                  ),
                ),
              );
            },
            backgroundColor: Colors.redAccent,
            child: itemCount > 0
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_cart),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    ],
                  )
                : const Icon(Icons.shopping_cart),
          );
        },
      ),
    );
  }

  // (La función _buildFilterSortPanel() se mantiene exactamente igual)
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