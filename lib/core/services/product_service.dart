// lib/core/services/product_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Referencia a la colección 'products'
  late final CollectionReference _productsRef;

  ProductService() {
    _productsRef = _firestore.collection('products');
  }

  // --- Funciones del Admin ---

  // Crear un nuevo producto
  Future<void> addProduct(ProductModel product) async {
    try {
      await _productsRef.add(product.toMap());
    } catch (e) {
      throw Exception('Error al añadir producto: $e');
    }
  }

  // Actualizar un producto existente
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.id).update(product.toMap());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // Eliminar un producto
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // --- Funciones del Cliente (y Admin) ---

  // Obtener un Stream (flujo en tiempo real) de todos los productos
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }
}