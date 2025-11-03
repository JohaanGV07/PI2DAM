import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login con Firestore',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
