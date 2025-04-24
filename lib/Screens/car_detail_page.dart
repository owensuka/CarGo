import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarDetailPage extends StatefulWidget {
  final String carId; // ✅ Ensure carId is defined and required

  const CarDetailPage({super.key, required this.carId}); // ✅ Add constructor

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  Map<String, dynamic>? carData;
  List<dynamic>? images;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchCarDetails();
  }

  /// 🔥 **Fetch Car Details from Firestore**
  Future<void> fetchCarDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId) // ✅ Use widget.carId instead of Get.arguments
          .get();

      if (doc.exists) {
        setState(() {
          carData = doc.data() as Map<String, dynamic>;
          images = carData!["image"] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load car details",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> rentCar() async {
    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Get.snackbar("Error", "You need to be logged in to rent a car",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Show a confirmation dialog with advanced styling
    bool? isConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)), // Rounded corners
          elevation: 10,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Confirm Rent",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Do you want to rent this car?",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.white)),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        "Confirm",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (isConfirmed != null && isConfirmed) {
      try {
        // Store the car ID in the user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid) // Use the logged-in user's UID
            .update({
          'rentedCars': FieldValue.arrayUnion(
              [widget.carId]), // Add the car ID to the rentedCars array
        });

        // Update the rent count of the car in the 'cars' collection
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(widget.carId)
            .update({
          'rentCount': FieldValue.increment(1), // Increment the rent count
        });

        Get.snackbar("Success", "Car rented successfully!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar("Error", "Failed to rent the car",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Car Details"),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          carData!["name"] ?? "Car Details",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Image Carousel
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images!.isEmpty ? 1 : images!.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                        child: Image.network(
                          images!.isEmpty
                              ? "https://via.placeholder.com/400x300?text=No+Image"
                              : images![index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(
                                  "https://via.placeholder.com/400x300?text=No+Image"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 📄 Car Details Card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carData!["name"] ?? "Unknown Car",
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      buildDetailRow("Horsepower",
                          "${carData!["horsepower"] ?? "N/A"} HP"),
                      buildDetailRow("Price per KM",
                          "\₹${carData!["price_per_km"] ?? "N/A"}"),
                      buildDetailRow(
                          "Mileage", "${carData!["mileage"] ?? "N/A"} KM"),

                      // Real-time rent count display
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('cars')
                            .doc(widget.carId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text("Loading rent count...");
                          }

                          var carDoc = snapshot.data!;
                          int rentCount = carDoc['rentCount'] ?? 0;

                          return buildDetailRow("Times Rented", "$rentCount");
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🚀 Rent Button
            Center(
              child: ElevatedButton(
                onPressed: rentCar, // Call rentCar method when tapped
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                child: const Text(
                  "Rent Now",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🏎 **Helper Widget for Car Details**
  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700]),
          ),
          Text(
            value,
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
