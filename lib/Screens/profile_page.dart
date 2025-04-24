import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  String name = "";
  String phone = "";
  String address = "";
  String? profilePicUrl; // Nullable string
  List<String> rentedCarIds = []; // List to store rented car IDs
  List<Map<String, dynamic>> rentedCars = []; // List to store car details

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user!.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        name = userData['name'] ?? "No Name";
        phone = userData['phone'] ?? "No Phone Number";
        address = userData['address'] ?? "No Address";
        rentedCarIds = List<String>.from(userData['rentedCars'] ?? []);
      });

      fetchRentedCars();
    }
  }

  Future<void> fetchRentedCars() async {
    if (rentedCarIds.isNotEmpty) {
      List<Map<String, dynamic>> cars = [];
      for (String carId in rentedCarIds) {
        DocumentSnapshot carDoc =
            await _firestore.collection('cars').doc(carId).get();
        if (carDoc.exists) {
          cars.add(carDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        rentedCars = cars;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            GestureDetector(
              onTap: pickProfileImage,
              child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(profilePicUrl!),
                      onBackgroundImageError: (_, __) {
                        setState(() {
                          profilePicUrl =
                              null; // Reset to default if error occurs
                        });
                      },
                    )
                  : _defaultProfileImage(),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: pickProfileImage,
              child: Text("Change Profile Picture",
                  style: TextStyle(color: Colors.blue)),
            ),

            const SizedBox(height: 20),

            // Profile Details
            buildProfileDetail("Name", name),
            buildProfileDetail("Phone Number", phone),
            buildProfileDetail("Address", address),

            const SizedBox(height: 20),

            // Rented Cars
            rentedCars.isEmpty
                ? Text("You have not rented any cars yet.")
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rented Cars",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      for (var car in rentedCars)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: car['image'] != null && car['image'] is List
                              ? (car['image'] as List).isNotEmpty
                                  ? Image.network(
                                      car['image']
                                          [0], // First image in the array
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.car_repair)
                              : const Icon(Icons.car_repair),
                          title: Text(car['name'] ?? 'Unknown Car'),
                          subtitle: Text(
                              "\₹${car['price_per_km']?.toStringAsFixed(2)} per km"),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> pickProfileImage() async {
    // Image picker code (not implemented here)
  }

  Widget _defaultProfileImage() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300], // Placeholder color
      child: Icon(Icons.person, size: 60, color: Colors.white),
    );
  }

  Widget buildProfileDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
          ),
          child: Text(value.isNotEmpty ? value : "Not available"),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
