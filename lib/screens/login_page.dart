import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() {
    String email = emailController.text;
    String password = passwordController.text;

    // TODO: Add real authentication logic
    if (email.isNotEmpty && password.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged in as $email")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('LoginScreen loaded');
    return Scaffold(
      appBar: AppBar(title: Text("SmartPath Translator")),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.purple[50],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      // TODO: Go to Sign Up screen
                    },
                    child: Text("Sign Up")),
                SizedBox(width: 20),
                ElevatedButton(onPressed: login, child: Text("Log In")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
