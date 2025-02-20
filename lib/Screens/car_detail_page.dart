import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

class CarDetailPage extends StatefulWidget {
  final String carId;

  const CarDetailPage({Key? key, required this.carId}) : super(key: key);

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  Map<String, dynamic>? carData;

  @override
  void initState() {
    super.initState();
    fetchCarDetails();
  }

  Future<void> fetchCarDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId)
          .get();
      if (doc.exists) {
        setState(() {
          carData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load car details",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (carData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<String> images = List<String>.from(carData!["images"] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          carData!["name"] ?? "Car Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Carousel with AutoPlay
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 250,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.85,
                  ),
                  items: images.map((url) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Car Details in Grid View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GridView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                children: [
                  _buildDetailCard(
                      "Price per km", "\$${carData!["price_per_km"]}"),
                  _buildDetailCard("Power", "${carData!["power"]} HP"),
                  _buildDetailCard("Mileage", "${carData!["mileage"]} km/l"),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Rent Now Button with Animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () =>
                    Get.snackbar("Success", "Proceed to rent this car"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(
                  "Rent Now",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Google Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Pickup Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        onTap: (LatLng location) {
                          setState(() {
                            selectedLocation = location;
                          });
                        },
                        markers: selectedLocation != null
                            ? {
                                Marker(
                                  markerId: MarkerId("selected"),
                                  position: selectedLocation!,
                                )
                              }
                            : {},
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              37.7749, -122.4194), // Default to San Francisco
                          zoom: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Show Selected Location Coordinates
            if (selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget for Car Detail Card
  Widget _buildDetailCard(String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
