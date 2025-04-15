import 'package:flutter/material.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Minigames',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 20),
            Text('Choose your game',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

  SizedBox(height: 40),

ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/wordmatching');
  },
  style: ElevatedButton.styleFrom(
    shape: StadiumBorder(),
    minimumSize: Size(230, 70),
    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    backgroundColor: Color.fromARGB(255, 231, 229, 229),
  ),
  child: Text(
    'Guess the Language',
    style: TextStyle(color: Colors.black),
  ),
),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                minimumSize: Size(230, 70),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Color.fromARGB(255, 231, 229, 229),
              ),
              child: Text('TODO//add game',
                style: TextStyle(color: Colors.black), 
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                minimumSize: Size(230, 70),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Color.fromARGB(255, 231, 229, 229),
              ),
              child: Text('TODO//add game',
                style: TextStyle(color: Colors.black),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                minimumSize: Size(230, 70),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Color.fromARGB(255, 231, 229, 229),
              ),
              child: Text('TODO//add game',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),

bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[300],
        selectedItemColor: Colors.black,
        onTap: (index) => _onItemTapped(context, index),
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
    );
  }
}