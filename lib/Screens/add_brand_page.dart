import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBrandPage extends StatefulWidget {
  @override
  _AddBrandPageState createState() => _AddBrandPageState();
}

class _AddBrandPageState extends State<AddBrandPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController logoController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBrand() async {
    String name = nameController.text.trim();
    String logoUrl = logoController.text.trim();

    if (name.isEmpty || logoUrl.isEmpty) {
      Get.snackbar("Error", "Please fill all fields",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      await _firestore.collection('top_brands').add({
        'name': name,
        'logo': logoUrl,
      });

      Get.snackbar("Success", "Brand added successfully",
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(); // Go back to HomePage
    } catch (e) {
      Get.snackbar("Error", "Failed to add brand",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Brand")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Brand Name"),
            ),
            TextField(
              controller: logoController,
              decoration: InputDecoration(labelText: "Logo URL"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addBrand,
              child: Text("Add Brand"),
            ),
          ],
        ),
      ),
    );
  }
}
