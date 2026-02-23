import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'components/player.dart';

/// Main game class that extends FlameGame
/// This is where you manage your game logic, components, and state
class MyFlameGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Player player;

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add a simple text component as a title
    add(
      TextComponent(
        text: 'Flame Engine Game',
        position: Vector2(size.x / 2, 50),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // Add the player component
    player = Player();
    add(player);

    // Add instructions
    add(
      TextComponent(
        text: 'Tap anywhere to move the square',
        position: Vector2(size.x / 2, size.y - 50),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    // Move player to tapped position
    player.moveTo(info.eventPosition.global);
  }
}
