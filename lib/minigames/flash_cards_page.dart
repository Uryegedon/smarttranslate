import 'package:flutter/material.dart';

import '../services/game_word_service.dart';
import '../widgets/app_bottom_nav_bar.dart';

class FlashCardsScreen extends StatefulWidget {
  const FlashCardsScreen({super.key});

  @override
  State<FlashCardsScreen> createState() => _FlashCardsScreenState();
}

class _FlashCardsScreenState extends State<FlashCardsScreen> {
  List<GameWord> _cards = [];
  int _index = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final words = await GameWordService.loadWords();
    if (!mounted) return;
    setState(() {
      _cards = List<GameWord>.of(words)..shuffle();
      _loading = false;
    });
  }

  void _next() {
    if (_cards.isEmpty) return;
    setState(() {
      _index = (_index + 1) % _cards.length;
      _showAnswer = false;
    });
  }

  void _previous() {
    if (_cards.isEmpty) return;
    setState(() {
      _index = (_index - 1 + _cards.length) % _cards.length;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final card = _cards.isEmpty ? null : _cards[_index];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Flash Cards', theme: theme),
            Expanded(
              child:
                  _loading
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        child: Column(
                          children: [
                            Text(
                              '${_index + 1} / ${_cards.length}',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: GestureDetector(
                                onTap:
                                    () => setState(
                                      () => _showAnswer = !_showAnswer,
                                    ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color:
                                        _showAnswer
                                            ? primary.withOpacity(0.1)
                                            : theme.cardColor,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: primary.withOpacity(0.18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showAnswer
                                              ? card?.language.toUpperCase() ??
                                                  ''
                                              : 'ENGLISH',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          _showAnswer
                                              ? card?.word ?? ''
                                              : card?.baseWord ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Tap to flip',
                                          style: TextStyle(
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _previous,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                    ),
                                    label: const Text('Back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _next,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    label: const Text('Next'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
