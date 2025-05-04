import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/themeprovider.dart'; // Import ThemeProvider from screens folder
import 'pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final themeProvider = ThemeProvider();
  await themeProvider.init(); // Wait for SharedPreferences to load

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const SmartTranslateApp(),
    ),
  );
}

class SmartTranslateApp extends StatelessWidget {
  const SmartTranslateApp({super.key});

  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isGuest = prefs.getBool('isGuest') ?? false;

    if (isLoggedIn || isGuest) {
      return '/translate'; // Redirect to TranslatorScreen
    }
    return '/'; // Redirect to WelcomePage
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    debugPrint("Current theme mode: ${themeProvider.isDarkMode ? 'Dark' : 'Light'}");  // Debug print
    return MaterialApp(
      title: 'SmartPath Translator',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        primaryColor: themeProvider.highlightColor,
        buttonTheme: ButtonThemeData(buttonColor: themeProvider.highlightColor),
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyLarge: TextStyle(color: themeProvider.fontColor),
          bodyMedium: TextStyle(color: themeProvider.fontColor),
          titleLarge: TextStyle(color: themeProvider.fontColor),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.highlightColor,
          foregroundColor: themeProvider.fontColor,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: themeProvider.highlightColor,
        buttonTheme: ButtonThemeData(buttonColor: themeProvider.highlightColor),
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: TextStyle(color: themeProvider.fontColor),
          bodyMedium: TextStyle(color: themeProvider.fontColor),
          titleLarge: TextStyle(color: themeProvider.fontColor),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.highlightColor,
          foregroundColor: themeProvider.fontColor,
        ),
      ),
      initialRoute: snapshot.data,
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignupPage(),
        '/translate': (context) => TranslatorScreen(),
        '/minigames': (context) => GameSelectionScreen(),
        '/profile': (context) => ProfileScreen(),
        '/soundandnotif': (context) => SoundNotificationPage(),
        '/langpref': (context) => LanguagePreferencesScreen(),
        '/wordmatching': (context) => GuessLanguageScreen(),
        '/camera': (context) => CameraOcrPage(),
        '/ocrsettings': (context) => OcrSettingsPage(),
        '/themesettings': (context) => ThemeSettingsPage(),
      },
    );
  },
);

      },
    );
  }
}
