import 'package:flutter/material.dart';



class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({super.key});

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
      case 3:
      Navigator.pushReplacementNamed(context, '/profile');
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Change background color here
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent, // Change app bar background color here
        elevation: 0,
        title: Text(
          'SmartPath Translator',
          style: TextStyle(
            fontSize: 24, // Change title font size here
            fontWeight: FontWeight.bold, // Change title font weight here
            color: Colors.black, // Change title color here
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Adjust padding here
              child: Column(
                children: [
                  LanguageCard(
                    language: 'English',
                    text: 'Hello, how are you',
                    cardColor: Colors.purpleAccent, // Change English card color here
                    iconColor: Colors.black, // Change microphone icon color here
                  ),
                  SizedBox(height: 16), // Adjust spacing between cards here
                  LanguageCard(
                    language: 'Spanish',
                    text: 'Hola, cómo estás',
                    cardColor: Colors.teal, // Change Spanish card color here
                    iconColor: Colors.black, // Change speaker icon color here
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Alternatives',
                    style: TextStyle(
                      fontSize: 16, // Change alternatives text size here
                      color: Colors.black, // Change alternatives text color here
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[300],
        selectedItemColor: Colors.black,
        onTap: (index) => _onItemTapped(context, index), // Handle navigation
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension),
            label: '',
          ),
           BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage('assets/avatar.jpg'),
              backgroundColor: Colors.greenAccent,
            ),
            label: '',
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class LanguageCard extends StatelessWidget {
  final String language;
  final String text;
  final Color cardColor;
  final Color iconColor;

  const LanguageCard({super.key, 
    required this.language,
    required this.text,
    required this.cardColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16), // Adjust card padding here
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16), // Adjust card border radius here
        boxShadow: [
          BoxShadow(
            color: Colors.black26, // Change shadow color here
            blurRadius: 8, // Adjust shadow blur radius here
            offset: Offset(0, 4), // Adjust shadow offset here
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: TextStyle(
                  fontSize: 18, // Change language label font size here
                  fontWeight: FontWeight.bold, // Change language label font weight here
                  color: Colors.white, // Change language label color here
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.white), // Change dropdown icon color here
            ],
          ),
          SizedBox(height: 8), // Adjust spacing between language and text here
          Text(
            text,
            style: TextStyle(
              fontSize: 16, // Change text font size here
              color: Colors.white, // Change text color here
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.mic, color: iconColor), // Change microphone icon color here
              Icon(Icons.volume_up, color: iconColor), // Change speaker icon color here
            ],
          ),
        ],
      ),
    );
  }
}