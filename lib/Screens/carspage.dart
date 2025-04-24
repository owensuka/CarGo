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

  /// 🚗 **Delete Car from Firestore**
  void deleteCar(String carId) async {
    try {
      await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
      Get.snackbar("Success", "Car deleted successfully",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to delete car",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "All Cars",
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
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
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                var car = cars[index];
                var carData = car.data() as Map<String, dynamic>?;

                // ✅ **Safely Extract Image Array**
                List<String> images = [];
                if (carData?['image'] is List) {
                  images = List<String>.from(carData?['image']);
                } else if (carData?['image'] is String) {
                  images = [carData?['image']];
                }

                return GestureDetector(
                  onTap: () {
                    Get.to(() => CarDetailPage(carId: car.id));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    color: Colors.white.withOpacity(1),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: images.isNotEmpty
                                    ? Image.network(
                                        images.first,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.car_repair,
                                                    size: 50),
                                      )
                                    : const Icon(Icons.car_repair, size: 50),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
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
                                    (carData?.containsKey('pricePerKm') ??
                                            false)
                                        ? "\$${carData!['pricePerKm']} per km"
                                        : "Price not available",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // 🗑 **Admin-Only Delete Button**
                        if (isAdmin)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white, size: 20),
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

      // ➕ **Floating Button for Admin**
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Get.to(() => AddCarPage());
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
