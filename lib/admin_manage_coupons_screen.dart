// lib/admin_manage_coupons_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();

  // Referencia a la colección
  late final CollectionReference _couponsRef;

  @override
  void initState() {
    super.initState();
    _couponsRef = _firestore.collection('coupons');
  }

  // Función para agregar un cupón
  Future<void> _addCoupon() async {
    final code = _codeController.text.trim().toUpperCase(); // Guardamos en mayúsculas
    final percentage = int.tryParse(_percentageController.text.trim()) ?? 0;

    if (code.isEmpty || percentage <= 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código inválido o porcentaje incorrecto (1-100)")),
      );
      return;
    }

    try {
      // Comprobamos si el código ya existe
      final query = await _couponsRef.where('code', isEqualTo: code).limit(1).get();
      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ese código de cupón ya existe")),
        );
        return;
      }

      // Creamos el cupón
      await _couponsRef.add({
        'code': code,
        'discountPercentage': percentage,
        'isActive': true,
      });

      _codeController.clear();
      _percentageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cupón agregado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar cupón: $e")),
      );
    }
  }

  // Función para eliminar un cupón
  Future<void> _deleteCoupon(String docId) async {
    try {
      await _couponsRef.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cupón eliminado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar cupón: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administrar Cupones"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Formulario de Nuevo Cupón ---
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: "Código (ej: VERANO20)"),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _percentageController,
              decoration: const InputDecoration(labelText: "Porcentaje de Dto. (ej: 20)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _addCoupon,
              child: const Text("Agregar Cupón"),
            ),
            
            const SizedBox(height: 20),
            const Text("Cupones Activos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            // --- Lista de Cupones Activos ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _couponsRef.where('isActive', isEqualTo: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No hay cupones activos."));
                  }

                  final coupons = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final data = coupon.data() as Map<String, dynamic>;
                      
                      return Card(
                        child: ListTile(
                          title: Text(data['code'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${data['discountPercentage']}% de descuento"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCoupon(coupon.id),
                          ),
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