import 'dart:math';
import 'package:flutter/material.dart';


class GuessLanguageScreen extends StatefulWidget {
  const GuessLanguageScreen({super.key});

  @override
  _GuessLanguageScreenState createState() => _GuessLanguageScreenState();
}

class _GuessLanguageScreenState extends State<GuessLanguageScreen> {
  final Map<String, String> wordPairs = {
    'MONEY': 'PERA',
    'CIRCLE': 'BILOG',
    'PAPER': 'PAPEL',
    'FISH': 'ISDA',
    'CAT': 'PUSA',
    'DOG': 'ASO',
    'HOUSE': 'BAHAY',
    'SUN': 'ARAW',
    'WATER': 'TUBIG',
    'FOOD': 'PAGKAIN',
    'LOVE': 'PAGIBIG',
    'BOOK': 'LIBRO',
    'CHAIR': 'UPUAN',
    'TREE': 'PUNO',
    'MOUSE': 'DAGA',
    'PENCIL': 'LAPIS',
  };

  String displayedWord = '';
  String correctLanguage = '';
  int score = 0;
  int lives = 3;

  @override
  void initState() {
    super.initState();
    generateNewWord();
  }

  void generateNewWord() {
    final random = Random();
    final allKeys = wordPairs.keys.toList();
    final englishWord = allKeys[random.nextInt(allKeys.length)];
    final filipinoWord = wordPairs[englishWord]!;

    bool showEnglish = random.nextBool();
    displayedWord = showEnglish ? englishWord : filipinoWord;
    correctLanguage = showEnglish ? 'ENGLISH' : 'FILIPINO';

    setState(() {});
  }

  void checkAnswer(String selectedLanguage) {
    if (selectedLanguage == correctLanguage) {
      setState(() {score++;});
    } 
    else {
      setState(() {lives--;});

      if (lives <= 0) {
        showGameOverDialog();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect! It was $correctLanguage.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }

    generateNewWord();
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Game Over'),
        content: Text('Your final score is $score.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                score = 0;
                lives = 3;
                generateNewWord();
              });
              Navigator.of(context).pop();
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget buildAnswerButton(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () => checkAnswer(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: Size(200, 60),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: Text('GUESS THE LANGUAGE',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Divider(color: Colors.black),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    lives,
                    (index) => Icon(Icons.favorite, color: Colors.cyan[800]),
                  ),
                ),
                Text(
                  'SCORE: $score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.symmetric(vertical: 50, horizontal: 100),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
            child: Text(
              displayedWord,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            ),
          ),
          Spacer(flex: 2),
          buildAnswerButton('ENGLISH', Colors.green),
          buildAnswerButton('FILIPINO', Colors.purple),
          Spacer(flex: 1),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[300],
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: ''),
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
    );
  }
}