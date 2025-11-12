// lib/spin_wheel_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart'; // Necesario para el controlador

class SpinWheelScreen extends StatefulWidget {
  final String username; // Lo necesitaremos si el premio es un cupón

  const SpinWheelScreen({super.key, required this.username});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  // Controlador para indicar a la ruleta a dónde girar
  final StreamController<int> _selected = BehaviorSubject<int>();

  // Lista de premios
  final List<String> items = [
    '10% DTO',
    'Sigue intentando 😢',
    'Capucchino Gratis',
    '5% DTO',
    'Sigue intentando 😢',
    'Postre Gratis',
  ];

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  // Función para mostrar el premio
  void _showPrizeDialog(String prize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¡Felicidades!"),
        content: Text("¡Has ganado: $prize!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Añadir lógica para guardar el premio (ej. crear un cupón)
            },
            child: const Text("Genial"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ruleta de la Suerte"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "¡Gira la ruleta y gana!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // --- 1. La Ruleta ---
            SizedBox(
              height: 300,
              width: 300,
              child: FortuneWheel(
                selected: _selected.stream, // Escucha al controlador
                animateFirst: false, // No gira al cargar
                items: [
                  for (var item in items)
                    FortuneItem(
                      child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: FortuneItemStyle(
                        // Damos colores alternos
                        color: items.indexOf(item) % 2 == 0 ? Colors.blue.shade100 : Colors.blue.shade300,
                        borderColor: Colors.blue.shade700,
                        borderWidth: 2,
                      ),
                    ),
                ],
                onAnimationEnd: () {
                  // Cuando la animación termina, mostramos el diálogo
                  setState(() {
                    // (Esta lógica es para el ejemplo,
                    // en una app real el 'value' vendría del 'selected')
                    // Pero necesitamos saber el resultado ANTES de girar.
                    // Vamos a simplificarlo: el 'onSpin' nos dirá el índice.
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. El Botón de Girar ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 50),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("¡GIRAR!", style: TextStyle(fontSize: 20)),
              onPressed: () {
                // Genera un número aleatorio para elegir un premio
                final int randomIndex = Fortune.randomInt(0, items.length);
                
                // Le dice a la ruleta a qué índice debe ir
                _selected.add(randomIndex);

                // Mostramos el diálogo DESPUÉS de que la ruleta gire
                Future.delayed(const Duration(seconds: 4), () {
                  _showPrizeDialog(items[randomIndex]);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}