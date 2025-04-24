import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrandDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve the arguments passed from HomePage
    final Map<String, dynamic> brandData = Get.arguments;
    String brandName = brandData['name'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(brandName),
      ),
      body: Column(
        children: [
          // Show the brand logo

          const SizedBox(height: 20),

          // Display list of cars under the brand
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .where('brand', isEqualTo: brandName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No cars available for this brand"));
                }

                List<DocumentSnapshot> cars = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    var car = cars[index];

                    // Safely access car details
                    String carName = car['name'] ?? 'Unknown Car';
                    String carImage = car['image'] ?? '';
                    double carPrice = car['price']?.toDouble() ?? 0.0;

                    return GestureDetector(
                      onTap: () {
                        // Navigate to the car detail page
                        // You can pass the car ID to CarDetailPage
                        String carId = car.id;
                        Get.toNamed('/carDetail', arguments: {
                          'carId': carId,
                        });
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display car image
                            carImage.isNotEmpty
                                ? Image.network(
                                    carImage,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, size: 100),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display car name and price
                                  Text(
                                    carName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "\$${carPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
