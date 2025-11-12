// lib/manage_products_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ProductService _productService = ProductService();

  // Controladores del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isFeatured = false; 

  // --- 1. CONTROLADOR PARA LA BÚSQUEDA ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _searchController.dispose(); // <-- No olvides el dispose
    super.dispose();
  }

  // (Las funciones _addProduct, _deleteProduct y _showEditProductDialog se mantienen exactamente igual)
  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final imageUrl = _imageUrlController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty || price <= 0 || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre, Precio y Categoría son obligatorios")),
      );
      return;
    }

    final newProduct = ProductModel(
      id: 'temp',
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/200/200',
      category: category,
      isAvailable: true,
      isFeatured: _isFeatured,
      ratingAvg: 0.0,
      ratingCount: 0,
    );

    try {
      await _productService.addProduct(newProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto agregado")),
      );
      
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _categoryController.clear();
      setState(() {
        _isFeatured = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar producto: $e")),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
     try {
      await _productService.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto eliminado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar producto: $e")),
      );
    }
  }

  Future<void> _showEditProductDialog(ProductModel product) async {
    final nameEditController = TextEditingController(text: product.name);
    final descEditController = TextEditingController(text: product.description);
    final priceEditController = TextEditingController(text: product.price.toString());
    final imageUrlEditController = TextEditingController(text: product.imageUrl);
    final categoryEditController = TextEditingController(text: product.category);
    bool isFeaturedEdit = product.isFeatured;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Editar Producto"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameEditController, decoration: const InputDecoration(labelText: "Nombre")),
                    TextField(controller: descEditController, decoration: const InputDecoration(labelText: "Descripción")),
                    TextField(controller: priceEditController, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
                    TextField(controller: categoryEditController, decoration: const InputDecoration(labelText: "Categoría")),
                    TextField(controller: imageUrlEditController, decoration: const InputDecoration(labelText: "URL Imagen")),
                    SwitchListTile(
                      title: const Text("Destacado"),
                      value: isFeaturedEdit,
                      onChanged: (value) {
                        setDialogState(() {
                          isFeaturedEdit = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Valoración: ${product.ratingAvg.toStringAsFixed(1)} ⭐️ (${product.ratingCount} reseñas)",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedProduct = ProductModel(
                      id: product.id,
                      name: nameEditController.text,
                      description: descEditController.text,
                      price: double.tryParse(priceEditController.text) ?? product.price,
                      category: categoryEditController.text,
                      imageUrl: imageUrlEditController.text,
                      isFeatured: isFeaturedEdit,
                      isAvailable: product.isAvailable,
                      ratingAvg: product.ratingAvg,
                      ratingCount: product.ratingCount,
                    );
                    
                    try {
                      await _productService.updateProduct(updatedProduct);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Producto actualizado")),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al actualizar: $e")),
                      );
                    }
                  },
                  child: const Text("Actualizar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- WIDGET BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administrar Catálogo")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            // --- VISTA MÓVIL (Estrecha) ---
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SingleChildScrollView( 
                    child: _buildProductForm(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildProductList(), // La lista (que es Expanded)
                ],
              ),
            );
          } else {
            // --- VISTA DESKTOP (Ancha) ---
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: _buildProductForm(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildProductList(), // <-- Lista a la derecha
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // --- WIDGET FORMULARIO (Se queda igual) ---
  Widget _buildProductForm() {
    return Column(
      children: [
        const Text("Agregar Producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre Producto")),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: "Descripción")),
        TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Precio (ej: 2.50)"), keyboardType: TextInputType.number),
        TextField(controller: _categoryController, decoration: const InputDecoration(labelText: "Categoría (ej: Bebidas)")),
        TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: "URL de la Imagen (Opcional)")),
        SwitchListTile(
          title: const Text("¿Es Producto Destacado?"),
          value: _isFeatured,
          onChanged: (bool value) {
            setState(() { _isFeatured = value; });
          },
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _addProduct,
          child: const Text("Agregar Producto"),
        ),
      ],
    );
  }

  // --- 2. WIDGET LISTA (MODIFICADO CON BÚSQUEDA) ---
  Widget _buildProductList() {
    return Column(
      children: [
        const Text("Catálogo Actual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // --- 3. BARRA DE BÚSQUEDA AÑADIDA ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Buscar por nombre de producto...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        
        Expanded( 
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay productos en el catálogo."));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // --- 4. LÓGICA DE FILTRADO ---
              final allProducts = snapshot.data!;
              final filteredProducts = _searchQuery.isEmpty
                  ? allProducts
                  : allProducts.where((product) {
                      final name = product.name.toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
              
              if (filteredProducts.isEmpty) {
                return const Center(child: Text("No se encontraron productos."));
              }

              return ListView.builder(
                itemCount: filteredProducts.length, // <-- Usamos la lista filtrada
                itemBuilder: (context, index) {
                  final product = filteredProducts[index]; // <-- Usamos la lista filtrada
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(product.imageUrl),
                    ),
                    title: Row(
                      children: [
                        Text(product.name),
                        if (product.isFeatured)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.star, color: Colors.amber, size: 16),
                          ),
                      ],
                    ),
                    subtitle: Text("${product.category} - ${product.price.toStringAsFixed(2)}€ (${product.ratingAvg.toStringAsFixed(1)} ⭐️)"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditProductDialog(product),
                          tooltip: "Editar",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product.id),
                          tooltip: "Eliminar",
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}