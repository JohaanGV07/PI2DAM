// lib/admin_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Quitamos 'home_page.dart' (no es necesario aquí)

class AdminPage extends StatefulWidget {
  // 1. Aceptamos el username del admin en el constructor
  final String currentAdminUsername;
  
  const AdminPage({
    super.key,
    required this.currentAdminUsername, // Hacemos que sea obligatorio
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  // 2. Ya no necesitamos 'ModalRoute' ni 'didChangeDependencies'
  // El 'currentAdminUsername' lo leemos con 'widget.currentAdminUsername'

  Future<void> agregarUsuario() async {
    // ... (Tu función agregarUsuario() se queda exactamente igual) ...
    final username = _newUsernameController.text.trim();
    final password = _newPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'password': password,
        'rol': 'user', 
        'imageURL': 'https://www.shutterstock.com/image-vector/default-avatar-profile-icon-vector-600nw-1725655669.jpg',
      });

      _newUsernameController.clear();
      _newPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario agregado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar usuario: $e")),
      );
    }
  }

  Future<void> eliminarUsuario(String userId, String username) async {
    // 3. Usamos 'widget.currentAdminUsername' para la comprobación
    if (username == widget.currentAdminUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes eliminar tu propio usuario")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario eliminado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar usuario: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. Ya no necesitamos la variable 'adminUsername'
    return Scaffold(
      appBar: AppBar(title: const Text("Administrar usuarios")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... (Tu formulario de agregar usuario se queda igual) ...
            TextField(
              controller: _newUsernameController,
              decoration: const InputDecoration(
                labelText: "Nuevo usuario",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: agregarUsuario,
              icon: const Icon(Icons.person_add),
              label: const Text("Agregar usuario"),
            ),
            const SizedBox(height: 20),
            
            // ... (Tu StreamBuilder se queda exactamente igual) ...
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userData = user.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(userData['username'] ?? 'N/A'),
                        subtitle: Text("Rol: ${userData['rol'] ?? 'user'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              eliminarUsuario(user.id, userData['username'] ?? 'N/A'),
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