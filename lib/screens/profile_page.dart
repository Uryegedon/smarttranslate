import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themeawarewidget.dart'; // Import the theme-aware widgets

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/translate');
        break;
      case 1:
        Navigator.pushNamed(context, '/camera');
        break;
      case 2:
        Navigator.pushNamed(context, '/minigames');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username; // Variable to store the username
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // Fetch the username when the screen loads
  }

  Future<void> _fetchUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isGuest = prefs.getBool('isGuest') ?? false;

      if (isGuest) {
        setState(() {
          username = 'Guest User'; // Set username for guest users
          isLoading = false;
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          username = doc['username']; // Retrieve the username from Firestore
          isLoading = false;
        });
      } else {
        setState(() {
          username = 'Unknown User'; // Fallback if no user is logged in
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        username = 'Unknown User'; // Fallback if an error occurs
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeAwareScaffold(
      appBar: ThemeAwareAppBar(
        leading: SizedBox(),
        title: ThemeAwareText(
          'Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ThemeAwareWidget(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Section (Profile picture aligned with username)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/avatar.jpg'),
                    ),
                    const SizedBox(width: 20),
                    // Username and "View Profile" button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemeAwareText(
                          isLoading
                              ? 'Loading...' // Show loading text while fetching
                              : username ?? 'Unknown User', // Display username
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile editing page
                            if (username == 'Guest User') {
                              Navigator.pushNamed(context, '/login');
                            } else {
                              Navigator.pushNamed(context, '/signup');
                            }
                          },
                          child: ThemeAwareText(
                            username == 'Guest User' ? 'Log in' : 'View Profile',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.underline, // Underline the text
                              color: Colors.blue, // Optional: Add a color for the text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              // Settings and Options below the profile
              Expanded(
                child: ListView(
                  children: [
                    // Language Preferences
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text("Language Preferences"),
                      onTap: () {
                        Navigator.pushNamed(context, '/langpref');
                      },
                    ),
                    // OCR Settings
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text("OCR Settings"),
                      onTap: () {
                        Navigator.pushNamed(context, '/ocrsettings');
                      },
                    ),
                    // Sound and Notifications
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text("Sound and Notifications"),
                      onTap: () {
                        Navigator.pushNamed(context, '/soundandnotif');
                      },
                    ),
                    // Theme Settings
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text("Theme Settings"),
                      onTap: () {
                        Navigator.pushNamed(context, '/themesettings');
                      },
                    ),
                    // Help & Support
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Help and Support"),
                      onTap: () {
                        // Navigate to help and support
                      },
                    ),
                    // Privacy Settings
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text("Privacy Settings"),
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                    // Log Out
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Log out"),
                      onTap: () {
                        FirebaseAuth.instance.signOut().then((_) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 1, // The initial selected index
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.blue[300],
  selectedItemColor: Colors.black,
  unselectedItemColor: Colors.white.withOpacity(0.7),
  selectedFontSize: 14, // Optional: You can leave this out as labels are removed
  unselectedFontSize: 12, // Optional: You can leave this out as labels are removed
  onTap: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/translate');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/camera');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/minigames');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.translate, size: 30),
      label: '', // Empty label
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt, size: 30),
      label: '', // Empty label
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.extension, size: 30),
      label: '', // Empty label
    ),
    BottomNavigationBarItem(
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
      label: '', // Empty label
    ),
  ],
),

    );
  }
}