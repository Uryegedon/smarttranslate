import 'package:flutter/material.dart';
import 'package:smarttranslate_app/screens/welcome_page.dart';
import 'package:smarttranslate_app/screens/login_page.dart';
import 'package:smarttranslate_app/screens/Signup_page.dart';
 
void main() {
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
      routes: {
        '/': (context) => WelcomePage(), // Corrected from WelcomeScreen to WelcomePage
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupPage(), // Add this line for the signup page
        // Add more routes like '/signup' and '/home' later
      },
    );
  }
}