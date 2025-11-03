// lib/core/models/product_model.dart

class ProductModel {
  final String id; // El ID del documento de Firestore
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // Ej: "Bebidas", "Comida", "Postres"
  final bool isAvailable; // Para marcar si hay stock

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
  });

  // Método de fábrica para crear un ProductModel desde un mapa de Firestore
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      // Aseguramos que el precio sea double, venga como int o double
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? 'https://picsum.photos/200/200',
      category: data['category'] ?? 'General',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Método para convertir el modelo a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
    };
  }
}