import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firestore_login/login_page.dart';

// --- 1. Importa los paquetes necesarios ---
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

  // --- 2. Envuelve la App con el Provider ---
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(), // Tu app (MyApp) ahora es hija del Provider
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestor cafetería',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
