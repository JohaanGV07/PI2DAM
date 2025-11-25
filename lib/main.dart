import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'login_page.dart'; // Ya no lo necesitamos aquí directamente
import 'package:flutter_firestore_login/splash_screen.dart'; // <-- 1. IMPORTAMOS SPLASH

// --- Imports del Provider ---
import 'package:provider/provider.dart';
import 'package:flutter_firestore_login/core/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA6Msetg7kOGJUkrLMJQp-sCM7ptmkea0o",
      authDomain: "login-cecbb.firebaseapp.com",
      projectId: "login-cecbb",
      storageBucket: "login-cecbb.firebasestorage.app",
      messagingSenderId: "967420706845",
      appId: "1:967420706845:web:637f2be2653278abdbc6f4",
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoffeExpress', // Nombre actualizado
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Puedes personalizar el tema aquí si quieres colores café
        // primaryColor: Colors.brown,
        useMaterial3: true,
      ),
      // --- 2. CAMBIAMOS LA HOME POR EL SPLASH SCREEN ---
      home: const SplashScreen(), 
    );
  }
}