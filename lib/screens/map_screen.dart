import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Başlangıç konumu (Muğla/Kötekli civarı)
  static const latlong.LatLng _initialPosition =
      latlong.LatLng(37.1683, 28.3931);

  @override
  Widget build(BuildContext context) {
    // Scaffold yerine doğrudan Stack veya Container döndürüyoruz
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _initialPosition, // initialCenter kullanın (v6+)
            initialZoom: 14.0,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.stash.app.emre', // Burası kalsın
            ),
            // MarkerLayer vb. ekleyebilirsin
            const MarkerLayer(
              markers: [
                Marker(
                  point: latlong.LatLng(37.1683, 28.3931),
                  width: 80,
                  height: 80,
                  child: Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),

        // Arama çubuğu vb. widgetlar buraya Stack ile eklenebilir
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _mapController.move(_initialPosition, 14.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
