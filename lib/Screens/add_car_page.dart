import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  _AddCarPageState createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  List<File> _images = [];
  bool _isUploading = false;

  /// Pick multiple images from the gallery
  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  /// Uploads images to Firebase Storage and returns their URLs
  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (var image in _images) {
      String fileName = "cars/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      urls.add(imageUrl);
    }
    return urls;
  }

  /// Adds car data to Firestore
  Future<void> _addCar() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _powerController.text.isEmpty ||
        _mileageController.text.isEmpty ||
        _images.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields and select images");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedImageUrls = await _uploadImages();

      String carId = FirebaseFirestore.instance.collection('cars').doc().id;
      await FirebaseFirestore.instance.collection('cars').doc(carId).set({
        'id': carId,
        'name': _nameController.text,
        'price_per_km': double.parse(_priceController.text),
        'power': _powerController.text,
        'mileage': _mileageController.text,
        'images': uploadedImageUrls, // Storing multiple image URLs
      });

      Get.snackbar("Success", "Car added successfully");
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Failed to add car");
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Car", style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _images.isEmpty
                      ? const Center(
                          child: Text("Tap to pick images",
                              style: TextStyle(fontSize: 16)),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image.file(_images[index],
                                  height: 150, width: 150, fit: BoxFit.cover),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Car Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price Per Km"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _powerController,
                decoration: const InputDecoration(labelText: "Power (HP)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: "Mileage (km/l)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _addCar,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text("Add Car"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
