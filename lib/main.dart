import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const MafiaTrainerApp());
}

class MafiaTrainerApp extends StatelessWidget {
  const MafiaTrainerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mafia Voting Practice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

