// lib/core/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final bool isFeatured; // <-- 1. AÑADE ESTE CAMPO

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.isFeatured, // <-- 2. AÑADE AL CONSTRUCTOR
  });

  // Método de fábrica
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? 'https://picsum.photos/200/200',
      category: data['category'] ?? 'General',
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false, // <-- 3. AÑADE (por defecto false)
    );
  }

  // Método toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured, // <-- 4. AÑADE PARA GUARDAR EN FIRESTORE
    };
  }
}