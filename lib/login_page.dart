// lib/login_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'register_page.dart';
// 1. Importa el nuevo servicio de Google
import 'package:flutter_firestore_login/core/services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 2. Instancia el servicio de Google
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> _login() async {
    // ... (la lógica de campos vacíos se queda igual)
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Por favor completa todos los campos");
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _errorMessage = "Usuario no encontrado");
      } else {
        // *** 3. CORRECCIÓN DEL LOGIN MANUAL ***
        final userDoc = query.docs.first;
        final userData = userDoc.data();
        final String userId = userDoc.id; // <-- ¡Capturamos el ID!

        if (userData['password'] == password) {
          // Login exitoso
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                userId: userId, // <-- ¡Pasamos el ID!
                username: userData['username'],
                imageURL: userData['imageURL'],
                rol: userData['rol'],
              ),
            ),
          );
        } else {
          setState(() => _errorMessage = "Contraseña incorrecta");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Error al conectar con Firestore: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // 4. Función para el botón de Google (llama al nuevo servicio)
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await _googleAuthService.signInWithGoogle(context);

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (Tu build se queda igual, excepto el botón de Google) ...
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Iniciar sesión",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre de usuario",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Entrar"),
                  ),
                  const SizedBox(height: 15),
                  const Text("O conéctate con:"),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    // (Asumo que ya tienes el logo en 'assets/google_logo.png')
                    icon: Image.asset('assets/google_logo.png', height: 24.0), 
                    label: const Text("Google"),
                    onPressed: _isLoading ? null : _loginWithGoogle, // <-- Llama a la nueva función
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : _navigateToRegister,
                    child: const Text("¿No tienes cuenta? Regístrate aquí"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}