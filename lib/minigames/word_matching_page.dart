import 'dart:math';

import 'package:flutter/material.dart';

import '../services/game_word_service.dart';
import '../widgets/app_bottom_nav_bar.dart';

class WordMatchingScreen extends StatefulWidget {
  const WordMatchingScreen({super.key});

  @override
  State<WordMatchingScreen> createState() => _WordMatchingScreenState();
}

class _MatchCard {
  const _MatchCard({
    required this.id,
    required this.text,
    required this.subtitle,
    required this.isSource,
  });

  final String id;
  final String text;
  final String subtitle;
  final bool isSource;
}

class _WordMatchingScreenState extends State<WordMatchingScreen> {
  final _random = Random();
  List<GameWord> _words = [];
  List<_MatchCard> _sourceCards = [];
  List<_MatchCard> _targetCards = [];
  final Set<String> _matchedIds = {};
  _MatchCard? _selectedSource;
  _MatchCard? _selectedTarget;
  bool _loading = true;
  int _moves = 0;
  int _round = 1;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await GameWordService.loadWords(
      languages: const ['Spanish', 'Filipino', 'Japanese', 'Russian'],
    );
    if (!mounted) return;
    setState(() {
      _words = words.where((word) => word.word.trim().isNotEmpty).toList();
      _loading = false;
    });
    _newRound();
  }

  void _newRound() {
    if (_words.isEmpty) return;

    final shuffled = List<GameWord>.of(_words)..shuffle(_random);
    final selected = <GameWord>[];
    final usedBaseWords = <String>{};
    for (final word in shuffled) {
      if (usedBaseWords.add(word.baseWord)) {
        selected.add(word);
      }
      if (selected.length == 4) break;
    }

    final sourceCards = [
      for (final word in selected)
        _MatchCard(
          id: word.baseWord,
          text: word.baseWord.toUpperCase(),
          subtitle: 'English',
          isSource: true,
        ),
    ]..shuffle(_random);

    final targetCards = [
      for (final word in selected)
        _MatchCard(
          id: word.baseWord,
          text: word.word,
          subtitle: word.language,
          isSource: false,
        ),
    ]..shuffle(_random);

    setState(() {
      _sourceCards = sourceCards;
      _targetCards = targetCards;
      _matchedIds.clear();
      _selectedSource = null;
      _selectedTarget = null;
      _moves = 0;
    });
  }

  void _selectCard(_MatchCard card) {
    if (_matchedIds.contains(card.id)) return;

    setState(() {
      if (card.isSource) {
        _selectedSource = _selectedSource?.id == card.id ? null : card;
      } else {
        _selectedTarget = _selectedTarget?.id == card.id ? null : card;
      }
    });

    final source = _selectedSource;
    final target = _selectedTarget;
    if (source != null && target != null) {
      _resolvePair(source, target);
    }
  }

  void _resolvePair(_MatchCard source, _MatchCard target) {
    final isMatch = source.id == target.id;
    setState(() => _moves++);

    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (isMatch) {
        setState(() {
          _matchedIds.add(source.id);
          _selectedSource = null;
          _selectedTarget = null;
        });

        if (_matchedIds.length == _sourceCards.length) {
          _showRoundComplete();
        }
      } else {
        setState(() {
          _selectedSource = null;
          _selectedTarget = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not a match')));
      }
    });
  }

  void _showRoundComplete() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Round Complete'),
            content: Text('Matched all pairs in $_moves moves.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _round++);
                  _newRound();
                },
                child: const Text('Next Round'),
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
            _Header(title: 'Word Matching', theme: theme),
            Expanded(
              child:
                  _loading
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: 'Round',
                                  value: '$_round',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Metric(
                                  label: 'Moves',
                                  value: '$_moves',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Match each English word with its translation',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _CardColumn(
                                  title: 'English',
                                  cards: _sourceCards,
                                  selected: _selectedSource,
                                  matchedIds: _matchedIds,
                                  onTap: _selectCard,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CardColumn(
                                  title: 'Translation',
                                  cards: _targetCards,
                                  selected: _selectedTarget,
                                  matchedIds: _matchedIds,
                                  onTap: _selectCard,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _newRound,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('New Round'),
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

class _CardColumn extends StatelessWidget {
  const _CardColumn({
    required this.title,
    required this.cards,
    required this.selected,
    required this.matchedIds,
    required this.onTap,
  });

  final String title;
  final List<_MatchCard> cards;
  final _MatchCard? selected;
  final Set<String> matchedIds;
  final ValueChanged<_MatchCard> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        for (final card in cards) ...[
          _PairTile(
            card: card,
            isSelected: selected?.id == card.id,
            isMatched: matchedIds.contains(card.id),
            onTap: () => onTap(card),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PairTile extends StatelessWidget {
  const _PairTile({
    required this.card,
    required this.isSelected,
    required this.isMatched,
    required this.onTap,
  });

  final _MatchCard card;
  final bool isSelected;
  final bool isMatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final background =
        isMatched
            ? primary.withOpacity(0.12)
            : isSelected
            ? primary.withOpacity(0.08)
            : theme.cardColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isMatched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isMatched || isSelected
                      ? primary
                      : theme.dividerColor.withOpacity(0.8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
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
