import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _selectedLocation;
  late final MapController _mapController;
  LatLng _mapCenter =
      const LatLng(37.7749, -122.4194); // Default center (San Francisco)
  bool _isLoading = true;
  LatLng? _userLocation;
  List<LatLng> _route = []; // List to store the route coordinates

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _locateUser();
  }

  Future<void> _locateUser() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled. Please enable them.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showErrorDialog(
            'Location permission is required to use this feature.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
          'Current Position: ${position.latitude}, ${position.longitude}'); // Debugging log

      final userLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _userLocation = userLocation;
        _mapCenter = userLocation;
        _isLoading = false;
      });

      _mapController.move(userLocation, 15.0);

      // Fetch the route from the user's location to the selected location
      if (_selectedLocation != null) {
        _fetchRoute(userLocation, _selectedLocation!);
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch location. Please try again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    // Replace with your API endpoint and API key
    const apiUrl =
        'https://api.openrouteservice.org/v2/directions/foot-walking';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization':
            'your-api-key', // Use your OpenRouteService API Key here
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routeCoordinates = data['features'][0]['geometry']['coordinates']
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();

      setState(() {
        _route = routeCoordinates;
      });
    } else {
      _showErrorDialog('Failed to fetch the route. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  // Fetch the route once the destination is selected
                  if (_userLocation != null) {
                    _fetchRoute(_userLocation!, point);
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.blue,
                        size: 15.0,
                      ),
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: _selectedLocation != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, _selectedLocation);
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm Destination'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
