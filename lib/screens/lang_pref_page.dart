import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LanguagePreferencesScreen extends StatefulWidget {
  const LanguagePreferencesScreen({super.key});

  @override
  State<LanguagePreferencesScreen> createState() =>
      _LanguagePreferencesScreenState();
}

class _LanguagePreferencesScreenState extends State<LanguagePreferencesScreen> {
  String _selectedLanguage = 'English';
  String _defaultSourceLanguage = SettingsService.defaultSourceLanguage;
  String _defaultTargetLanguage = SettingsService.defaultTargetLanguage;
  bool _soundEffectsEnabled = true;

  final List<String> _languages = SettingsService.translatorLanguages;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _selectedLanguage = settings.displayLanguage;
      _defaultSourceLanguage = settings.defaultSourceLanguage;
      _defaultTargetLanguage = settings.defaultTargetLanguage;
      _soundEffectsEnabled = settings.soundEffectsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
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
                  const SizedBox(width: 16),
                  Text(
                    'Language & Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Settings card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Display Language
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.language_rounded,
                              size: 20,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Display Language',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: primary,
                                ),
                                items:
                                    _languages.map((String language) {
                                      return DropdownMenuItem<String>(
                                        value: language,
                                        child: Text(language),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue == null) return;
                                  setState(() {
                                    _selectedLanguage = newValue;
                                  });
                                  SettingsService.saveDisplayLanguage(newValue);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: theme.dividerColor),
                    ),
                    _languageDropdownRow(
                      icon: Icons.input_rounded,
                      label: 'Default Source',
                      value: _defaultSourceLanguage,
                      theme: theme,
                      primary: primary,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() {
                          _defaultSourceLanguage = newValue;
                        });
                        SettingsService.saveDefaultSourceLanguage(newValue);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: theme.dividerColor),
                    ),
                    _languageDropdownRow(
                      icon: Icons.output_rounded,
                      label: 'Default Target',
                      value: _defaultTargetLanguage,
                      theme: theme,
                      primary: primary,
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() {
                          _defaultTargetLanguage = newValue;
                        });
                        SettingsService.saveDefaultTargetLanguage(newValue);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: theme.dividerColor),
                    ),
                    // Sound Effects
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 20,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Sound Effects',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: _soundEffectsEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                _soundEffectsEnabled = value;
                              });
                              SettingsService.saveSoundEffectsEnabled(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageDropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required Color primary,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: primary,
                ),
                items:
                    _languages.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
