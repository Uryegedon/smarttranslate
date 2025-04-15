import 'package:flutter/material.dart';
import 'translate_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  // Log out the user if they are already logged in (for testing)
  void logOut() async {
    await FirebaseAuth.instance.signOut();
    print("User logged out");
  }

  void login() async {
  String input = emailController.text.trim(); // This might be an email or username
  String password = passwordController.text;

  if (input.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Username/Email and password cannot be empty")),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    String email = input;

    // 🔍 If input doesn't look like an email, treat it as a username
    if (!input.contains('@')) {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that username.',
        );
      }

      email = userQuery.docs.first['email'];
    }

    print("Logging in with email: $email");

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    Navigator.pushReplacementNamed(context, '/translate');
  } on FirebaseAuthException catch (e) {
    print("FirebaseAuthException: ${e.code} - ${e.message}");
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for that email or username.';
        break;
      case 'wrong-password':
        message = 'Wrong password.';
        break;
      case 'invalid-email':
        message = 'Invalid email format.';
        break;
      default:
        message = 'Login failed. Please check your credentials and try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    print("General error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred. Try again.")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }

  // Save the login state in SharedPreferences
  try{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacementNamed(context, '/translate');
  } catch (e) {
    print("Error saving login state: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred while saving login state.")),
    );  
  }





}



  void continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TranslatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SmartPath Translator"),
      centerTitle: true,
      automaticallyImplyLeading: false,
      ),
      
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.deepPurple),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email),
                labelText: "Username/Email",
                filled: true,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                labelText: "Password",
                filled: true,
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: Text("Log In"),
                    ),
            ),
             SizedBox(height: 20), // Space between login button and sign-up text
            TextButton(
              onPressed:(){
                Navigator.pushNamed(context, '/signup');
              },
                  // Navigate to sign-up page
              child: Text(
                'Don\'t have an account? Sign Up',
                style: TextStyle(
                  color: Colors.blue,  // Change color as needed
                  fontSize: 16,         // Adjust font size
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
