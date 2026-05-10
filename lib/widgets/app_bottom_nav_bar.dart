import 'package:flutter/material.dart';

enum AppTab { translate, camera, minigames, profile }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentTab});

  final AppTab currentTab;

  static const _routes = <AppTab, String>{
    AppTab.translate: '/translate',
    AppTab.camera: '/camera',
    AppTab.minigames: '/minigames',
    AppTab.profile: '/profile',
  };

  void _onTap(BuildContext context, int index) {
    final selectedTab = AppTab.values[index];
    final selectedRoute = _routes[selectedTab]!;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (selectedRoute == currentRoute) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      selectedRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final unselected = theme.hintColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.translate_rounded,
                index: AppTab.translate.index,
                label: 'Translate',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.camera_alt_rounded,
                index: AppTab.camera.index,
                label: 'Camera',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.extension_rounded,
                index: AppTab.minigames.index,
                label: 'Games',
                primary: primary,
                unselected: unselected,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_rounded,
                index: AppTab.profile.index,
                label: 'Profile',
                primary: primary,
                unselected: unselected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required String label,
    required Color primary,
    required Color unselected,
  }) {
    final isSelected = currentTab.index == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? primary : unselected,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
