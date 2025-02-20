import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'car_detail_page.dart';
import 'add_car_page.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  _CarsPageState createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    checkIfAdmin();
  }

  void checkIfAdmin() {
    if (user != null && user!.email == "admin@gmail.com") {
      setState(() {
        isAdmin = true;
      });
    }
  }

  void deleteCar(String carId) async {
    try {
      await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
      Get.snackbar("Success", "Car deleted successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete car");
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("All Cars", style: GoogleFonts.poppins()),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cars').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading cars"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No cars available"));
          }

          var cars = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                var car = cars[index];
                var carData =
                    car.data() as Map<String, dynamic>?; // Ensure it's a Map

                return GestureDetector(
                  onTap: () {
                    Get.to(() => CarDetailPage(carId: car.id));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: Image.network(
                                  carData?['image'] ?? '', // Handle null
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.car_repair, size: 50),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    carData?['name'] ?? "Unknown Car",
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    (carData?.containsKey('price_per_km') ??
                                            false)
                                        ? "\$${carData!['price_per_km']} per km"
                                        : "Price not available",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isAdmin)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Get.defaultDialog(
                                  title: "Delete Car",
                                  middleText:
                                      "Are you sure you want to delete this car?",
                                  textConfirm: "Yes",
                                  textCancel: "No",
                                  confirmTextColor: Colors.white,
                                  onConfirm: () {
                                    deleteCar(car.id);
                                    Get.back();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Get.to(() => AddCarPage());
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
