import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/prize_service.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles

class MyCouponsScreen extends StatelessWidget {
  final String userId;
  const MyCouponsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final PrizeService prizeService = PrizeService();

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Cupones")),
      body: StreamBuilder<QuerySnapshot>(
        stream: prizeService.getUserCouponsStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final coupons = snapshot.data!.docs;
          
          if (coupons.isEmpty) {
            return const Center(child: Text("No tienes cupones activos."));
          }

          return ListView.builder(
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final data = coupons[index].data() as Map<String, dynamic>;
              final code = data['code'];
              final discount = data['discountPercentage'];

              return Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.local_offer, color: Colors.orange),
                  title: Text("Descuento $discount%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Código: $code"),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Código copiado")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}