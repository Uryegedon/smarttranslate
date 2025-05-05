import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'translationservice.dart';
import 'themeawarewidget.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = "";
  List<String> _alternativeTranslations = [];
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Spanish';
  final List<String> _availableLanguages = ['English', 'Spanish', 'Filipino'];

  void _translate(String text) async {
    if (text.isNotEmpty) {
      try {
        String translated = await translateText(text, _sourceLanguage, _targetLanguage);
        List<String> alternatives = await fetchAlternativeTranslations(translated);

        setState(() {
          _translatedText = translated;
          _alternativeTranslations = alternatives;
        });
      } catch (e) {
        setState(() {
          _translatedText = "Translation failed: $e";
          _alternativeTranslations = [];
        });
      }
    } else {
      setState(() {
        _translatedText = "";
        _alternativeTranslations = [];
      });
    }
  }

  Future<List<String>> fetchAlternativeTranslations(String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      "$text (Alternative 1)",
      "$text (Alternative 2)",
      "$text (Alternative 3)",
    ];
  }

  void _onSourceLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _sourceLanguage = newValue;
      });
      if (_inputController.text.isNotEmpty) {
        _translate(_inputController.text);
      }
    }
  }

  void _onTargetLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _targetLanguage = newValue;
      });
      if (_inputController.text.isNotEmpty) {
        _translate(_inputController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemeAwareScaffold(
      appBar: ThemeAwareAppBar(
  leading: SizedBox(),  // Empty leading to remove the back button
  title: ThemeAwareText(
    'SmartPath Translator',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24,  // Increased font size
    ),
  ),
  centerTitle: true,
),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Language dropdowns in a row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactLanguageDropdown(
                      value: _sourceLanguage,
                      onChanged: _onSourceLanguageChanged,
                      label: 'From',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactLanguageDropdown(
                      value: _targetLanguage,
                      onChanged: _onTargetLanguageChanged,
                      label: 'To',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input box
              _buildTextBox(
                child: TextField(
                  controller: _inputController,
                  onChanged: _translate,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type here...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: theme.hintColor),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),

              // Output box
              _buildTextBox(
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText.isEmpty ? 'Translation will appear here' : _translatedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _translatedText.isEmpty ? theme.hintColor : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Alternative translations
              if (_alternativeTranslations.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.alt_route, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      ThemeAwareText(
                        'Alternative Translations',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._alternativeTranslations.map((alt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  child: _buildShadowContainer(
                    child: Row(
                      children: [
                        Icon(Icons.translate, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(child: ThemeAwareText(alt)),
                        IconButton(
                          icon: const Icon(Icons.content_copy, size: 18),
                          onPressed: () {
                            FlutterClipboard.copy(alt);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: ThemeAwareText('Copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,  // The initial selected index
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.blue[300],
  selectedItemColor: Colors.black,
  unselectedItemColor: Colors.white.withOpacity(0.7),
  selectedFontSize: 14, // Optional: You can leave this out as labels are removed
  unselectedFontSize: 12, // Optional: You can leave this out as labels are removed
  onTap: (index) => _onItemTapped(context, index),
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.translate, size: 30),
      label: '', // Empty label (required by Flutter)
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt, size: 30),
      label: '', // Empty label (required by Flutter)
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.extension, size: 30),
      label: '', // Empty label (required by Flutter)
    ),
    BottomNavigationBarItem(
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
      label: '', // Empty label (required by Flutter)
    ),
  ],
),


    );
  }

  Widget _buildCompactLanguageDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return _buildShadowContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: _availableLanguages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text(label, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildTextBox({required Widget child}) {
    return SizedBox(
      height: 150,
      child: _buildShadowContainer(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _buildShadowContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/translate');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/camera');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/minigames');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
