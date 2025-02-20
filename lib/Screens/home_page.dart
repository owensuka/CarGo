import 'package:cargo/Screens/carspage.dart';
import 'package:cargo/Screens/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicons/unicons.dart';

class HomePage extends StatefulWidget {
  final String role; // Role passed from login

  const HomePage({Key? key, required this.role}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _pages = []; // Use `late` to initialize after `widget.role`

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _HomeContent(role: widget.role), // ✅ Use widget.role
      const CarsPage(),
      const Center(child: Text('Map')),
      ProfilePage(),
    ]);
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
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xff06090d) : const Color(0xfff8f8f8),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(UniconsLine.bars,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.orange,
              ),
              child: Text(
                'Menu',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(UniconsLine.user, color: Colors.blue),
              title: Text('Profile', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(UniconsLine.signout, color: Colors.red),
              title: Text('Logout', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: isDarkMode ? Colors.blue : Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(UniconsLine.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(UniconsLine.car), label: 'Cars'),
          BottomNavigationBarItem(icon: Icon(UniconsLine.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(UniconsLine.user), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String role;

  const _HomeContent({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildTopBrands(context),
      ],
    );
  }

  Widget _buildTopBrands(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('top_brands').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading data"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No top brands available"));
        }

        List<DocumentSnapshot> brands = snapshot.data!.docs;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Top Brands",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  if (role == 'admin') // ✅ Check role before showing Add button
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.orange),
                      onPressed: () {
                        Get.toNamed('/addBrand');
                      },
                    ),
                ],
              ),
              SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    var brand = brands[index];
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed('/brandDetails', arguments: brand.id);
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(brand['logo']),
                            radius: 30,
                          ),
                          SizedBox(height: 5),
                          Text(brand['name'],
                              style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
