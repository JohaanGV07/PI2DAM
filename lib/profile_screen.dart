import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String currentImageURL;
  final String username;
  final String rol;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.currentImageURL,
    required this.username,
    required this.rol,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _imageURLController;
  late String _displayImageURL;

  @override
  void initState() {
    super.initState();
    _displayImageURL = widget.currentImageURL;
    _imageURLController = TextEditingController();
  }

  @override
  void dispose() {
    _imageURLController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileImage() async {
    final newURL = _imageURLController.text.trim();
    if (newURL.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'imageURL': newURL});

      if (!mounted) return;

      setState(() {
        _displayImageURL = newURL;
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Imagen de perfil actualizada correctamente")),
      );
      _imageURLController.clear();
      
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error al actualizar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Grande
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(_displayImageURL),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 20),
            
            Text(
              widget.username,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              "Rol: ${widget.rol}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            const Divider(),
            const SizedBox(height: 20),
            
            const Text("Cambiar Foto de Perfil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _imageURLController,
              decoration: const InputDecoration(
                labelText: "Nueva URL de la imagen",
                hintText: "https://ejemplo.com/foto.jpg",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _updateProfileImage,
              icon: const Icon(Icons.save),
              label: const Text("Guardar Cambios"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}