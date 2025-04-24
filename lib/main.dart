import 'package:cargo/Screens/add_brand_page.dart';
import 'package:cargo/Screens/brand_detail_page.dart';
import 'package:cargo/Screens/home_page.dart';
import 'package:cargo/Screens/signup_page.dart';
import 'package:cargo/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // ✅ Auth checking widget
      getPages: [
        GetPage(
          name: '/home',
          page: () {
            final role =
                Get.arguments as String? ?? 'user'; // Default to 'user'
            return HomePage(role: role);
          },
        ),
        GetPage(name: '/signUp', page: () => SignUpPage()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/addBrand', page: () => AddBrandPage()),
      ],
    );
  }
}

/// ✅ Automatically redirects users based on login status
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          return FutureBuilder<String>(
            future: _getUserRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (!roleSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return HomePage(role: roleSnapshot.data!);
            },
          );
        } else {
          // User is NOT logged in
          return LoginPage();
        }
      },
    );
  }

  /// ✅ Fetch the user's role from Firestore
  Future<String> _getUserRole(User user) async {
    try {
      var doc = await FirebaseAuth.instance.currentUser;
      return doc != null ? "user" : "admin"; // Modify logic based on Firestore
    } catch (e) {
      return "user"; // Default to 'user' in case of error
    }
  }
}
