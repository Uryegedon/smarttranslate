import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SoundNotificationPage extends StatefulWidget {
  const SoundNotificationPage({super.key});

  @override
  State<SoundNotificationPage> createState() => _SoundNotificationPageState();
}

class _SoundNotificationPageState extends State<SoundNotificationPage> {
  bool allowNotification = false;
  String soundOption = 'sound';
  double soundVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      allowNotification = settings.allowNotifications;
      soundOption = settings.soundOption;
      soundVolume = settings.soundVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Sound & Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification toggle card
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              size: 20,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Allow Notifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: allowNotification,
                            onChanged: (value) {
                              setState(() {
                                allowNotification = value;
                              });
                              SettingsService.saveAllowNotifications(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sound options card
                  Container(
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
                      children: [
                        RadioListTile<String>(
                          value: 'sound',
                          groupValue: soundOption,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              soundOption = value;
                            });
                            SettingsService.saveSoundOption(value);
                          },
                          title: Row(
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                size: 20,
                                color: primary,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sound and vibration',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: theme.dividerColor),
                        ),
                        RadioListTile<String>(
                          value: 'silent',
                          groupValue: soundOption,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              soundOption = value;
                            });
                            SettingsService.saveSoundOption(value);
                          },
                          title: Row(
                            children: [
                              Icon(
                                Icons.volume_off_rounded,
                                size: 20,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Silent',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Volume slider
                  Text(
                    'SOUND VOLUME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
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
                        Icon(
                          Icons.volume_mute_rounded,
                          size: 20,
                          color: theme.hintColor,
                        ),
                        Expanded(
                          child: Slider(
                            value: soundVolume,
                            onChanged: (value) {
                              setState(() {
                                soundVolume = value;
                              });
                              SettingsService.saveSoundVolume(value);
                            },
                          ),
                        ),
                        Icon(Icons.volume_up_rounded, size: 20, color: primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
