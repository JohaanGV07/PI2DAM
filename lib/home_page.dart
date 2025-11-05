// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_page.dart';
import 'login_page.dart';
import 'contact_map_screen.dart';

// Importaciones de Features (Carpetas)
import 'package:flutter_firestore_login/features/menu/screens/product_list_screen.dart';
import 'package:flutter_firestore_login/features/orders/screens/user_orders_screen.dart'; // <-- Importación necesaria para Mis Pedidos
import 'package:flutter_firestore_login/manage_products_screen.dart';


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

  // Lógica de cambio de imagen (se mantiene igual)
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

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Imagen actualizada")));

        _imageURLController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar imagen: $e")));
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

  // Lógica de Logout
  Future<void> _signOut(BuildContext context) async {
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
            onPressed: () => _signOut(context),
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
              title: const Text('Inicio (Perfil)'),
              onTap: () => Navigator.pop(context),
            ),
            // *** NAVEGACIÓN CORREGIDA: VER CATÁLOGO ***
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Ver Catálogo'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      username: widget.username, // <-- ¡Pasamos el username!
                    ),
                  ),
                );
              },
            ),
            // *** NAVEGACIÓN CORREGIDA: MIS PEDIDOS ***
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Mis Pedidos'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserOrdersScreen(
                      username: widget.username, // <-- ¡Pasamos el username!
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Contacto y Ubicación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactMapScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () => _signOut(context),
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
            Text(
              "Rol: ${widget.rol}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Botones de Admin
            if (widget.rol == 'admin') ...[
              
              // Administrar Usuarios
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPage(
                        currentAdminUsername: widget.username,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Administrar Usuarios"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 48),
                ),
              ),

              const SizedBox(height: 10),

              // Administrar Catálogo
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageProductsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.coffee),
                label: const Text("Administrar Catálogo"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}