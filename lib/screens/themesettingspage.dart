import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themeprovider.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Get available theme modes (excluding system)
    final availableModes =
        ThemeMode.values.where((mode) => mode != ThemeMode.system).toList();
    final availableSchemes = HighlightScheme.values;

    return Scaffold(
      appBar: AppBar(title: const Text("Appearance"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Section
            _buildSectionHeader("Theme Mode", context),
            const SizedBox(height: 8),
            _buildThemeModeSelector(availableModes, themeProvider, context),
            const SizedBox(height: 24),

            // Color Scheme Section
            _buildSectionHeader("Color Scheme", context),
            const SizedBox(height: 8),
            _buildColorSchemeSelector(availableSchemes, themeProvider, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildThemeModeSelector(
    List<ThemeMode> modes,
    ThemeProvider themeProvider,
    BuildContext context,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          modes.map((mode) {
            final isSelected = themeProvider.themeMode == mode;
            return ChoiceChip(
              label: Text(
                _formatModeName(mode.toString()),
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => themeProvider.setThemeMode(mode),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildColorSchemeSelector(
    List<HighlightScheme> schemes,
    ThemeProvider themeProvider,
    BuildContext context,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children:
          schemes.map((scheme) {
            return _buildSchemeCard(scheme, themeProvider, context);
          }).toList(),
    );
  }

  Widget _buildSchemeCard(
    HighlightScheme scheme,
    ThemeProvider themeProvider,
    BuildContext context,
  ) {
    final isSelected = themeProvider.highlightScheme == scheme;
    final (IconData icon, Color color) = _getSchemeData(scheme);

    return GestureDetector(
      onTap: () => themeProvider.setHighlightScheme(scheme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(color: color, width: 2)
                  : Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 24,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              _formatSchemeName(scheme.name),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getSchemeData(HighlightScheme scheme) {
    switch (scheme) {
      case HighlightScheme.greenApple:
        return (Icons.eco, Colors.lightGreen.shade400);
      case HighlightScheme.lavender:
        return (Icons.spa, Colors.deepPurpleAccent.shade200);
      default:
        return (Icons.palette, Colors.blueAccent.shade400);
    }
  }

  String _formatModeName(String modeName) {
    return modeName.split('.').last[0].toUpperCase() +
        modeName.split('.').last.substring(1);
  }

  String _formatSchemeName(String schemeName) {
    return schemeName
        .replaceAll("Scheme", "")
        .replaceAll("default", "Default")
        .splitMapJoin(
          RegExp(r'[A-Z]'),
          onMatch: (m) => " ${m.group(0)}",
          onNonMatch:
              (n) => n.isNotEmpty ? n[0].toUpperCase() + n.substring(1) : '',
        )
        .trim();
  }
}
