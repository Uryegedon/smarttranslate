import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class OcrSettingsPage extends StatefulWidget {
  const OcrSettingsPage({super.key});

  @override
  State<OcrSettingsPage> createState() => _OcrSettingsPageState();
}

class _OcrSettingsPageState extends State<OcrSettingsPage> {
  bool _autoTranslate = true;
  double _textSize = 16.0;
  String _sourceLanguage = SettingsService.defaultOcrSourceLanguage;
  String _targetLanguage = SettingsService.defaultOcrTargetLanguage;

  final List<String> _languages = SettingsService.ocrLanguages;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _autoTranslate = settings.ocrAutoTranslate;
      _sourceLanguage = settings.ocrSourceLanguage;
      _targetLanguage = settings.ocrTargetLanguage;
      _textSize = settings.ocrTextSize;
    });
  }

  Future<void> _saveSettings() async {
    await Future.wait([
      SettingsService.saveOcrAutoTranslate(_autoTranslate),
      SettingsService.saveOcrSourceLanguage(_sourceLanguage),
      SettingsService.saveOcrTargetLanguage(_targetLanguage),
      SettingsService.saveOcrTextSize(_textSize),
    ]);
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
                    'OCR Settings',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
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
                        // Auto translate
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
                                  Icons.auto_awesome_rounded,
                                  size: 20,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Auto Translate',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _autoTranslate,
                                onChanged: (v) {
                                  setState(() => _autoTranslate = v);
                                  SettingsService.saveOcrAutoTranslate(v);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: theme.dividerColor),
                        ),
                        // Source language
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
                                  Icons.record_voice_over_rounded,
                                  size: 20,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Source Language',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              _languageDropdown(
                                value: _sourceLanguage,
                                primary: primary,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _sourceLanguage = value);
                                  SettingsService.saveOcrSourceLanguage(value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: theme.dividerColor),
                        ),
                        // Target language
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
                                  'Target Language',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              _languageDropdown(
                                value: _targetLanguage,
                                primary: primary,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _targetLanguage = value);
                                  SettingsService.saveOcrTargetLanguage(value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: theme.dividerColor),
                        ),
                        // Text size
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.text_fields_rounded,
                                      size: 20,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Text Size: ${_textSize.round()}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _textSize,
                                min: 12.0,
                                max: 32.0,
                                divisions: 10,
                                label: _textSize.round().toString(),
                                onChanged: (v) {
                                  setState(() => _textSize = v);
                                  SettingsService.saveOcrTextSize(v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Settings'),
                      onPressed: () async {
                        await _saveSettings();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageDropdown({
    required String value,
    required Color primary,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
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
              _languages
                  .map(
                    (lang) => DropdownMenuItem(value: lang, child: Text(lang)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
