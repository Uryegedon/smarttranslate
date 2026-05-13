import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'themeprovider.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  // ── Scheme metadata ──────────────────────────────────────────
  static const _schemeData = <HighlightScheme, _SchemeInfo>{
    HighlightScheme.defaultScheme: _SchemeInfo(
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0D9488),
      name: 'Teal',
      subtitle: 'Default',
    ),
    HighlightScheme.greenApple: _SchemeInfo(
      icon: Icons.eco_rounded,
      color: Color(0xFF65A30D),
      name: 'Green',
      subtitle: 'Apple',
    ),
    HighlightScheme.lavender: _SchemeInfo(
      icon: Icons.spa_rounded,
      color: Color(0xFF7C3AED),
      name: 'Lavender',
      subtitle: 'Purple',
    ),
    HighlightScheme.roseGold: _SchemeInfo(
      icon: Icons.favorite_rounded,
      color: Color(0xFFE11D48),
      name: 'Rose',
      subtitle: 'Gold',
    ),
    HighlightScheme.ocean: _SchemeInfo(
      icon: Icons.waves_rounded,
      color: Color(0xFF0284C7),
      name: 'Ocean',
      subtitle: 'Blue',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    final modes = ThemeMode.values.where((m) => m != ThemeMode.system).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Live preview banner ──
          _LivePreviewBanner(themeProvider: themeProvider),

          // ── Settings list ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back + title ──
                  Row(
                    children: [
                      _BackButton(theme: theme),
                      const SizedBox(width: 14),
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Theme mode ──
                  _SectionLabel('THEME MODE', theme),
                  const SizedBox(height: 12),
                  _ThemeModeSelector(
                    modes: modes,
                    themeProvider: themeProvider,
                    theme: theme,
                  ),

                  const SizedBox(height: 32),

                  // ── Color scheme ──
                  _SectionLabel('COLOR SCHEME', theme),
                  const SizedBox(height: 12),
                  _ColorSchemeGrid(
                    schemeData: _schemeData,
                    themeProvider: themeProvider,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Live preview banner at the top
// ─────────────────────────────────────────────
class _LivePreviewBanner extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _LivePreviewBanner({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final primary = themeProvider.primaryColor;
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.75)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          // Mini mock phone preview
          Container(
            width: 52,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mock AppBar
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      _previewBar(isDark, 0.9),
                      const SizedBox(height: 3),
                      _previewBar(isDark, 0.6),
                      const SizedBox(height: 3),
                      _previewBar(isDark, 0.75),
                    ],
                  ),
                ),
                const Spacer(),
                // Mock bottom nav
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              i == 0
                                  ? primary
                                  : (isDark ? Colors.white24 : Colors.black12),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Changes apply instantly',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDark ? '🌙 Dark Mode' : '☀️ Light Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBar(bool isDark, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Theme mode row selector
// ─────────────────────────────────────────────
class _ThemeModeSelector extends StatelessWidget {
  final List<ThemeMode> modes;
  final ThemeProvider themeProvider;
  final ThemeData theme;
  const _ThemeModeSelector({
    required this.modes,
    required this.themeProvider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children:
            modes.asMap().entries.map((entry) {
              final mode = entry.value;
              final isSelected = themeProvider.themeMode == mode;
              final icon =
                  mode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded;
              final label =
                  mode == ThemeMode.light ? 'Light Mode' : 'Dark Mode';
              final desc =
                  mode == ThemeMode.light
                      ? 'Bright, clean interface'
                      : 'Easy on the eyes at night';
              final color = theme.colorScheme.primary;

              return Column(
                children: [
                  _AnimatedTile(
                    isSelected: isSelected,
                    color: color,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setThemeMode(mode);
                    },
                    child: Row(
                      children: [
                        // Icon badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? color.withOpacity(0.12)
                                    : theme.dividerColor.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            size: 22,
                            color: isSelected ? color : theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Check indicator
                        AnimatedScale(
                          scale: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.key < modes.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: theme.dividerColor),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Color scheme grid
// ─────────────────────────────────────────────
class _ColorSchemeGrid extends StatelessWidget {
  final Map<HighlightScheme, _SchemeInfo> schemeData;
  final ThemeProvider themeProvider;
  final ThemeData theme;
  const _ColorSchemeGrid({
    required this.schemeData,
    required this.themeProvider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final schemes = schemeData.keys.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: schemes.length,
      itemBuilder: (_, i) {
        final scheme = schemes[i];
        final info = schemeData[scheme]!;
        final isSelected = themeProvider.highlightScheme == scheme;

        return _SchemeCard(
          info: info,
          isSelected: isSelected,
          theme: theme,
          onTap: () {
            HapticFeedback.selectionClick();
            themeProvider.setHighlightScheme(scheme);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Individual scheme card with press animation
// ─────────────────────────────────────────────
class _SchemeCard extends StatefulWidget {
  final _SchemeInfo info;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;
  const _SchemeCard({
    required this.info,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.info.color;
    final isSelected = widget.isSelected;
    final theme = widget.theme;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border:
                isSelected
                    ? Border.all(color: color, width: 2.5)
                    : Border.all(color: theme.dividerColor, width: 1),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Colour swatch circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: isSelected ? 52 : 44,
                height: isSelected ? 52 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.65)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : widget.info.icon,
                  color: Colors.white,
                  size: isSelected ? 26 : 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.info.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.info.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? color.withOpacity(0.7) : theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated tile for press feedback
// ─────────────────────────────────────────────
class _AnimatedTile extends StatefulWidget {
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  const _AnimatedTile({
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _bgAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _bgAnim = ColorTween(
      begin: Colors.transparent,
      end: widget.color.withOpacity(0.05),
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder:
          (_, child) => Material(
            color: _bgAnim.value ?? Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTapDown: (_) => _ctrl.forward(),
              onTapUp: (_) => _ctrl.reverse(),
              onTapCancel: () => _ctrl.reverse(),
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: widget.color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: widget.child,
              ),
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final ThemeData theme;
  const _BackButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: theme.colorScheme.onSurface,
          size: 22,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.hintColor,
        letterSpacing: 1.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────
class _SchemeInfo {
  final IconData icon;
  final Color color;
  final String name;
  final String subtitle;
  const _SchemeInfo({
    required this.icon,
    required this.color,
    required this.name,
    required this.subtitle,
  });
}
