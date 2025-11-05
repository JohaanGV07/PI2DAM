// lib/address_picker_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressPickerMapScreen extends StatefulWidget {
  final LatLng initialLocation;

  // Recibe la ubicación inicial (la de la cafetería) para centrar el mapa
  const AddressPickerMapScreen({super.key, required this.initialLocation});

  @override
  State<AddressPickerMapScreen> createState() => _AddressPickerMapScreenState();
}

class _AddressPickerMapScreenState extends State<AddressPickerMapScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  // Esta función se llama cada vez que el usuario toca el mapa
  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
    _mapController.move(_selectedLocation!, 16.0); // Centra el mapa en el pin
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona la dirección de entrega"),
      ),
      body: Stack(
        children: [
          // El Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 16.0,
              onTap: _handleTap, // ¡Aquí está la magia!
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app', // Asegúrate que coincida
              ),
              // El Pin (Marcador)
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _selectedLocation!,
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
          // Botón de Confirmar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Confirmar esta ubicación"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Devolvemos las coordenadas (LatLng) a la pantalla anterior
                if (_selectedLocation != null) {
                  Navigator.pop(context, _selectedLocation);
                }
              },
            ),
          )
        ],
      ),
    );
  }
}