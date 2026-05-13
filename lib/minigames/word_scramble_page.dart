import 'dart:math';

import 'package:flutter/material.dart';

import '../services/game_word_service.dart';
import '../widgets/app_bottom_nav_bar.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  final _random = Random();
  final _answerController = TextEditingController();
  List<GameWord> _deck = [];
  GameWord? _current;
  String _scrambled = '';
  String? _lastBaseWord;
  bool _loading = true;
  int _score = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final words = await GameWordService.loadWords();
    if (!mounted) return;
    setState(() {
      _deck = List<GameWord>.of(words)..shuffle(_random);
      _loading = false;
    });
    _nextRound();
  }

  void _nextRound() {
    if (_deck.isEmpty) {
      setState(() => _loading = true);
      _loadWords();
      return;
    }

    final index = _deck.lastIndexWhere(
      (word) => word.baseWord != _lastBaseWord,
    );
    final next = index == -1 ? _deck.removeLast() : _deck.removeAt(index);
    final scrambled = _scramble(next.word);

    setState(() {
      _current = next;
      _lastBaseWord = next.baseWord;
      _scrambled = scrambled;
      _answerController.clear();
    });
  }

  String _scramble(String word) {
    final characters = word.runes.map(String.fromCharCode).toList();
    if (characters.length < 2) return word;

    var shuffled = List<String>.of(characters);
    for (var attempt = 0; attempt < 6; attempt++) {
      shuffled.shuffle(_random);
      final candidate = shuffled.join();
      if (candidate.toLowerCase() != word.toLowerCase()) {
        return candidate;
      }
    }

    return shuffled.reversed.join();
  }

  void _checkAnswer() {
    final current = _current;
    if (current == null) return;

    final answer = _answerController.text.trim().toLowerCase();
    final correct = current.word.trim().toLowerCase();
    if (answer == correct) {
      setState(() {
        _score++;
        _streak++;
      });
      _showMessage('Correct');
      _nextRound();
    } else {
      setState(() => _streak = 0);
      _showMessage('Try again');
    }
  }

  void _reveal() {
    final current = _current;
    if (current == null) return;
    _showMessage('Answer: ${current.word}');
    _nextRound();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final current = _current;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Word Scramble', theme: theme),
            Expanded(
              child:
                  _loading
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          _ScoreBar(score: _score, streak: _streak),
                          const SizedBox(height: 28),
                          Text(
                            current?.language.toUpperCase() ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 36,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _scrambled,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _answerController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _checkAnswer(),
                            decoration: const InputDecoration(
                              hintText: 'Unscramble the word',
                              prefixIcon: Icon(Icons.edit_rounded),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _reveal,
                                  child: const Text('Reveal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _checkAnswer,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Check'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.minigames),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.streak});

  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Metric(label: 'Score', value: '$score')),
        const SizedBox(width: 12),
        Expanded(child: _Metric(label: 'Streak', value: '$streak')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: theme.hintColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
