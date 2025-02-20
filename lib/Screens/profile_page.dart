import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

        // Check if the profilePic field exists before accessing it
        profilePicUrl =
            userData.containsKey('profilePic') ? userData['profilePic'] : null;
      });
    }
  }

  Future<void> pickProfileImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Upload to Firebase Storage (Not implemented here)
      // Example: profilePicUrl = await uploadImageToFirebase(imageFile);

      setState(() {
        profilePicUrl = pickedFile.path; // Temporary display
      });

      await _firestore.collection('users').doc(user!.uid).update({
        'profilePic': profilePicUrl,
      });

      Get.snackbar("Success", "Profile picture updated",
          backgroundColor: Colors.green, colorText: Colors.white);
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
          ],
        ),
      ),
    );
  }

  Widget _defaultProfileImage() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300], // Placeholder color
      child: SvgPicture.asset(
        'assets/images/profile-picture.svg', // Ensure the SVG exists in assets
        width: 80,
        height: 80,
        fit: BoxFit.contain,
      ),
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
