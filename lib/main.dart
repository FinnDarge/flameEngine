import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/flame_game.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: GameWidget(
          game: MyFlameGame(),
        ),
      ),
    );
  }
}
