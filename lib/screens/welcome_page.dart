import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void continueAsGuest(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    await prefs.setBool('isLoggedIn', false);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/translate');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with opacity
          Opacity(
            opacity: 0.1, // Adjust opacity here
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Welcome_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Foreground content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to the", style: TextStyle(fontSize: 18)),
              Text(
                "SmartPath Translator",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text("Sign Up"),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text("Log In"),
                  ),
                ],
              ),
            ],
          ),
          // Positioned widget for "Continue as Guest"
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                // Navigate to TranslatorScreen as guest
                continueAsGuest(context);
              },
              child: Text(
                "Continue as Guest",
                style: TextStyle(
                  color: Colors.black54, // Change text color here
                  fontSize: 16, // Change font size here
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
