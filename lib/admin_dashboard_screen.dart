// lib/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/order_service.dart';
import 'package:flutter_firestore_login/core/services/product_service.dart';
import 'package:flutter_firestore_login/core/models/product_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final ProductService productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard de Admin"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Usamos ListView para que sea scrollable
          children: [
            // --- 1. Tarjeta de Ingresos Totales (Solo pedidos 'Listos' o 'Entregados') ---
            _buildTotalRevenueCard(orderService),

            const SizedBox(height: 16),

            // --- 2. Tarjetas de Pedidos y Clientes (en una fila) ---
            Row(
              children: [
                Expanded(child: _buildPendingOrdersCard(orderService)),
                const SizedBox(width: 16),
                Expanded(child: _buildTotalCustomersCard()),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- 3. Tarjeta de Producto Estrella (Mejor Valoración) ---
            const Text(
              "Producto Estrella ⭐️",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTopRatedProductCard(productService),
          ],
        ),
      ),
    );
  }

  // --- Widget para Tarjeta de Ingresos ---
  Widget _buildTotalRevenueCard(OrderService service) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "INGRESOS TOTALES",
              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: service.getAllOrdersStream(), // Reutilizamos el stream de todos los pedidos
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                double totalRevenue = 0.0;
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Sumamos solo si el pedido está completado
                  if (data['status'] == 'Listo' || data['status'] == 'Entregado') {
                    totalRevenue += (data['totalAmount'] ?? 0.0);
                  }
                }
                return Text(
                  "${totalRevenue.toStringAsFixed(2)} €",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget para Pedidos Pendientes ---
  Widget _buildPendingOrdersCard(OrderService service) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Pendientes",
              style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'Pendiente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text(
                  snapshot.data!.docs.length.toString(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget para Total de Clientes ---
  Widget _buildTotalCustomersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Clientes",
              style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('rol', isEqualTo: 'user') // Contamos solo clientes
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text(
                  snapshot.data!.docs.length.toString(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Widget para Producto Estrella ---
  Widget _buildTopRatedProductCard(ProductService service) {
    // Usamos un Stream normal de productos y lo ordenamos/filtramos en el builder
    return StreamBuilder<List<ProductModel>>(
      stream: service.getProductsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text("Calculando..."));
        
        // Copiamos la lista para poder ordenarla
        final products = List<ProductModel>.from(snapshot.data!);
        
        // Ordenamos por valoración descendente
        products.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
        
        if (products.isEmpty || products.first.ratingCount == 0) {
          return const Card(child: ListTile(title: Text("Aún no hay valoraciones")));
        }
        
        final topProduct = products.first;

        return Card(
          elevation: 2,
          color: Colors.amber.shade50,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(topProduct.imageUrl),
            ),
            title: Text(topProduct.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Basado en ${topProduct.ratingCount} reseñas"),
            trailing: Chip(
              label: Text("${topProduct.ratingAvg.toStringAsFixed(1)} ⭐️"),
              backgroundColor: Colors.amber.shade200,
            ),
          ),
        );
      },
    );
  }
}