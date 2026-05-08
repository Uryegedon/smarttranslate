import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'translationservice.dart';
import 'themeawarewidget.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = "";
  List<String> _alternativeTranslations = [];
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

          const SizedBox(height: 10),

          // ── Output card (fills ~40% of remaining height) ──
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
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 0,
        onTap: (index) => _onItemTapped(context, index),
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
