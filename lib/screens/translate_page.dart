import 'package:flutter/material.dart';
import 'translationservice.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  _TranslatorScreenState createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _controller = TextEditingController();
  String _translatedText = "";

  void _translate(String text) async {
    if (text.isNotEmpty) {
      try {
        String translated = await translateText(text);
        setState(() {
          _translatedText = translated;
        });
      } catch (e) {
        setState(() {
          _translatedText = "Translation failed: $e";
        });
      }
    } else {
      setState(() {
        _translatedText = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Light teal background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SmartPath Translator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input Card
              _buildLanguageCard(
                language: 'English',
                controller: _controller,
                onChanged: _translate,
                color: const Color(0xFF9E8FB2),
                isOutput: false,
              ),
              const SizedBox(height: 20),
              // Output Card
              _buildLanguageCard(
                language: 'Spanish',
                outputText: _translatedText,
                color: const Color(0xFF6DB7A3),
                isOutput: true,
              ),
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Alternatives',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[300],
        selectedItemColor: Colors.black,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: ''),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 14,
              
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required String language,
    TextEditingController? controller,
    String? outputText,
    Color? color,
    bool isOutput = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.pink[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isOutput
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        outputText ?? "",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Column(
                      children: const [
                        Icon(Icons.copy, color: Colors.white),
                        SizedBox(height: 8),
                        Icon(Icons.volume_up, color: Colors.white),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: onChanged,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Hello, how are you',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(Icons.mic, color: Colors.white),
                        SizedBox(width: 8),
                        Icon(Icons.volume_up, color: Colors.white),
                      ],
                    )
                  ],
                ),
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/translate');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/camera');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/minigames');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
