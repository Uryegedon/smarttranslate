import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/themeprovider.dart';
import 'pages.dart'; // Ensure this is the correct path to ProfileScreen

Future<void> clearSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint(
      'If you are running on Web/Windows, you need to run `flutterfire configure` and pass options.',
    );
  }

  // Comment out for production - only for debugging
  // await clearSharedPreferences();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const SmartTranslateApp(),
    ),
  );
}

class SmartTranslateApp extends StatefulWidget {
  const SmartTranslateApp({super.key});

  @override
  State<SmartTranslateApp> createState() => _SmartTranslateAppState();
}

class _SmartTranslateAppState extends State<SmartTranslateApp> {
  late final Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _getInitialRoute();
  }

  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isGuest = prefs.getBool('isGuest') ?? false;

    if (isLoggedIn || isGuest) {
      return '/translate';
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeProvider.themeMode == ThemeMode.dark
                            ? themeProvider.darkTheme.colorScheme.primary
                            : themeProvider.lightTheme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'SmartPath Translator',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeAnimationDuration: const Duration(milliseconds: 120),
              themeAnimationCurve: Curves.easeOut,
              initialRoute: snapshot.data,
              routes: {
                '/': (context) => const WelcomePage(),
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => SignupPage(),
                '/translate': (context) => TranslatorScreen(),
                '/minigames': (context) => GameSelectionScreen(),
                '/profile': (context) => ProfileScreen(),
                '/soundandnotif': (context) => SoundNotificationPage(),
                '/langpref': (context) => LanguagePreferencesScreen(),
                '/wordmatching': (context) => GuessLanguageScreen(),
                '/wordscramble': (context) => WordScrambleScreen(),
                '/flashcards': (context) => FlashCardsScreen(),
                '/wordmatchingpairs': (context) => WordMatchingScreen(),
                '/camera': (context) => CameraOcrPage(),
                '/ocrsettings': (context) => OcrSettingsPage(),
                '/themesettings': (context) => ThemeSettingsPage(),
                '/offlinedownloads': (context) => OfflineDownloadsPage(),
              },
            );
          },
        );
      },
    );
  }
}
