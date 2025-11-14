import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/prize_service.dart';

class MyPrizesScreen extends StatefulWidget {
  final String userId;
  
  const MyPrizesScreen({super.key, required this.userId});

  @override
  State<MyPrizesScreen> createState() => _MyPrizesScreenState();
}

class _MyPrizesScreenState extends State<MyPrizesScreen> {
  final PrizeService _prizeService = PrizeService();

  // Esta función marca el premio como 'usado'
  void _usePrize(String prizeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar uso"),
        content: const Text("¿Estás seguro de que quieres usar este premio? Se marcará como 'usado' y desaparecerá de esta lista."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _prizeService.usePrize(widget.userId, prizeId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("¡Premio canjeado! (Muestra esto en caja)"))
              );
            },
            child: const Text("Sí, usar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Premios"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _prizeService.getPrizesStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar premios: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No tienes premios disponibles.\n¡Prueba la ruleta!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          final prizes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: prizes.length,
            itemBuilder: (context, index) {
              final prizeDoc = prizes[index];
              final prizeData = prizeDoc.data() as Map<String, dynamic>;
              final prizeName = prizeData['prizeName'] ?? 'Premio';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    prizeName.contains('DTO') ? Icons.percent : Icons.coffee,
                    color: Colors.amber.shade700,
                    size: 40,
                  ),
                  title: Text(prizeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Toca para canjear"),
                  trailing: ElevatedButton(
                    child: const Text("USAR"),
                    onPressed: () {
                      _usePrize(prizeDoc.id);
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