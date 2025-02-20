import 'package:cargo/Screens/add_brand_page.dart';
import 'package:cargo/Screens/brand_detail_page.dart';
import 'package:cargo/Screens/home_page.dart';
import 'package:cargo/Screens/signup_page.dart';
import 'package:cargo/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import your Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use your generated Firebase options
  );

  runApp(MyApp()); // Running MyApp instead of GetMaterialApp directly
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Start with login instead of HomePage
      getPages: [
        GetPage(
          name: '/home',
          page: () {
            final role =
                Get.arguments as String? ?? 'user'; // Default to 'user'
            return HomePage(role: role);
          },
        ),
        GetPage(name: '/brandDetails', page: () => BrandDetailsPage()),
        GetPage(name: '/signUp', page: () => SignUpPage()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/addBrand', page: () => AddBrandPage()),
      ],
    );
  }
}
