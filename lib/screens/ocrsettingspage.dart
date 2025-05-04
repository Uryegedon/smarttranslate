import 'package:flutter/material.dart';

class OcrSettingsPage extends StatefulWidget {
  const OcrSettingsPage({super.key});

  @override
  State<OcrSettingsPage> createState() => _OcrSettingsPageState();
}

class _OcrSettingsPageState extends State<OcrSettingsPage> {
  bool _autoTranslate = true;
  double _textSize = 16.0;
  String _targetLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Spanish'},
    {'code': 'fil', 'label': 'Filipino'},
    {'code': 'fr', 'label': 'French'},
    {'code': 'de', 'label': 'German'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Auto Translate Recognized Text"),
            value: _autoTranslate,
            onChanged: (value) {
              setState(() {
                _autoTranslate = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Target Language"),
            trailing: DropdownButton<String>(
              value: _targetLanguage,
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['label']!),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _targetLanguage = val!;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Result Text Size"),
            subtitle: Slider(
              value: _textSize,
              min: 12.0,
              max: 32.0,
              divisions: 10,
              label: _textSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _textSize = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save Settings"),
            onPressed: () {
              // You can use a settings manager or local storage here
              Navigator.pop(context); // Go back to the OCR page
            },
          )
        ],
      ),
    );
  }
}
