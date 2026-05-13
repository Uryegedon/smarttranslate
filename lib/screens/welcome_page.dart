import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void continueAsGuest(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isGuest', true);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/translate');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Decorative background blobs
          Positioned(
            top: -size.height * 0.12,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.12), primary.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.08),
                    theme.colorScheme.secondary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: size.height * 0.08),

                            Container(
                              width: size.width * 0.22,
                              height: size.width * 0.22,
                              constraints: const BoxConstraints(
                                minWidth: 72,
                                minHeight: 72,
                                maxWidth: 120,
                                maxHeight: 120,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [primary, primary.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.translate_rounded,
                                color: Colors.white,
                                size: size.width * 0.11,
                              ),
                            ),

                            SizedBox(height: size.height * 0.035),

                            Text(
                              "Welcome to",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.hintColor,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Lingualink",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width * 0.085,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Break language barriers instantly",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontSize: 15,
                              ),
                            ),

                            const Spacer(),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    () =>
                                        Navigator.pushNamed(context, '/signup'),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    () =>
                                        Navigator.pushNamed(context, '/login'),
                                child: const Text(
                                  "Log In",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => continueAsGuest(context),
                              child: Text(
                                "Continue as Guest",
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
