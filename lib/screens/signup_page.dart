import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

By downloading, accessing, or using Smart Translate, you agree to be bound by these Terms. If you do not agree, please do not use the App.

Use of the App
You agree to use Smart Translate only for lawful and appropriate purposes. You must not:
• Use the App in any way that violates any applicable local, national, or international law or regulation.
• Attempt to gain unauthorized access to any part of the App, server, or connected systems.
• Reverse engineer, decompile, or disassemble any part of the App.
• Use the App to transmit any harmful, offensive, or illegal content.

User Accounts
To access certain features, you may be required to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account.

Intellectual Property
All content, features, and functionality of Smart Translate are the property of Smart Path Solutions or its licensors. You may not reproduce, distribute, or create derivative works without our permission.

Limitation of Liability
To the fullest extent permitted by law, Smart Path Solutions shall not be liable for any indirect, incidental, special, or consequential damages resulting from your use of or inability to use the App.

Modifications to the Terms
We reserve the right to modify these Terms at any time. Continued use of the App after changes means you accept the revised Terms.

Termination
We may suspend or terminate your access to the App at any time for conduct that violates these Terms or is harmful to other users or the Company.

Governing Law
These Terms are governed by and construed in accordance with the laws of [Your Country/State].

Privacy Policy
Effective Date: [Insert Date]

This Privacy Policy describes how Smart Translate collects, uses, and protects your personal information.

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

Children’s Privacy:
Smart Translate is not intended for children under 13. We do not knowingly collect personal data from children.

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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
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
                    const SizedBox(height: 16),

                    // Terms and Conditions Checkbox (optional)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              text: const TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: TextStyle(
                                      color: Colors.blue,
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

                    const SizedBox(height: 20),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  if (!_agreedToTerms) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (!isUnique) {
                                    setState(() => _isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
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

                                    if (!context.mounted) {
                                      return;
                                    }
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/',
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
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                ? const CircularProgressIndicator()
                                : const Text(
                                  'Sign Up',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
