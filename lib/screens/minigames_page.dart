import 'package:flutter/material.dart';
import 'themeawarewidget.dart';
import '../widgets/app_bottom_nav_bar.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ThemeAwareScaffold(
      body: Column(
        children: [
          // ── Fixed gradient header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              24,
              28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withOpacity(0.82)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minigames 🎮',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Learn languages while having fun',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // ── Game list fills remaining screen ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE GAMES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildGameCard(
                    context: context,
                    theme: theme,
                    title: 'Guess the Language',
                    description: 'Is it English or Filipino?',
                    icon: Icons.quiz_rounded,
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, '/wordmatching'),
                  ),
                  const SizedBox(height: 14),
                  _buildGameCard(
                    context: context,
                    theme: theme,
                    title: 'Word Scramble',
                    description: 'Unscramble translated words',
                    icon: Icons.shuffle_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () {},
                    isLocked: true,
                  ),
                  const SizedBox(height: 14),
                  _buildGameCard(
                    context: context,
                    theme: theme,
                    title: 'Flash Cards',
                    description: 'Learn vocabulary with flashcards',
                    icon: Icons.style_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {},
                    isLocked: true,
                  ),
                  const SizedBox(height: 14),
                  _buildGameCard(
                    context: context,
                    theme: theme,
                    title: 'Speed Translate',
                    description: 'Race against the clock',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () {},
                    isLocked: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.minigames),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isLocked ? theme.hintColor.withOpacity(0.4) : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLocked
                            ? theme.hintColor.withOpacity(0.5)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Icon(
                isLocked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isLocked
                    ? theme.hintColor.withOpacity(0.3)
                    : theme.hintColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}