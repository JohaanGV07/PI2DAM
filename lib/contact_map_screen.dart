// lib/contact_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ContactMapScreen extends StatelessWidget {
  const ContactMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Coordenadas de ejemplo (Plaza del Ayuntamiento, Valencia)
    // ¡Cámbialas por las de tu cafetería!
    final LatLng cafeLocation = LatLng(39.458090, -0.350943);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Encuéntranos"),
      ),
      body: Column(
        children: [
          // --- Mapa de OpenStreetMap ---
          Expanded(
            flex: 3, // El mapa ocupa más espacio
            child: FlutterMap(
              options: MapOptions(
                initialCenter: cafeLocation,
                initialZoom: 16.0,
              ),
              children: [
                // Capa de OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app', // Cambia esto por tu package
                ),
                // Marcador en la ubicación
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: cafeLocation,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red.shade700,
                        size: 45.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- Información de Contacto ---
          Expanded(
            flex: 2, // La info de contacto ocupa menos
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.location_city),
                    title: Text("Nuestra Dirección"),
                    subtitle: Text("Camins al Grau, 46023 Valencia"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text("Teléfono"),
                    subtitle: Text("+34 960 123 456"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.alternate_email),
                    title: Text("Email"),
                    subtitle: Text("coffeexpress@gmail.com"),
                  ),
                  Divider(),
                   ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text("Horario"),
                    subtitle: Text("Lunes a Viernes: 08:00 - 20:00"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}