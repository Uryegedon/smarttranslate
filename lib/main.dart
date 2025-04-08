import 'package:flutter/material.dart';
import 'package:smarttranslate_app/screens/welcome_page.dart';
import 'package:smarttranslate_app/screens/login_page.dart';
import 'package:smarttranslate_app/screens/Signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smarttranslate_app/screens/translate_page.dart';
import 'package:smarttranslate_app/screens/minigames_page.dart';
import 'package:smarttranslate_app/screens/profile_page.dart';
import 'package:smarttranslate_app/screens/soundandnotif_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized before Firebase
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(SmartTranslateApp());
}

class SmartTranslateApp extends StatelessWidget {
  const SmartTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPath Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',

      //routing to diff pages
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupPage(),
        '/translate': (context) => TranslatorScreen(), 
        '/minigames': (context) => GameSelectionScreen(), 
        '/profile': (context) => ProfileScreen(),
        '/soundandnotif': (context) => SoundNotificationPage(), 
      },
    );
  }
}