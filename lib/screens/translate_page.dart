import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'translationservice.dart';
import 'themeawarewidget.dart';
import '../services/language_algorithms.dart';
import '../widgets/app_bottom_nav_bar.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = "";
  List<String> _alternativeTranslations = [];
  List<String> _autocompleteSuggestions = [];
  String? _typoSuggestion;
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Spanish';
  final List<String> _availableLanguages = ['English', 'Spanish', 'Filipino'];

  void _translate(String text) async {
    _updateWritingAssistance(text);

    if (text.isNotEmpty) {
      try {
        final localTranslation = LanguageAlgorithms.findDirectTranslation(
          text: text,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        );

        String translated =
            localTranslation ??
            await translateText(text, _sourceLanguage, _targetLanguage);

        List<String> alternatives =
            LanguageAlgorithms.rankAlternativeTranslations(
              originalText: text,
              translatedText: translated,
              sourceLanguage: _sourceLanguage,
              targetLanguage: _targetLanguage,
            );

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
        _autocompleteSuggestions = [];
        _typoSuggestion = null;
      });
    }
  }

  void _updateWritingAssistance(String text) {
    final activeWord = _activeWordFrom(text);

    setState(() {
      _autocompleteSuggestions = LanguageAlgorithms.autocomplete(
        prefix: activeWord,
        language: _sourceLanguage,
      );
      _typoSuggestion = LanguageAlgorithms.suggestCorrection(
        word: activeWord,
        language: _sourceLanguage,
      );
    });
  }

  String _activeWordFrom(String text) {
    final words = text.trimRight().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.last;
  }

  void _replaceActiveWord(String replacement) {
    final currentText = _inputController.text.trimRight();
    final lastSpace = currentText.lastIndexOf(RegExp(r'\s'));
    final newText =
        lastSpace == -1
            ? replacement
            : '${currentText.substring(0, lastSpace + 1)}$replacement';

    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _translate(newText);
  }

  void _onSourceLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _sourceLanguage = newValue;
      });
      _updateWritingAssistance(_inputController.text);
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
        leading: SizedBox(), // Empty leading to remove the back button
        title: ThemeAwareText(
          'SmartPath Translator',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24, // Increased font size
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
              if (_typoSuggestion != null ||
                  _autocompleteSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWritingAssistancePanel(theme),
              ],
              const SizedBox(height: 12),

              // Output box
              _buildTextBox(
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText.isEmpty
                        ? 'Translation will appear here'
                        : _translatedText,
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
                      Icon(
                        Icons.alt_route,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      ThemeAwareText(
                        'Alternative Translations',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._alternativeTranslations.map(
                  (alt) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 8.0,
                    ),
                    child: _buildShadowContainer(
                      child: Row(
                        children: [
                          Icon(
                            Icons.translate,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: ThemeAwareText(alt)),
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 18),
                            onPressed: () {
                              FlutterClipboard.copy(alt);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: ThemeAwareText(
                                    'Copied to clipboard',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.translate),
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
          items:
              _availableLanguages.map((String language) {
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

  Widget _buildWritingAssistancePanel(ThemeData theme) {
    return _buildShadowContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_typoSuggestion != null) ...[
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: ThemeAwareText(
                    'Did you mean "$_typoSuggestion"?',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => _replaceActiveWord(_typoSuggestion!),
                  child: const Text('Use'),
                ),
              ],
            ),
            if (_autocompleteSuggestions.isNotEmpty) const Divider(),
          ],
          if (_autocompleteSuggestions.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.manage_search, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                ThemeAwareText(
                  'Suggestions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _autocompleteSuggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _replaceActiveWord(suggestion),
                    );
                  }).toList(),
            ),
          ],
        ],
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
