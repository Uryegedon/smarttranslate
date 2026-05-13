import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HighlightScheme { defaultScheme, greenApple, lavender, roseGold, ocean }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  HighlightScheme _highlightScheme = HighlightScheme.defaultScheme;
  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;

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
      _clearThemeCache();

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
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', mode.index);
    } catch (e) {
      debugPrint("Error saving theme mode: $e");
    }
  }

  Future<void> setHighlightScheme(HighlightScheme scheme) async {
    if (_highlightScheme == scheme) return;

    _highlightScheme = scheme;
    _clearThemeCache();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highlightScheme', scheme.index);
    } catch (e) {
      debugPrint("Error saving highlight scheme: $e");
    }
  }

  void _clearThemeCache() {
    _cachedLightTheme = null;
    _cachedDarkTheme = null;
  }

  // ─── Shared text theme ───
  TextTheme get _textTheme => const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );

  // ─── Color palette helpers ───
  static const _defaultPrimary = Color(0xFF0D9488);
  static const _defaultPrimaryLight = Color(0xFFCCFBF1);
  static const _defaultSecondary = Color(0xFFF97316);
  static const _greenApplePrimary = Color(0xFF65A30D);
  static const _greenAppleLight = Color(0xFFECFCCB);
  static const _lavenderPrimary = Color(0xFF7C3AED);
  static const _lavenderLight = Color(0xFFEDE9FE);
  static const _rosePrimary = Color(0xFFE11D48);
  static const _roseLight = Color(0xFFFFE4E6);
  static const _oceanPrimary = Color(0xFF0284C7);
  static const _oceanLight = Color(0xFFE0F2FE);

  Color get primaryColor {
    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        return _greenApplePrimary;
      case HighlightScheme.lavender:
        return _lavenderPrimary;
      case HighlightScheme.roseGold:
        return _rosePrimary;
      case HighlightScheme.ocean:
        return _oceanPrimary;
      default:
        return _defaultPrimary;
    }
  }

  Color get primaryLightColor {
    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        return _greenAppleLight;
      case HighlightScheme.lavender:
        return _lavenderLight;
      case HighlightScheme.roseGold:
        return _roseLight;
      case HighlightScheme.ocean:
        return _oceanLight;
      default:
        return _defaultPrimaryLight;
    }
  }

  // ─── LIGHT THEME ───
  ThemeData get lightTheme => _cachedLightTheme ??= _buildLightTheme();

  ThemeData _buildLightTheme() {
    Color primary;
    Color primaryLight;

    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        primary = _greenApplePrimary;
        primaryLight = _greenAppleLight;
        break;
      case HighlightScheme.lavender:
        primary = _lavenderPrimary;
        primaryLight = _lavenderLight;
        break;
      case HighlightScheme.roseGold:
        primary = _rosePrimary;
        primaryLight = _roseLight;
        break;
      case HighlightScheme.ocean:
        primary = _oceanPrimary;
        primaryLight = _oceanLight;
        break;
      default:
        primary = _defaultPrimary;
        primaryLight = _defaultPrimaryLight;
    }

    final colorScheme = ColorScheme.light(
      primary: primary,
      primaryContainer: primaryLight,
      secondary: _defaultSecondary,
      secondaryContainer: const Color(0xFFFFF7ED),
      surface: Colors.white,
      background: const Color(0xFFF8FAFC),
      error: const Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1E293B),
      onBackground: const Color(0xFF1E293B),
      onError: Colors.white,
      outline: const Color(0xFFE2E8F0),
      shadow: const Color(0x1A000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      hintColor: const Color(0xFF94A3B8),
      textTheme: _textTheme.apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF1E293B),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIconColor: primary,
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return const Color(0xFFCBD5E1);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.3);
          }
          return const Color(0xFFE2E8F0);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.15),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return const Color(0xFFCBD5E1);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 0),
        unselectedLabelStyle: const TextStyle(fontSize: 0),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      iconTheme: IconThemeData(color: const Color(0xFF64748B), size: 24),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ─── DARK THEME ───
  ThemeData get darkTheme => _cachedDarkTheme ??= _buildDarkTheme();

  ThemeData _buildDarkTheme() {
    Color primary;
    Color primaryLight;

    switch (_highlightScheme) {
      case HighlightScheme.greenApple:
        primary = const Color(0xFF84CC16);
        primaryLight = const Color(0xFF1A2E05);
        break;
      case HighlightScheme.lavender:
        primary = const Color(0xFFA78BFA);
        primaryLight = const Color(0xFF1E1533);
        break;
      case HighlightScheme.roseGold:
        primary = const Color(0xFFFB7185);
        primaryLight = const Color(0xFF4C0519);
        break;
      case HighlightScheme.ocean:
        primary = const Color(0xFF38BDF8);
        primaryLight = const Color(0xFF0C3659);
        break;
      default:
        primary = const Color(0xFF2DD4BF);
        primaryLight = const Color(0xFF042F2E);
    }

    final colorScheme = ColorScheme.dark(
      primary: primary,
      primaryContainer: primaryLight,
      secondary: const Color(0xFFFB923C),
      secondaryContainer: const Color(0xFF431407),
      surface: const Color(0xFF1E293B),
      background: const Color(0xFF0F172A),
      error: const Color(0xFFFCA5A5),
      onPrimary: const Color(0xFF0F172A),
      onSecondary: const Color(0xFF0F172A),
      onSurface: const Color(0xFFF1F5F9),
      onBackground: const Color(0xFFF1F5F9),
      onError: const Color(0xFF0F172A),
      outline: const Color(0xFF334155),
      shadow: const Color(0x40000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
      hintColor: const Color(0xFF64748B),
      textTheme: _textTheme.apply(
        bodyColor: const Color(0xFFF1F5F9),
        displayColor: const Color(0xFFF1F5F9),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: const Color(0xFFF1F5F9),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF1F5F9),
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        prefixIconColor: primary,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return const Color(0xFF64748B);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.3);
          }
          return const Color(0xFF334155);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.2),
        thumbColor: primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: const Color(0xFF64748B), width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return const Color(0xFF64748B);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF334155),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 0),
        unselectedLabelStyle: const TextStyle(fontSize: 0),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 24),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
