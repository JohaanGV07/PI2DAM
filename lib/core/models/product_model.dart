class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final bool isFeatured;
  final double ratingAvg;
  final int ratingCount;
  
  // --- 1. NUEVO CAMPO STOCK ---
  final int stock; 

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.isFeatured,
    required this.ratingAvg,
    required this.ratingCount,
    required this.stock, // <-- Añadido al constructor
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
      isFeatured: data['isFeatured'] ?? false,
      ratingAvg: (data['ratingAvg'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      stock: data['stock'] ?? 0, // <-- Añadido (por defecto 0)
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
      'isFeatured': isFeatured,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'stock': stock, // <-- Añadido para guardar
    };
  }
}