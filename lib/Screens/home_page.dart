import 'package:cargo/Screens/carspage.dart';
import 'package:cargo/Screens/map_page.dart';
import 'package:cargo/Screens/profile_page.dart';
import 'package:cargo/widgets/most_rented_cars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicons/unicons.dart';

class HomePage extends StatefulWidget {
  final String role;

  const HomePage({Key? key, required this.role}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeContent(role: widget.role),
      const CarsPage(),
      const MapPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("CarGo",
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Text("Rent your favorite cars with ease!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: GoogleFonts.poppins(fontSize: 16)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(UniconsLine.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(UniconsLine.car), label: 'Cars'),
              BottomNavigationBarItem(
                  icon: Icon(UniconsLine.map), label: 'Map'),
              BottomNavigationBarItem(
                  icon: Icon(UniconsLine.user), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

/// **🏠 Home Content Widget - Contains Custom Shape, Top Brands & Most Rented Cars**
class _HomeContent extends StatelessWidget {
  final String role;

  const _HomeContent({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildCustomShape(context), // ✅ Custom shape with Top Brands inside
        Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text("CarGo",
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            const SizedBox(height: 250), // ✅ Adjusted space for shape
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("Most Rented Cars",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    MostRentedCars(), // ✅ Now using the separate file
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// **🎨 Custom Curved Shape with Top Brands Inside**
  Widget _buildCustomShape(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100), // Space from AppBar
          Text(
            "Welcome to CarGo Rent!",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Find and rent the best cars at affordable prices.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Top Brands",
            style: GoogleFonts.poppins(
              fontSize: 20, // ✅ Readable size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20), // Space before Top Brands
          SizedBox(
            height: 100, // ✅ Ensure enough space for Top Brands
            child: _buildTopBrands(),
          ),
        ],
      ),
    );
  }

  /// **🏆 Top Brands Section**
  Widget _buildTopBrands() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('top_brands').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No top brands available"));
        }

        List<DocumentSnapshot> brands = snapshot.data!.docs;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: brands.length,
          itemBuilder: (context, index) {
            var brand = brands[index];

            // Safely access brand fields
            String brandName = brand['name'] ?? 'Unknown';
            String brandLogo = brand['logo'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0), // Add horizontal spacing
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: brandLogo.isNotEmpty
                        ? NetworkImage(brandLogo)
                        : const AssetImage("assets/default_brand.png")
                            as ImageProvider, // Fallback image
                  ),
                  const SizedBox(height: 5),
                  Text(
                    brandName,
                    style:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
