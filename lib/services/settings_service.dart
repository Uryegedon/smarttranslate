import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AppSettings {
  const AppSettings({
    required this.displayLanguage,
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    required this.soundEffectsEnabled,
    required this.allowNotifications,
    required this.soundOption,
    required this.soundVolume,
    required this.ocrAutoTranslate,
    required this.ocrSourceLanguage,
    required this.ocrTargetLanguage,
    required this.ocrTextSize,
  });

  final String displayLanguage;
  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final bool soundEffectsEnabled;
  final bool allowNotifications;
  final String soundOption;
  final double soundVolume;
  final bool ocrAutoTranslate;
  final String ocrSourceLanguage;
  final String ocrTargetLanguage;
  final double ocrTextSize;
}

class SettingsService {
  static const String defaultDisplayLanguage = 'English';
  static const String defaultSourceLanguage = 'English';
  static const String defaultTargetLanguage = 'Spanish';
  static const String defaultOcrSourceLanguage = 'English';
  static const String defaultOcrTargetLanguage = 'English';
  static const double defaultOcrTextSize = 16;
  static const double defaultSoundVolume = 0.5;

  static const List<String> translatorLanguages = [
    'English',
    'Spanish',
    'Filipino',
    'Japanese',
    'Russian',
  ];

  static const List<String> ocrLanguages = [
    'English',
    'Spanish',
    'Filipino',
    'Japanese',
    'Russian',
  ];

  static const String _displayLanguageKey = 'settings.displayLanguage';
  static const String _defaultSourceLanguageKey =
      'settings.defaultSourceLanguage';
  static const String _defaultTargetLanguageKey =
      'settings.defaultTargetLanguage';
  static const String _soundEffectsEnabledKey = 'settings.soundEffectsEnabled';
  static const String _allowNotificationsKey = 'settings.allowNotifications';
  static const String _soundOptionKey = 'settings.soundOption';
  static const String _soundVolumeKey = 'settings.soundVolume';
  static const String _ocrAutoTranslateKey = 'settings.ocrAutoTranslate';
  static const String _ocrSourceLanguageKey = 'settings.ocrSourceLanguage';
  static const String _ocrTargetLanguageKey = 'settings.ocrTargetLanguage';
  static const String _ocrTextSizeKey = 'settings.ocrTextSize';
  static const String _translationApiUrlKey = 'settings.translationApiUrl';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      displayLanguage: _normaliseTranslatorLanguage(
        prefs.getString(_displayLanguageKey),
        fallback: defaultDisplayLanguage,
      ),
      defaultSourceLanguage: _normaliseTranslatorLanguage(
        prefs.getString(_defaultSourceLanguageKey),
        fallback: defaultSourceLanguage,
      ),
      defaultTargetLanguage: _normaliseTranslatorLanguage(
        prefs.getString(_defaultTargetLanguageKey),
        fallback: defaultTargetLanguage,
      ),
      soundEffectsEnabled: prefs.getBool(_soundEffectsEnabledKey) ?? true,
      allowNotifications: prefs.getBool(_allowNotificationsKey) ?? false,
      soundOption: _normaliseSoundOption(prefs.getString(_soundOptionKey)),
      soundVolume: prefs.getDouble(_soundVolumeKey) ?? defaultSoundVolume,
      ocrAutoTranslate: prefs.getBool(_ocrAutoTranslateKey) ?? true,
      ocrSourceLanguage: _normaliseOcrLanguage(
        prefs.getString(_ocrSourceLanguageKey),
        fallback: defaultOcrSourceLanguage,
      ),
      ocrTargetLanguage: _normaliseOcrLanguage(
        prefs.getString(_ocrTargetLanguageKey),
        fallback: defaultOcrTargetLanguage,
      ),
      ocrTextSize: prefs.getDouble(_ocrTextSizeKey) ?? defaultOcrTextSize,
    );
  }

  static Future<void> saveDisplayLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayLanguageKey, value);
  }

  static Future<void> saveDefaultSourceLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultSourceLanguageKey, value);
  }

  static Future<void> saveDefaultTargetLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultTargetLanguageKey, value);
  }

  static Future<void> saveSoundEffectsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsEnabledKey, value);
  }

  static Future<void> saveAllowNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowNotificationsKey, value);
  }

  static Future<void> saveSoundOption(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundOptionKey, value);
  }

  static Future<void> saveSoundVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_soundVolumeKey, value);
  }

  static Future<void> saveOcrAutoTranslate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ocrAutoTranslateKey, value);
  }

  static Future<void> saveOcrSourceLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ocrSourceLanguageKey, value);
  }

  static Future<void> saveOcrTargetLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ocrTargetLanguageKey, value);
  }

  static Future<void> saveOcrTextSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ocrTextSizeKey, value);
  }

  static Future<String?> loadTranslationApiUrlOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_translationApiUrlKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> saveTranslationApiUrlOverride(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalised = normaliseTranslationApiUrl(value);
    if (normalised == null) {
      await prefs.remove(_translationApiUrlKey);
      return;
    }
    await prefs.setString(_translationApiUrlKey, normalised);
  }

  static Future<void> clearTranslationApiUrlOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_translationApiUrlKey);
  }

  static String? normaliseTranslationApiUrl(String value) {
    var url = value.trim();
    if (url.isEmpty) return null;

    if (_looksLikeNgrokCode(url)) {
      url =
          '${AppConfig.ngrokScheme}$url${AppConfig.ngrokHostSuffix}${AppConfig.translationPath}';
    } else if (_looksLikeNgrokHost(url)) {
      url = '${AppConfig.ngrokScheme}$url${AppConfig.translationPath}';
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final scheme = _shouldDefaultToHttp(url) ? 'http://' : 'https://';
      url = '$scheme$url';
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) {
      return null;
    }

    final path =
        parsed.path.endsWith('/translate/')
            ? parsed.path
            : parsed.path.endsWith('/translate')
            ? '${parsed.path}/'
            : '${parsed.path.replaceFirst(RegExp(r'/$'), '')}/translate/';

    return parsed.replace(path: path).toString();
  }

  static bool _looksLikeNgrokCode(String value) {
    return RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(value) &&
        !value.contains('.') &&
        !value.contains('/');
  }

  static bool _looksLikeNgrokHost(String value) {
    return RegExp(r'^[a-zA-Z0-9-]+\.ngrok-free\.app/?$').hasMatch(value);
  }

  static bool _shouldDefaultToHttp(String value) {
    final host = value.split('/').first.split(':').first.toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        RegExp(r'^(10|172\.(1[6-9]|2\d|3[0-1])|192\.168)\.').hasMatch(host);
  }

  static String _normaliseOcrLanguage(
    String? value, {
    required String fallback,
  }) {
    return switch (value) {
      'en' => 'English',
      'es' => 'Spanish',
      'fil' => 'Filipino',
      'ja' => 'Japanese',
      'ru' => 'Russian',
      final stored when stored != null && ocrLanguages.contains(stored) =>
        stored,
      _ => fallback,
    };
  }

  static String _normaliseTranslatorLanguage(
    String? value, {
    required String fallback,
  }) {
    if (value != null && translatorLanguages.contains(value)) {
      return value;
    }
    return fallback;
  }

  static String _normaliseSoundOption(String? value) {
    return switch (value) {
      'sound' || 'silent' => value!,
      _ => 'sound',
    };
  }
}
