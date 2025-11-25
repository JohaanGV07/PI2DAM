import 'package:flutter/material.dart';

// Imports de pantallas principales
import 'admin_page.dart';
import 'login_page.dart';
import 'contact_map_screen.dart';
import 'manage_products_screen.dart';
import 'admin_manage_orders_screen.dart';
import 'package:flutter_firestore_login/admin_dashboard_screen.dart';
import 'package:flutter_firestore_login/admin_manage_coupons_screen.dart';

// Imports de Features
import 'package:flutter_firestore_login/features/menu/screens/product_list_screen.dart';
import 'package:flutter_firestore_login/features/orders/screens/user_orders_screen.dart';
import 'package:flutter_firestore_login/spin_wheel_screen.dart';
import 'package:flutter_firestore_login/my_prizes_screen.dart';
import 'package:flutter_firestore_login/my_coupons_screen.dart';
import 'package:flutter_firestore_login/features/menu/screens/favorites_screen.dart';

// Imports del Chat
import 'package:flutter_firestore_login/core/services/chat_service.dart';
import 'package:flutter_firestore_login/chat_screen.dart';
import 'package:flutter_firestore_login/admin_chat_list_screen.dart';

// --- IMPORT NUEVO: PERFIL ---
import 'package:flutter_firestore_login/profile_screen.dart';

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
  final ChatService _chatService = ChatService();

  // Lógica de Logout
  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // Navegar a Perfil
  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: widget.userId,
          username: widget.username,
          // *** CORRECCIÓN AQUÍ: nombre del parámetro correcto ***
          currentImageURL: widget.imageURL, 
          rol: widget.rol, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        centerTitle: false,
        actions: [
          // --- LOGO EN LA PARTE SUPERIOR DERECHA ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/coffeexpress.png', width: 40), 
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: "Cerrar Sesión",
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
              currentAccountPicture: GestureDetector(
                onTap: _goToProfile, // Ir al perfil al tocar avatar del drawer
                child: CircleAvatar(
                  backgroundImage: NetworkImage(widget.imageURL),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.brown), // Color café para la marca
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'), 
              onTap: () {
                Navigator.pop(context);
                _goToProfile();
              },
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
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- SALUDO DE BIENVENIDA ---
                const Text(
                  "Bienvenido a",
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                const Text(
                  "CoffeExpress",
                  style: TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.brown,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                
                GestureDetector(
                  onTap: _goToProfile, // Ir a página de perfil
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: NetworkImage(widget.imageURL),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 15),
                
                Text(
                  widget.username,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: Text(
                    "Rol: ${widget.rol}",
                    style: TextStyle(fontSize: 16, color: Colors.brown.shade800),
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- BOTONES DE ADMIN ---
                if (widget.rol == 'admin') ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("PANEL DE ADMINISTRACIÓN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _AdminButton(
                        icon: Icons.dashboard, 
                        label: "Dashboard", 
                        color: Colors.indigo,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                      ),
                      _AdminButton(
                        icon: Icons.admin_panel_settings, 
                        label: "Usuarios", 
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(currentAdminUsername: widget.username))),
                      ),
                      _AdminButton(
                        icon: Icons.coffee, 
                        label: "Catálogo", 
                        color: Colors.brown,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsScreen())),
                      ),
                      _AdminButton(
                        icon: Icons.receipt_long, 
                        label: "Pedidos", 
                        color: Colors.teal,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageOrdersScreen())),
                      ),
                      _AdminButton(
                        icon: Icons.forum, 
                        label: "Chats", 
                        color: Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatListScreen(adminUsername: widget.username))),
                      ),
                      _AdminButton(
                        icon: Icons.percent, 
                        label: "Cupones", 
                        color: Colors.orange.shade800,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCouponsScreen())),
                      ),
                    ],
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

// Widget auxiliar para los botones de admin (más limpio)
class _AdminButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}