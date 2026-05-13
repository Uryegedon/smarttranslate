import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameUnique(String username) async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot =
        await firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
    return querySnapshot.docs.isEmpty;
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Terms and Privacy Policy'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Text('''
Acceptance of Terms

By downloading, accessing, or using Lingualink, you agree to be bound by these Terms. If you do not agree, please do not use the App.

Use of the App
You agree to use Lingualink only for lawful and appropriate purposes. You must not:
• Use the App in any way that violates any applicable local, national, or international law or regulation.
• Attempt to gain unauthorized access to any part of the App, server, or connected systems.
• Reverse engineer, decompile, or disassemble any part of the App.
• Use the App to transmit any harmful, offensive, or illegal content.

User Accounts
To access certain features, you may be required to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account.

Intellectual Property
All content, features, and functionality of Lingualink are the property of Smart Path Solutions or its licensors. You may not reproduce, distribute, or create derivative works without our permission.

Limitation of Liability
To the fullest extent permitted by law, Smart Path Solutions shall not be liable for any indirect, incidental, special, or consequential damages resulting from your use of or inability to use the App.

Modifications to the Terms
We reserve the right to modify these Terms at any time. Continued use of the App after changes means you accept the revised Terms.

Termination
We may suspend or terminate your access to the App at any time for conduct that violates these Terms or is harmful to other users or the Company.

Governing Law
These Terms are governed by the applicable laws in your place of residence, unless a different governing law is required by local regulation.

Privacy Policy
Effective Date: May 10, 2026

This Privacy Policy describes how Lingualink collects, uses, and protects your personal information.

Information We Collect:
• Personal Information: Name, email address, login credentials.
• Usage Data: Translation history, preferred languages.
• Device Information: Type, OS, IP, general location.

How We Use Your Information:
• Operate and improve the App.
• Personalize experience.
• Provide customer support.
• Comply with legal obligations.

Data Sharing:
• With third-party services (e.g., hosting, analytics).
• With legal authorities if required.

Data Security:
We implement reasonable technical and organizational measures, but no method is 100% secure.

Your Rights and Choices:
• Access, update, delete your data.
• Contact us at Smartpathsolutions@gmail.com for data or privacy concerns.

Children's Privacy:
Lingualink is not intended for children under 13. We do not knowingly collect personal data from children.

Changes to Policy:
We may update this policy periodically.

Contact Us:
Smartpathsolutions@gmail.com
Smart Path Solutions
''', style: const TextStyle(fontSize: 14)),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
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

                const SizedBox(height: 36),

                // Header
                Text(
                  "Create\nAccount ✨",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Join Lingualink and start translating",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        "Username",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'Choose a username',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email
                      Text(
                        "Email",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'Enter your email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password
                      Text(
                        "Password",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: 'Create a password',
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Terms and conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsDialog(context),
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    if (!_agreedToTerms) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You must agree to the terms',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final username =
                                        _usernameController.text.trim();
                                    final email = _emailController.text.trim();
                                    final password =
                                        _passwordController.text.trim();

                                    setState(() => _isLoading = true);

                                    final isUnique = await _isUsernameUnique(
                                      username,
                                    );
                                    if (!mounted || !context.mounted) return;
                                    if (!isUnique) {
                                      setState(() => _isLoading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Username is already taken.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final userCredential = await FirebaseAuth
                                          .instance
                                          .createUserWithEmailAndPassword(
                                            email: email,
                                            password: password,
                                          );

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userCredential.user?.uid)
                                          .set({
                                            'username': username,
                                            'email': email,
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool('isLoggedIn', true);
                                      await prefs.setBool('isGuest', false);

                                      if (!mounted || !context.mounted) return;
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/translate',
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage;
                                      if (e.code == 'email-already-in-use') {
                                        errorMessage =
                                            'This email is already in use.';
                                      } else if (e.code == 'weak-password') {
                                        errorMessage =
                                            'The password is too weak.';
                                      } else {
                                        errorMessage =
                                            'An error occurred. Please try again.';
                                      }
                                      if (!mounted || !context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(errorMessage)),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 15,
                              ),
                              children: [
                                TextSpan(
                                  text: "Log In",
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

                      const SizedBox(height: 20),
                    ],
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
