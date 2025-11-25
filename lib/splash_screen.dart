import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_firestore_login/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Configuración de la animación (Fade In + Escalado suave)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Temporizador para navegar al Login después de 3 segundos
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo color café suave o blanco, según prefieras
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animado
            ScaleTransition(
              scale: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  'assets/coffeexpress.png', // Asegúrate de que el nombre sea exacto
                  width: 200, // Ajusta el tamaño según tu logo
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Texto de la App (Opcional, si el logo no tiene texto)
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "CoffeExpress",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown, // Color temático
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            ),
          ],
        ),
      ),
    );
  }
}