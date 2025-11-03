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
  // Instancia de nuestro servicio de productos
  final ProductService _productService = ProductService();

  // Controladores para el formulario de nuevo producto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Función para agregar un nuevo producto
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

    // Usamos un ID temporal (Firestore lo ignorará)
    final newProduct = ProductModel(
      id: 'temp',
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/200/200',
      category: category,
      isAvailable: true,
    );

    try {
      await _productService.addProduct(newProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto agregado")),
      );
      // Limpiamos los campos
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _categoryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar producto: $e")),
      );
    }
  }

  // Función para eliminar un producto
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administrar Catálogo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Formulario de Nuevo Producto ---
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre Producto"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Precio (ej: 2.50)"),
              keyboardType: TextInputType.number,
            ),
             TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: "Categoría (ej: Bebidas)"),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: "URL de la Imagen (Opcional)"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text("Agregar Producto"),
            ),
            
            // --- Lista de Productos (en tiempo real) ---
            const SizedBox(height: 20),
            const Text("Catálogo Actual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                  final products = snapshot.data!;

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.imageUrl),
                        ),
                        title: Text(product.name),
                        subtitle: Text("${product.category} - ${product.price.toStringAsFixed(2)}€"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}