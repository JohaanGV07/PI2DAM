// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'admin_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String imageURL;
  final String rol;

  const HomePage({
    super.key,
    required this.username,
    required this.imageURL,
    required this.rol,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentImageURL;
  final TextEditingController _imageURLController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentImageURL = widget.imageURL;
  }

  Future<void> _cambiarImagen() async {
    final newURL = _imageURLController.text.trim();
    if (newURL.isEmpty) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(query.docs.first.id)
            .update({'imageURL': newURL});

        setState(() {
          _currentImageURL = newURL;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Imagen actualizada")));

        _imageURLController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al actualizar imagen: $e")));
    }
  }

  void _mostrarDialogCambioImagen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Actualizar imagen de perfil"),
        content: TextField(
          controller: _imageURLController,
          decoration: const InputDecoration(
            hintText: "Ingresa la URL de la nueva imagen",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _cambiarImagen();
              Navigator.pop(context);
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }

  // --- Lógica de Logout ---
  // (La añadimos aquí para que el botón funcione)
  Future<void> _signOut(BuildContext context) async {
    // Como no usamos Firebase Auth, solo navegamos al Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context), // <--- Lógica de logout añadida
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username),
              accountEmail: Text("Rol: ${widget.rol}"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(_currentImageURL),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Ver Catálogo'), // Ajustado para la app
              onTap: () {
                // TODO: Navegar a ProductListScreen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Mis Pedidos'), // Ajustado para la app
              onTap: () {
                // TODO: Navegar a UserOrdersScreen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app), // Icono cambiado
              title: const Text('Cerrar Sesión'),
              onTap: () => _signOut(context), // Lógica de logout añadida
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _mostrarDialogCambioImagen,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_currentImageURL),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Toca la imagen para cambiarla",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              "Hola, ${widget.username}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // En lib/home_page.dart, dentro del build:
            if (widget.rol == 'admin') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPage(
                        // Así es como pasamos el username
                        currentAdminUsername: widget.username,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text(
                  "Administrar usuarios",
                ), // O "Administrar Cafetería"
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
