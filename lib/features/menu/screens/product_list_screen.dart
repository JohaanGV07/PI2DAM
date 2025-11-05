// lib/features/menu/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';
import 'package:flutter_firestore_login/shared/widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  // --- Estado para Filtros y Ordenación ---
  String _sortValue = 'name_asc'; // Valor por defecto
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Esta función aplica los filtros y la ordenación a la lista de productos
  List<ProductModel> _filterAndSortProducts(List<ProductModel> products) {
    List<ProductModel> filteredProducts = List.from(products);

    // 1. Filtrado por Rango Numérico (Precio)
    final double? minPrice = double.tryParse(_minPriceController.text);
    final double? maxPrice = double.tryParse(_maxPriceController.text);

    if (minPrice != null && minPrice > 0) {
      filteredProducts = filteredProducts.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null && maxPrice > 0) {
      filteredProducts = filteredProducts.where((p) => p.price <= maxPrice).toList();
    }

    // 2. Ordenación (Alfabética y Numérica, Asc y Desc)
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
    // TODO: Implementar lógica del CartProvider (siguiente paso)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product.name} añadido al carrito")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuestro Catálogo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Navegar a CartScreen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Panel de Filtros y Ordenación ---
          _buildFilterSortPanel(),
          
          // --- Lista de Productos ---
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

                // Aplicamos los filtros locales a la lista de Firestore
                final processedProducts = _filterAndSortProducts(snapshot.data!);

                if (processedProducts.isEmpty) {
                  return const Center(child: Text("No hay productos que coincidan con los filtros."));
                }

                return ListView.builder(
                  itemCount: processedProducts.length,
                  itemBuilder: (context, index) {
                    final product = processedProducts[index];
                    return ProductCard(
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

  // Widget del panel de filtros
  Widget _buildFilterSortPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Ordenación
          DropdownButtonFormField<String>(
            value: _sortValue,
            decoration: const InputDecoration(
              labelText: "Ordenar por",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'name_asc', child: Text("Nombre (A-Z)")),
              DropdownMenuItem(value: 'name_desc', child: Text("Nombre (Z-A)")),
              DropdownMenuItem(value: 'price_asc', child: Text("Precio (Menor a Mayor)")),
              DropdownMenuItem(value: 'price_desc', child: Text("Precio (Mayor a Menor)")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortValue = value);
              }
            },
          ),
          const SizedBox(height: 10),
          // Rango de Precios
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(labelText: "Precio Mín."),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}), // Refresca al escribir
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  decoration: const InputDecoration(labelText: "Precio Máx."),
                  keyboardType: TextInputType.number,
                   onChanged: (value) => setState(() {}), // Refresca al escribir
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}