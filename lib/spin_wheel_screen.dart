import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
// 1. Importamos SharedPreferences
import 'package:shared_preferences/shared_preferences.dart'; 

class SpinWheelScreen extends StatefulWidget {
  final String username;
  // 2. Recibimos el userId
  final String userId; 

  const SpinWheelScreen({
    super.key, 
    required this.username,
    required this.userId, // Lo hacemos obligatorio
  });

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  final StreamController<int> _selected = BehaviorSubject<int>();

  final List<String> items = [
    '10% DTO',
    'Sigue intentando 😢',
    'Capucchino Gratis',
    '5% DTO',
    'Sigue intentando 😢',
    'Postre Gratis',
  ];

  // --- 3. Variables de Estado para el Límite Diario ---
  bool _canSpin = false;
  Duration _remainingTime = Duration.zero;
  Timer? _countdownTimer;
  // Clave única para guardar en SharedPreferences
  late final String _lastSpinKey;

  @override
  void initState() {
    super.initState();
    // Creamos una clave única por usuario
    _lastSpinKey = 'lastSpinTimestamp_${widget.userId}';
    _checkLastSpin();
  }

  @override
  void dispose() {
    _selected.close();
    _countdownTimer?.cancel(); // Cancelamos el timer
    super.dispose();
  }

  // --- 4. Lógica para comprobar el último giro ---
  Future<void> _checkLastSpin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSpinString = prefs.getString(_lastSpinKey);

    if (lastSpinString == null) {
      // Nunca ha girado
      setState(() {
        _canSpin = true;
      });
      return;
    }

    final DateTime lastSpinTime = DateTime.parse(lastSpinString);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(lastSpinTime);

    if (difference.inHours >= 24) {
      // Ya han pasado 24h
      setState(() {
        _canSpin = true;
      });
    } else {
      // Aún no puede girar, calculamos el tiempo restante
      setState(() {
        _canSpin = false;
        _remainingTime = const Duration(hours: 24) - difference;
      });
      _startCountdown();
    }
  }

  // --- 5. Iniciar la cuenta regresiva (Timer) ---
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _canSpin = true;
        });
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  // --- 6. Función para guardar el giro y empezar el contador ---
  Future<void> _spinWheel() async {
    // Guardamos la hora actual
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSpinKey, DateTime.now().toIso8601String());

    // Empezamos el contador
    setState(() {
      _canSpin = false;
      _remainingTime = const Duration(hours: 24);
    });
    _startCountdown();

    // Lógica del giro
    final int randomIndex = Fortune.randomInt(0, items.length);
    _selected.add(randomIndex);

    final String prize = items[randomIndex];

    // Mostramos el diálogo DESPUÉS de que la ruleta gire
    Future.delayed(const Duration(seconds: 4), () {
      _showPrizeDialog(prize);
      
      // TODO: Aquí llamaremos al servicio para guardar el premio
      // _prizeService.addPrizeToUser(widget.userId, prize);
    });
  }

  // --- 7. Formatear la duración del Timer ---
  String _formatDuration(Duration d) {
    // Formato HH:MM:SS
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }


  void _showPrizeDialog(String prize) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar pulsando fuera
      builder: (ctx) => AlertDialog(
        title: const Text("¡Felicidades!"),
        content: Text("¡Has ganado: $prize!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
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

            // --- La Ruleta (se queda igual) ---
            SizedBox(
              height: 300,
              width: 300,
              child: FortuneWheel(
                selected: _selected.stream,
                animateFirst: false,
                items: [
                  for (var item in items)
                    FortuneItem(
                      child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: FortuneItemStyle(
                        color: items.indexOf(item) % 2 == 0 ? Colors.blue.shade100 : Colors.blue.shade300,
                        borderColor: Colors.blue.shade700,
                        borderWidth: 2,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 8. Lógica del Botón/Contador ---
            if (_canSpin)
              // Si SÍ puede girar, muestra el botón
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("¡GIRAR!", style: TextStyle(fontSize: 20)),
                onPressed: _spinWheel,
              )
            else
              // Si NO puede girar, muestra la cuenta regresiva
              Column(
                children: [
                  const Text("Próximo giro disponible en:", style: TextStyle(fontSize: 16)),
                  Text(
                    _formatDuration(_remainingTime),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}