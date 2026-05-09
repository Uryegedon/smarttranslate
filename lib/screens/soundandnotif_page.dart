import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Sound and Notification',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purple[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Allow Notification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: allowNotification,
                    onChanged: (value) {
                      setState(() {
                        allowNotification = value;
                      });
                    },
                    activeThumbColor: Colors.black,
                    inactiveThumbColor: Colors.pink[100],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 166, 238, 232),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  RadioGroup<String>(
                    groupValue: soundOption,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        soundOption = value;
                      });
                    },
                    child: const Column(
                      children: [
                        RadioListTile(
                          value: 'sound',
                          title: Text('Allow sound and vibration'),
                        ),
                        RadioListTile(value: 'silent', title: Text('Silent')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sound Volume',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Slider(
              value: soundVolume,
              onChanged: (value) {
                setState(() {
                  soundVolume = value;
                });
              },
              activeColor: Colors.blue,
              inactiveColor: Colors.blue[100],
            ),
          ],
        ),
      ),
    );
  }
}
