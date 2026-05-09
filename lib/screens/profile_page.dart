import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themeawarewidget.dart'; // Import the theme-aware widgets
import '../widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
        final doc =
            await FirebaseFirestore.instance
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
    final theme = Theme.of(context);

    return ThemeAwareScaffold(
      appBar: ThemeAwareAppBar(
        leading: SizedBox(),
        title: ThemeAwareText(
          'Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ThemeAwareWidget(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ThemeAwareText(
                              isLoading
                                  ? 'Loading...'
                                  : username ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                if (username == 'Guest User') {
                                  Navigator.pushNamed(context, '/login');
                                } else {
                                  Navigator.pushNamed(context, '/signup');
                                }
                              },
                              child: Text(
                                username == 'Guest User'
                                    ? 'Log in'
                                    : 'View Profile',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ProfileActionTile(
                icon: Icons.language,
                title: 'Language Preferences',
                onTap: () => Navigator.pushNamed(context, '/langpref'),
              ),
              _ProfileActionTile(
                icon: Icons.camera_alt,
                title: 'OCR Settings',
                onTap: () => Navigator.pushNamed(context, '/ocrsettings'),
              ),
              _ProfileActionTile(
                icon: Icons.volume_up,
                title: 'Sound and Notifications',
                onTap: () => Navigator.pushNamed(context, '/soundandnotif'),
              ),
              _ProfileActionTile(
                icon: Icons.brightness_6,
                title: 'Theme Settings',
                onTap: () => Navigator.pushNamed(context, '/themesettings'),
              ),
              _ProfileActionTile(
                icon: Icons.logout,
                title: 'Log out',
                isDestructive: true,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await FirebaseAuth.instance.signOut();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.setBool('isGuest', false);

                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.profile),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: isDestructive ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
