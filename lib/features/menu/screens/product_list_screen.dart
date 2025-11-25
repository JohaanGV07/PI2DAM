import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';
import 'package:flutter_firestore_login/shared/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';
import 'package:flutter_firestore_login/features/cart/screens/cart_screen.dart';
import 'package:flutter_firestore_login/core/services/favorite_service.dart';


class ProductListScreen extends StatefulWidget {
  final String username;
  final String userId; 
  
  const ProductListScreen({
    super.key, 
    required this.username, 
    required this.userId,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final FavoriteService _favService = FavoriteService();

  String _sortValue = 'name_asc';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<ProductModel> _filterAndSortProducts(List<ProductModel> products) {
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
      case 'name_asc': filteredProducts.sort((a, b) => a.name.compareTo(b.name)); break;
      case 'name_desc': filteredProducts.sort((a, b) => b.name.compareTo(a.name)); break;
      case 'price_asc': filteredProducts.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_desc': filteredProducts.sort((a, b) => b.price.compareTo(a.price)); break;
    }
    return filteredProducts;
  }
  
  void _onAddToCart(ProductModel product) {
    // --- NUEVA COMPROBACIÓN DE STOCK ---
    // (Aunque el botón esté deshabilitado, protegemos la lógica)
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Lo sentimos! Este producto está agotado."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product.name} añadido al carrito"), duration: const Duration(seconds: 1)),
    );
  }

  void _onToggleFav(ProductModel product) {
    _favService.toggleFavorite(widget.userId, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuestro Catálogo"),
        actions: [
          Consumer<CartProvider>(
            builder: (ctx, cart, child) => Stack(
              alignment: Alignment.center,
              children: [
                child!, 
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.red,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        cart.itemCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      username: widget.username,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      
      body: Column(
        children: [
          _buildFilterSortPanel(),
          
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshotProducts) {
                if (snapshotProducts.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshotProducts.hasData || snapshotProducts.data!.isEmpty) {
                  return const Center(child: Text("No hay productos disponibles."));
                }

                return StreamBuilder<List<String>>(
                  stream: _favService.getFavoriteIdsStream(widget.userId),
                  builder: (context, snapshotFavs) {
                    final favIds = snapshotFavs.data ?? [];

                    final processedProducts = _filterAndSortProducts(snapshotProducts.data!);
                    final featuredProducts = processedProducts.where((p) => p.isFeatured).toList();
                    final regularProducts = processedProducts.where((p) => !p.isFeatured).toList();

                    if (processedProducts.isEmpty) {
                      return const Center(child: Text("No hay productos que coincidan."));
                    }

                    return ListView(
                      children: [
                        // --- SECCIÓN DESTACADOS ---
                        if (featuredProducts.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text("⭐️ Productos Destacados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          ...featuredProducts.map((product) {
                            final isFav = favIds.contains(product.id);
                            return ProductCard(
                              product: product,
                              isFavorite: isFav,
                              onToggleFavorite: () => _onToggleFav(product),
                              onAddToCart: () => _onAddToCart(product),
                            );
                          }),
                          const Divider(thickness: 2, height: 20, indent: 16, endIndent: 16),
                        ],

                        // --- SECCIÓN NORMAL ---
                        if (featuredProducts.isNotEmpty && regularProducts.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text("Menú Completo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        
                        ...regularProducts.map((product) {
                          final isFav = favIds.contains(product.id);
                          return ProductCard(
                            product: product,
                            isFavorite: isFav,
                            onToggleFavorite: () => _onToggleFav(product),
                            onAddToCart: () => _onAddToCart(product),
                          );
                        }),
                      ],
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),

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
                    userId: widget.userId,
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
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(6)),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text('$itemCount', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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

  Widget _buildFilterSortPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _sortValue,
            decoration: const InputDecoration(labelText: "Ordenar por", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'name_asc', child: Text("Nombre (A-Z)")),
              DropdownMenuItem(value: 'name_desc', child: Text("Nombre (Z-A)")),
              DropdownMenuItem(value: 'price_asc', child: Text("Precio (Menor a Mayor)")),
              DropdownMenuItem(value: 'price_desc', child: Text("Precio (Mayor a Menor)")),
            ],
            onChanged: (value) { if (value != null) setState(() => _sortValue = value); },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _minPriceController, decoration: const InputDecoration(labelText: "Precio Mín."), keyboardType: TextInputType.number, onChanged: (value) => setState(() {}))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _maxPriceController, decoration: const InputDecoration(labelText: "Precio Máx."), keyboardType: TextInputType.number, onChanged: (value) => setState(() {}))),
            ],
          ),
        ],
      ),
    );
  }
}