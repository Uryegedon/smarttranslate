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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentTab.index,
      height: 68,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final selectedTab = AppTab.values[index];
        final selectedRoute = _routes[selectedTab]!;
        final currentRoute = ModalRoute.of(context)?.settings.name;

        if (selectedRoute == currentRoute) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          selectedRoute,
          (route) => false,
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.translate_outlined),
          selectedIcon: Icon(Icons.translate),
          label: 'Translate',
        ),
        NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt),
          label: 'Camera',
        ),
        NavigationDestination(
          icon: Icon(Icons.extension_outlined),
          selectedIcon: Icon(Icons.extension),
          label: 'Games',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
