import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  MaterialColor _fontColor = Colors.teal;
  MaterialColor _highlightColor = Colors.blue;

  bool get isDarkMode => _isDarkMode;
  MaterialColor get fontColor => _fontColor;
  MaterialColor get highlightColor => _highlightColor;

  TextStyle get highlightTextStyle => TextStyle(color: _fontColor);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    int fontColorValue = prefs.getInt('fontColor') ?? Colors.teal.toARGB32();
    int highlightColorValue = prefs.getInt('highlightColor') ?? Colors.blue.toARGB32();

    _fontColor = _getMaterialColorFromARGB32(fontColorValue);
    _highlightColor = _getMaterialColorFromARGB32(highlightColorValue);

    notifyListeners();
  }

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners(); // Notify listeners to rebuild the UI
  }

  void changeFontColor(MaterialColor color) async {
    _fontColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontColor', color.toARGB32());
    notifyListeners();
  }

  void changeHighlightColor(MaterialColor color) async {
    _highlightColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highlightColor', color.toARGB32());
    notifyListeners();
  }

  MaterialColor _getMaterialColorFromARGB32(int argb) {
    return <MaterialColor>[
      Colors.red,
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ].firstWhere((c) => c.toARGB32() == argb, orElse: () => Colors.teal);
  }
}

