import 'package:flutter/material.dart';

class  WelcomePage  extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  
  Widget build(BuildContext context) {
    print('LoginScreen loaded');
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.teal[100],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome to the", style: TextStyle(fontSize: 18)),
                Text("SmartPath Translator",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia')),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        print('Navigating to SignupPage');
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
          ),

          // Guest "X" Button
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // Navigate to home screen as guest
                // Navigator.pushNamed(context, '/home');
              },
              child: Icon(Icons.close, color: Colors.black54, size: 28),
            ),
          )
        ],
      ),
    );
  }
}
