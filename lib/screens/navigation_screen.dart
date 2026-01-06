import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import '../utils/app_styles.dart';
import 'dart:async';

class NavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String shopName;
  final String shopAddress;

  const NavigationScreen({
    Key? key,
    required this.destinationLat,
    required this.destinationLng,
    required this.shopName,
    required this.shopAddress,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String _distance = '';
  String _duration = '';
  String _errorMessage = '';
  List<Map<String, dynamic>> _steps = [];
  int _currentStepIndex = 0;
  bool _isFollowingUser = true;
  bool _hasArrived = false;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    await _getUserLocation();
    if (_userLocation != null) {
      await _fetchRoute();
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Her 10 metrede bir güncelle (daha optimize)
      ),
    ).listen((Position position) {
      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = newLocation;
      });

      // Sadece takip modundaysa haritayı hareket ettir
      if (_isFollowingUser) {
        _mapController.move(newLocation, 17.0);
      }

      // Varış kontrolü (sadece henüz varmadıysa)
      if (!_hasArrived) {
        _checkArrival(position);
      }

      // Adım ilerlemesi kontrolü
      _checkStepProgress(position);
    });
  }

  void _checkStepProgress(Position currentPos) {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length - 1) return;

    // Bir sonraki adımın konumu varsa kontrol et
    final nextStep = _steps[_currentStepIndex + 1];
    if (nextStep['location'] == null) return;

    final nextStepLoc = nextStep['location'] as LatLng;

    double distanceToNextStep = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      nextStepLoc.latitude,
      nextStepLoc.longitude,
    );

    // 30 metreden yakınsa bir sonraki adıma geç
    if (distanceToNextStep < 30) {
      setState(() {
        if (_currentStepIndex < _steps.length - 1) {
          _currentStepIndex++;
        }
      });
    }
  }

  void _checkArrival(Position currentPos) {
    double distanceToTarget = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    // 25 metreden az kaldıysa varış bildirimi
    if (distanceToTarget < 25) {
      setState(() {
        _hasArrived = true;
      });
      _showArrivalDialog();
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "You've Arrived!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.shopName} is right here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.pop(context); // Navigation ekranını kapat
              },
              child: const Text(
                "Finish",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isLoadingRoute = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not get your location: $e';
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_userLocation == null) return;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${widget.destinationLng},${widget.destinationLat}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          // Adım adım talimatlar
          final legs = route['legs'] as List;
          _steps = [];

          for (var leg in legs) {
            final steps = leg['steps'] as List;
            for (var step in steps) {
              // Konum bilgisi varsa ekle
              LatLng? stepLocation;
              if (step['maneuver'] != null &&
                  step['maneuver']['location'] != null) {
                final loc = step['maneuver']['location'];
                stepLocation = LatLng(loc[1], loc[0]);
              }

              _steps.add({
                'instruction': step['maneuver']?['modifier'] ?? 'continue',
                'distance': step['distance'] ?? 0.0,
                'duration': step['duration'] ?? 0.0,
                'name': step['name'] ?? 'Unknown road',
                'location': stepLocation,
              });
            }
          }

          setState(() {
            _routePoints = coordinates
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList();

            final distanceMeters = route['distance'];
            _distance = distanceMeters > 1000
                ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
                : '${distanceMeters.toStringAsFixed(0)} m';

            final durationSeconds = route['duration'];
            _duration = durationSeconds > 3600
                ? '${(durationSeconds / 3600).toStringAsFixed(1)} hours'
                : '${(durationSeconds / 60).toStringAsFixed(0)} min';

            _isLoadingRoute = false;
          });

          _fitMapToRoute();
        } else {
          _useFallbackRoute();
        }
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    setState(() {
      _routePoints = [
        _userLocation!,
        LatLng(widget.destinationLat, widget.destinationLng)
      ];
      _distance = _calculateDistance(
          _userLocation!, LatLng(widget.destinationLat, widget.destinationLng));
      _duration = 'Estimated';
      _isLoadingRoute = false;
    });
    _fitMapToRoute();
  }

  String _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLon = _degreesToRadians(end.longitude - start.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) *
            math.cos(_degreesToRadians(end.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    return distance > 1
        ? '${distance.toStringAsFixed(1)} km'
        : '${(distance * 1000).toStringAsFixed(0)} m';
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    final distance = _calculateDistanceInKm(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    double zoom = 13;
    if (distance > 100) {
      zoom = 8;
    } else if (distance > 50) {
      zoom = 10;
    } else if (distance > 20) {
      zoom = 11;
    } else if (distance > 10) {
      zoom = 12;
    }

    _mapController.move(center, zoom);
  }

  double _calculateDistanceInKm(LatLng start, LatLng end) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLon = _degreesToRadians(end.longitude - start.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) *
            math.cos(_degreesToRadians(end.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  String _getDirectionIcon(String instruction) {
    if (instruction.contains('left')) return '⬅️';
    if (instruction.contains('right')) return '➡️';
    if (instruction.contains('straight')) return '⬆️';
    return '▶️';
  }

  void _showAllSteps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Turn-by-Turn Directions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == _currentStepIndex;
                  final step = _steps[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? kOrangeButton.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? kOrangeButton : Colors.grey.shade200,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getDirectionIcon(step['instruction']),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['name'],
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrent ? kOrangeButton : kPrimaryBlue,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${(step['distance']).toStringAsFixed(0)} m",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Icon(Icons.navigation, color: kOrangeButton, size: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Harita
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ??
                  LatLng(widget.destinationLat, widget.destinationLng),
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                // Kullanıcı haritayı elle hareket ettirdiyse takibi durdur
                if (hasGesture) {
                  setState(() => _isFollowingUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.stash.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6,
                      color: kOrangeButton,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimaryBlue.withOpacity(0.3),
                          border: Border.all(color: kPrimaryBlue, width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Marker(
                    point: LatLng(widget.destinationLat, widget.destinationLng),
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // "My Location" butonu (sadece takip modunda değilken görünür)
          if (!_isFollowingUser)
            Positioned(
              right: 16,
              bottom: 280,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() => _isFollowingUser = true);
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 17.0);
                  }
                },
                child: Icon(Icons.my_location, color: kPrimaryBlue),
              ),
            ),

          // Üst panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Icon(Icons.arrow_back, color: kPrimaryBlue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shopName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.shopAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Alt panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingRoute)
                      Column(
                        children: [
                          CircularProgressIndicator(color: kOrangeButton),
                          const SizedBox(height: 12),
                          Text(
                            'Calculating route...',
                            style: TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoCard(
                                  Icons.straighten, 'Distance', _distance),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              _buildInfoCard(
                                  Icons.access_time, 'Duration', _duration),
                            ],
                          ),
                          if (_steps.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kLightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: kOrangeButton.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _getDirectionIcon(_steps[_currentStepIndex]
                                        ['instruction']),
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _steps[_currentStepIndex]['name'],
                                          style: TextStyle(
                                            color: kPrimaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(_steps[_currentStepIndex]['distance'] / 1000).toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _showAllSteps(context),
                              icon: Icon(Icons.list, color: kOrangeButton),
                              label: Text(
                                "View All Steps",
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: kOrangeButton, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: kPrimaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
