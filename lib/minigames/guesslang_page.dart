import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_word_service.dart';
import '../services/language_algorithms.dart';
import '../screens/themeawarewidget.dart';

class GuessLanguageScreen extends StatefulWidget {
  const GuessLanguageScreen({super.key});

  @override
  State<GuessLanguageScreen> createState() => _GuessLanguageScreenState();
}

class _LanguageRound {
  const _LanguageRound({
    required this.baseWord,
    required this.word,
    required this.language,
  });

  final String baseWord;
  final String word;
  final String language;
}

class _GuessLanguageScreenState extends State<GuessLanguageScreen> {
  final Random _random = Random();
  List<_LanguageRound> _roundSource = [];
  List<_LanguageRound> _roundDeck = [];

  String displayedWord = '';
  String correctLanguage = '';
  int score = 0;
  int lives = 3;
  bool _isLoadingRounds = true;
  String? _lastBaseWord;
  String? _lastDisplayedWord;

  @override
  void initState() {
    super.initState();
    _resetRoundDeck();
  }

  Future<void> _resetRoundDeck() async {
    setState(() => _isLoadingRounds = true);

    if (_roundSource.isEmpty) {
      final words = await GameWordService.loadWords();
      final rounds =
          words
              .where((word) => word.word.trim().isNotEmpty)
              .map(
                (word) => _LanguageRound(
                  baseWord: word.baseWord,
                  word: word.word.toUpperCase(),
                  language: word.language.toUpperCase(),
                ),
              )
              .toList();
      _roundSource = List.unmodifiable(rounds);
    }

    final rounds = List<_LanguageRound>.of(_roundSource);
    rounds.shuffle(_random);
    if (!mounted) return;
    setState(() {
      _roundDeck = rounds;
      _isLoadingRounds = false;
    });
    generateNewWord();
  }

  void generateNewWord() {
    if (_roundDeck.isEmpty) {
      _resetRoundDeck();
      return;
    }

    final nextRound = _drawNextRound();
    displayedWord = nextRound.word;
    correctLanguage = nextRound.language;
    _lastBaseWord = nextRound.baseWord;
    _lastDisplayedWord = nextRound.word;

    setState(() {});
  }

  _LanguageRound _drawNextRound() {
    final nextIndex = _roundDeck.lastIndexWhere(
      (round) =>
          round.baseWord != _lastBaseWord && round.word != _lastDisplayedWord,
    );

    if (nextIndex == -1) {
      return _roundDeck.removeLast();
    }

    return _roundDeck.removeAt(nextIndex);
  }

  void checkAnswer(String selectedLanguage) {
    if (selectedLanguage == correctLanguage) {
      setState(() {
        score++;
      });
    } else {
      setState(() {
        lives--;
      });

      if (lives <= 0) {
        showGameOverDialog();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect! It was $correctLanguage.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }

    generateNewWord();
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text(
              'Game Over 😢',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Your final score is $score.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    score = 0;
                    lives = 3;
                    _lastBaseWord = null;
                    _lastDisplayedWord = null;
                  });
                  _resetRoundDeck();
                  Navigator.of(context).pop();
                },
                child: Text('Play Again'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
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
                    'Guess the Language',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Score and lives bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                    // Hearts
                    Row(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < lives
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                i < lives
                                    ? const Color(0xFFEF4444)
                                    : theme.hintColor.withOpacity(0.3),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: $score',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Word display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: primary.withOpacity(0.1), width: 1),
              ),
              child: Center(
                child:
                    _isLoadingRounds
                        ? CircularProgressIndicator(color: primary)
                        : Text(
                          displayedWord,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 2,
                          ),
                        ),
              ),
            ),

            const Spacer(flex: 2),

            // Answer buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    LanguageAlgorithms.supportedLanguages.map((language) {
                      final label = language.toUpperCase();
                      return SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 76) / 2,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoadingRounds
                                  ? null
                                  : () => checkAnswer(label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                label == 'ENGLISH'
                                    ? primary
                                    : const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2,
        onTap: (index) {
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
        },
      ),
    );
  }
}
