import 'dart:math';
import 'package:flutter/material.dart';
import '../screens/themeawarewidget.dart';

class GuessLanguageScreen extends StatefulWidget {
  const GuessLanguageScreen({super.key});

  @override
  _GuessLanguageScreenState createState() => _GuessLanguageScreenState();
}

class _GuessLanguageScreenState extends State<GuessLanguageScreen> {
  final Map<String, String> wordPairs = {
    'MONEY': 'PERA',
    'CIRCLE': 'BILOG',
    'PAPER': 'PAPEL',
    'FISH': 'ISDA',
    'CAT': 'PUSA',
    'DOG': 'ASO',
    'HOUSE': 'BAHAY',
    'SUN': 'ARAW',
    'WATER': 'TUBIG',
    'FOOD': 'PAGKAIN',
    'LOVE': 'PAGIBIG',
    'BOOK': 'LIBRO',
    'CHAIR': 'UPUAN',
    'TREE': 'PUNO',
    'MOUSE': 'DAGA',
    'PENCIL': 'LAPIS',
  };

  String displayedWord = '';
  String correctLanguage = '';
  int score = 0;
  int lives = 3;

  @override
  void initState() {
    super.initState();
    generateNewWord();
  }

  void generateNewWord() {
    final random = Random();
    final allKeys = wordPairs.keys.toList();
    final englishWord = allKeys[random.nextInt(allKeys.length)];
    final filipinoWord = wordPairs[englishWord]!;

    bool showEnglish = random.nextBool();
    displayedWord = showEnglish ? englishWord : filipinoWord;
    correctLanguage = showEnglish ? 'ENGLISH' : 'FILIPINO';

    setState(() {});
  }

  void checkAnswer(String selectedLanguage) {
    if (selectedLanguage == correctLanguage) {
      setState(() {score++;});
    } 
    else {
      setState(() {lives--;});

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Game Over 😢', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Your final score is $score.', style: TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                score = 0;
                lives = 3;
                generateNewWord();
              });
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
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Guess the Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Score and lives bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    // Hearts
                    Row(
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: i < lives ? const Color(0xFFEF4444) : theme.hintColor.withOpacity(0.3),
                          size: 22,
                        ),
                      )),
                    ),
                    const Spacer(),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: $score',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primary),
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
                child: Text(
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => checkAnswer('ENGLISH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('ENGLISH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => checkAnswer('FILIPINO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('FILIPINO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ],
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
            case 0: Navigator.pushReplacementNamed(context, '/translate'); break;
            case 1: Navigator.pushReplacementNamed(context, '/camera'); break;
            case 2: Navigator.pushReplacementNamed(context, '/minigames'); break;
            case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
          }
        },
      ),
    );
  }
}