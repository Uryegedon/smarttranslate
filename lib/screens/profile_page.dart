import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themeawarewidget.dart';
import '../widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isGuest = prefs.getBool('isGuest') ?? false;

      if (isGuest) {
        setState(() { username = 'Guest User'; isLoading = false; });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).get();
        setState(() { username = doc['username']; isLoading = false; });
      } else {
        setState(() { username = 'Unknown User'; isLoading = false; });
      }
    } catch (e) {
      setState(() { username = 'Unknown User'; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final screenHeight = MediaQuery.of(context).size.height;

    return ThemeAwareScaffold(
      body: Column(
        children: [
          // ── Teal gradient profile header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              24,
              28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withOpacity(0.82)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading ? 'Loading...' : (username ?? 'Unknown User'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              if (username == 'Guest User') {
                                Navigator.pushNamed(context, '/login');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                username == 'Guest User' ? 'Log in →' : 'Signed in ✓',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Settings list (fills remaining space) ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('General', theme),
                  const SizedBox(height: 10),
                  _settingsCard(theme, [
                    _tile(Icons.language_rounded, 'Language Preferences', theme,
                        () => Navigator.pushNamed(context, '/langpref')),
                    _divider(theme),
                    _tile(Icons.camera_alt_rounded, 'OCR Settings', theme,
                        () => Navigator.pushNamed(context, '/ocrsettings')),
                    _divider(theme),
                    _tile(Icons.volume_up_rounded, 'Sound & Notifications', theme,
                        () => Navigator.pushNamed(context, '/soundandnotif')),
                  ]),

                  const SizedBox(height: 24),
                  _sectionLabel('Appearance', theme),
                  const SizedBox(height: 10),
                  _settingsCard(theme, [
                    _tile(Icons.palette_rounded, 'Theme Settings', theme,
                        () => Navigator.pushNamed(context, '/themesettings')),
                  ]),

                  const SizedBox(height: 24),
                  _sectionLabel('Support', theme),
                  const SizedBox(height: 10),
                  _settingsCard(theme, [
                    _tile(Icons.help_outline_rounded, 'Help and Support', theme, () {}),
                    _divider(theme),
                    _tile(Icons.shield_outlined, 'Privacy Settings', theme, () {}),
                  ]),

                  const SizedBox(height: 24),
                  _settingsCard(theme, [
                    _tile(
                      Icons.logout_rounded,
                      'Log out',
                      theme,
                      () {
                        FirebaseAuth.instance.signOut().then((_) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                        });
                      },
                      iconColor: theme.colorScheme.error,
                      titleColor: theme.colorScheme.error,
                      showChevron: false,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.profile),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.hintColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    ThemeData theme,
    VoidCallback onTap, {
    Color? iconColor,
    Color? titleColor,
    bool showChevron = true,
  }) {
    final primary = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (iconColor ?? primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: iconColor ?? primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded, size: 22, color: theme.hintColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: theme.dividerColor),
    );
  }
}