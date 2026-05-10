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

class _TranslatorScreenState extends State<TranslatorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = "";
  List<String> _alternativeTranslations = [];
  List<String> _autocompleteSuggestions = [];
  String? _typoSuggestion;
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Spanish';
  final List<String> _availableLanguages = ['English', 'Spanish', 'Filipino'];
  late AnimationController _swapController;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _swapController.dispose();
    _inputController.dispose();
    super.dispose();
  }

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

  void _swapLanguages() {
    _swapController.forward(from: 0);
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
    if (_inputController.text.isNotEmpty) {
      _translate(_inputController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ThemeAwareScaffold(
      appBar: ThemeAwareAppBar(
        leading: const SizedBox(),
        title: ThemeAwareText(
          'SmartPath Translator',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Language Selector ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildLanguageChip(
                      value: _sourceLanguage,
                      onChanged: _onSourceLanguageChanged,
                    ),
                  ),
                  GestureDetector(
                    onTap: _swapLanguages,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(
                        CurvedAnimation(parent: _swapController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: theme.colorScheme.secondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildLanguageChip(
                      value: _targetLanguage,
                      onChanged: _onTargetLanguageChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Input card (fills ~40% of remaining height) ──
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextCardFull(
                child: TextField(
                  controller: _inputController,
                  onChanged: _translate,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type something to translate...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 16,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
                icon: Icons.edit_note_rounded,
                iconColor: primary,
              ),
            ),
          ),

          if (_typoSuggestion != null || _autocompleteSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildWritingAssistancePanel(theme),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Output card ──
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextCardFull(
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText.isEmpty
                        ? 'Translation will appear here'
                        : _translatedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: _translatedText.isEmpty
                          ? theme.hintColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                icon: Icons.translate_rounded,
                iconColor: theme.colorScheme.secondary,
                backgroundColor: primary.withOpacity(0.03),
                trailing: _translatedText.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          FlutterClipboard.copy(_translatedText);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.content_copy_rounded, size: 16, color: primary),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // ── Alternative Translations (compact, bottom strip) ──
          if (_alternativeTranslations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.alt_route_rounded, size: 14, color: primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alternative Translations',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _alternativeTranslations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final alt = _alternativeTranslations[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.subdirectory_arrow_right_rounded,
                                    size: 16, color: theme.hintColor),
                                const SizedBox(width: 10),
                                Expanded(child: Text(alt, style: theme.textTheme.bodyMedium)),
                                GestureDetector(
                                  onTap: () {
                                    FlutterClipboard.copy(alt);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied')),
                                    );
                                  },
                                  child: Icon(Icons.content_copy_rounded,
                                      size: 15, color: primary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.translate),
    );
  }

  Widget _buildWritingAssistancePanel(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_typoSuggestion != null) ...[
              Row(
                children: [
                  Icon(Icons.auto_fix_high_rounded, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Did you mean "$_typoSuggestion"?',
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _replaceActiveWord(_typoSuggestion!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Use',
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              if (_autocompleteSuggestions.isNotEmpty) Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(color: theme.dividerColor, height: 1),
              ),
            ],
            if (_autocompleteSuggestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.manage_search_rounded, color: theme.colorScheme.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Suggestions',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _autocompleteSuggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _replaceActiveWord(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        suggestion,
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Theme.of(context).hintColor),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: _availableLanguages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Full-height card — fills whatever space its parent Expanded gives it
  Widget _buildTextCardFull({
    required Widget child,
    required IconData icon,
    required Color iconColor,
    Color? backgroundColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
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
