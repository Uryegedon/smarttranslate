import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HighlightScheme { defaultScheme, greenApple, lavender }

const _noPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoPageTransitionsBuilder(),
    TargetPlatform.iOS: _NoPageTransitionsBuilder(),
    TargetPlatform.macOS: _NoPageTransitionsBuilder(),
    TargetPlatform.windows: _NoPageTransitionsBuilder(),
    TargetPlatform.linux: _NoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
  },
);

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  HighlightScheme _highlightScheme = HighlightScheme.defaultScheme;

  ThemeMode get themeMode => _themeMode;
  HighlightScheme get highlightScheme => _highlightScheme;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.light.index;
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.index == themeModeIndex,
        orElse: () => ThemeMode.light,
      );

      // Load highlight scheme
      final highlightSchemeIndex =
          prefs.getInt('highlightScheme') ??
          HighlightScheme.defaultScheme.index;
      _highlightScheme = HighlightScheme.values.firstWhere(
        (scheme) => scheme.index == highlightSchemeIndex,
        orElse: () => HighlightScheme.defaultScheme,
      );

      debugPrint(
        "Theme initialized - Mode: $_themeMode, Scheme: $_highlightScheme",
      );
    } catch (e) {
      debugPrint("Error initializing theme: $e");
      _themeMode = ThemeMode.light;
      _highlightScheme = HighlightScheme.defaultScheme;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // No change needed

    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', mode.index);
      notifyListeners(); // Moved before navigation if needed
    } catch (e) {
      debugPrint("Error saving theme mode: $e");
    }
  }

  Future<void> setHighlightScheme(HighlightScheme scheme) async {
    if (_highlightScheme == scheme) return; // No change needed

    _highlightScheme = scheme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highlightScheme', scheme.index);
      notifyListeners(); // Moved before navigation if needed
    } catch (e) {
      debugPrint("Error saving highlight scheme: $e");
    }
  }

  ThemeData get lightTheme {
    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        return ThemeData.light().copyWith(
          primaryColor: Colors.lightGreen,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.lightGreen),
          colorScheme: ColorScheme.light(primary: Colors.lightGreen),
          pageTransitionsTheme: _noPageTransitionsTheme,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );
      case HighlightScheme.lavender:
        return ThemeData.light().copyWith(
          primaryColor: Colors.purple.shade200,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.purple.shade200),
          colorScheme: ColorScheme.light(primary: Colors.purple.shade200),
          pageTransitionsTheme: _noPageTransitionsTheme,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );
      default:
        return ThemeData.light().copyWith(
          pageTransitionsTheme: _noPageTransitionsTheme,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );
    }
  }

  ThemeData get darkTheme {
    final base = ThemeData.dark().copyWith(
      pageTransitionsTheme: _noPageTransitionsTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        return base.copyWith(
          primaryColor: Colors.lightGreen,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.lightGreen),
          colorScheme: ColorScheme.dark(primary: Colors.lightGreen),
        );
      case HighlightScheme.lavender:
        return base.copyWith(
          primaryColor: Colors.deepPurpleAccent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurpleAccent,
          ),
          colorScheme: ColorScheme.dark(primary: Colors.deepPurpleAccent),
        );
      default:
        return base;
    }
  }
}
