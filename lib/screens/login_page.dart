import 'package:flutter/material.dart';
import 'translate_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  // Log out the user if they are already logged in (for testing)
  void logOut() async {
    await FirebaseAuth.instance.signOut();
    debugPrint("User logged out");
  }

  void login() async {
    String input = emailController.text.trim();
    String password = passwordController.text;

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username/Email and password cannot be empty"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String email = input;

      if (!input.contains('@')) {
        final userQuery =
            await FirebaseFirestore.instance
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

      debugPrint("Logging in with email: $email");

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isGuest', false);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/translate');
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
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
          message =
              'Login failed. Please check your credentials and try again.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint("General error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Try again.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isGuest', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TranslatorScreen()),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Header
                Text(
                  "Welcome\nBack 👋",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sign in to continue translating",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 48),

                // Email/Username field
                Text(
                  "Email or Username",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: "Enter your email or username",
                  ),
                ),

                const SizedBox(height: 24),

                // Password field
                Text(
                  "Password",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    hintText: "Enter your password",
                    suffixIcon: GestureDetector(
                      onTap:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child:
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          )
                          : ElevatedButton(
                            onPressed: login,
                            child: const Text("Log In"),
                          ),
                ),

                const SizedBox(height: 28),

                // Sign up link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: theme.hintColor, fontSize: 15),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
