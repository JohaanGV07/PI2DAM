// lib/core/services/google_auth_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/home_page.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle(BuildContext context) async {
    // 1. Crear el proveedor de Google
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    // (Opcional: puedes añadir scopes si los necesitas)
    // googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');

    try {
      // 2. Iniciar sesión con Popup (método específico de Web)
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception("Error al iniciar sesión con Google.");
      }

      // 3. Comprobar si el usuario YA existe en nuestra BD 'users'
      // Usamos el UID de Firebase Auth como ID del documento
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      String username;
      String imageURL;
      String rol;
      String userId = user.uid; // El ID siempre será el de Firebase Auth

      if (!userDoc.exists) {
        // --- 4. SI NO EXISTE: Lo creamos en Firestore ---
        print("Creando nuevo usuario en Firestore...");
        
        username = user.displayName ?? user.email!;
        imageURL = user.photoURL ?? 'https://www.shutterstock.com/image-vector/default-avatar-profile-icon-vector-600nw-1725655669.jpg';
        rol = 'user'; // Rol por defecto

        await _firestore.collection('users').doc(userId).set({
          'username': username,
          'email': user.email,
          'imageURL': imageURL,
          'rol': rol,
          'password': '', // Password vacío (ya que usan Google)
        });

      } else {
        // --- 5. SI YA EXISTE: Obtenemos sus datos ---
        print("Usuario ya existe. Obteniendo datos...");
        final userData = userDoc.data() as Map<String, dynamic>;
        username = userData['username'];
        imageURL = userData['imageURL'];
        rol = userData['rol'];
        
        // (Opcional) Actualizamos su foto si la de Google es más nueva
        if (user.photoURL != null && userData['imageURL'] != user.photoURL) {
           await userDoc.reference.update({'imageURL': user.photoURL});
           imageURL = user.photoURL!;
        }
      }

      // 6. Navegar a HomePage
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: userId, // Pasamos el UID real
              username: username,
              imageURL: imageURL,
              rol: rol,
            ),
          ),
        );
      }

    } catch (e) {
      print("Error en Google Sign-In: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar con Google: $e")),
      );
    }
  }
}