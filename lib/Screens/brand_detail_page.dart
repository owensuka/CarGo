import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrandDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String brandId = Get.arguments; // Retrieve brand ID

    return Scaffold(
      appBar: AppBar(
        title: Text("Brand Details"),
      ),
      body: Center(
        child: Text('Details for Brand ID: $brandId'),
      ),
    );
  }
}
