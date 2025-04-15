import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized before Firebase
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(SmartTranslateApp());
}

class SmartTranslateApp extends StatelessWidget {
  const SmartTranslateApp({super.key});

  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isGuest = prefs.getBool('isGuest') ?? false;

    if (isLoggedIn || isGuest) {
      return '/translate'; // Redirect to TranslatorScreen
    }
    return '/'; // Redirect to WelcomePage
  }


@override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading indicator
        }
        return MaterialApp(
          title: 'SmartPath Translator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
          ),
          initialRoute: snapshot.data,
          routes: {
            '/': (context) => WelcomePage(),
            '/login': (context) => LoginScreen(),
            '/signup': (context) => SignupPage(),
            '/translate': (context) => TranslatorScreen(),
            '/minigames': (context) => GameSelectionScreen(),
            '/profile': (context) => ProfileScreen(),
            '/soundandnotif': (context) => SoundNotificationPage(),
            '/langpref': (context) => LanguagePreferencesScreen(),
            '/wordmatching': (context) => GuessLanguageScreen(),
          },
        );
      },
    );
  }
}