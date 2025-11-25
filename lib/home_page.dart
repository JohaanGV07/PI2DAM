import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports de pantallas principales
import 'admin_page.dart';
import 'login_page.dart';
import 'contact_map_screen.dart';
import 'manage_products_screen.dart';
import 'admin_manage_orders_screen.dart';
import 'package:flutter_firestore_login/admin_dashboard_screen.dart';
import 'package:flutter_firestore_login/admin_manage_coupons_screen.dart';

// Imports de Features (Carpetas)
import 'package:flutter_firestore_login/features/menu/screens/product_list_screen.dart';
import 'package:flutter_firestore_login/features/orders/screens/user_orders_screen.dart';
import 'package:flutter_firestore_login/spin_wheel_screen.dart';
import 'package:flutter_firestore_login/my_prizes_screen.dart';
import 'package:flutter_firestore_login/my_coupons_screen.dart'; // <-- 1. IMPORT RECUPERADO

// Import de Favoritos
import 'package:flutter_firestore_login/features/menu/screens/favorites_screen.dart';

// Imports del Chat
import 'package:flutter_firestore_login/core/services/chat_service.dart';
import 'package:flutter_firestore_login/chat_screen.dart';
import 'package:flutter_firestore_login/admin_chat_list_screen.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String username;
  final String imageURL;
  final String rol;

  const HomePage({
    super.key,
    required this.userId, 
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
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _currentImageURL = widget.imageURL;
  }

  // Lógica de cambio de imagen
  Future<void> _cambiarImagen() async {
    final newURL = _imageURLController.text.trim();
    if (newURL.isEmpty) return;

    // Guardamos el ScaffoldMessenger antes del await para evitar el error
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'imageURL': newURL});

      // Verificamos 'mounted' justo antes de usar setState
      if (!mounted) return;

      setState(() {
        _currentImageURL = newURL;
      });
      
      // Usamos la referencia guardada en lugar de 'context'
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Imagen actualizada")));
      
      _imageURLController.clear();
    } catch (e) {
      // Usamos la referencia guardada
      scaffoldMessenger.showSnackBar(
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
          decoration: const InputDecoration(hintText: "Ingresa la URL de la nueva imagen"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerramos primero
              _cambiarImagen(); // Luego ejecutamos la lógica async
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _signOut(BuildContext context) async {
    // Guardamos el Navigator antes del await si hubiera lógica async previa
    final navigator = Navigator.of(context);

    navigator.pushAndRemoveUntil(
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
            
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Ver Catálogo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      username: widget.username,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Mis Favoritos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoritesScreen(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Mis Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserOrdersScreen(
                      username: widget.username,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.green),
              title: const Text('Mis Premios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyPrizesScreen(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            // --- 2. BOTÓN DE MIS CUPONES (RECUPERADO) ---
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.purple),
              title: const Text('Mis Cupones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyCouponsScreen(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.casino, color: Colors.orange),
              title: const Text('Ruleta de Premios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpinWheelScreen(
                      username: widget.username,
                      userId: widget.userId,
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
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Soporte (Chat)'),
              onTap: () async {
                Navigator.pop(context);
                
                // Guardamos el navigator antes del await
                final navigator = Navigator.of(context);
                final roomId = await _chatService.getOrCreateChatRoom(widget.username);
                
                if (!mounted) return;

                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      roomId: roomId,
                      currentUsername: widget.username,
                    ),
                  ),
                );
              },
            ),

            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                const Text("Toca la imagen para cambiarla", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                Text("Hola, ${widget.username}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Rol: ${widget.rol}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 30),

                // Botones de Admin
                if (widget.rol == 'admin') ...[
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard, color: Colors.white),
                    label: const Text("Ver Dashboard"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminPage(currentAdminUsername: widget.username),
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

                  const SizedBox(height: 10),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminManageOrdersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text("Gestionar Pedidos"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatListScreen(
                            adminUsername: widget.username,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum, color: Colors.white),
                    label: const Text("Ver Chats de Clientes"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageCouponsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.percent, color: Colors.white),
                    label: const Text("Administrar Cupones"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 48),
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}