import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/enemy.dart';

/// Visual component for an enemy sprite positioned on the grid
class EnemySpriteComponent extends PositionComponent {
  final Enemy enemy;
  final double cellSize;
  
  late SpriteComponent _sprite;
  late TextComponent _nameText;
  late TextComponent _healthText;
  late RectangleComponent _healthBg;
  
  EnemySpriteComponent({
    required this.enemy,
    required this.cellSize,
    required Vector2 gridPosition,
  }) : super(
          anchor: Anchor.center,
          priority: 9, // Enemies render below characters (priority 10)
        ) {
    // Calculate position based on grid coordinates
    position = Vector2(
      (gridPosition.x * cellSize) + (cellSize / 2),
      (gridPosition.y * cellSize) + (cellSize / 2),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Load enemy image
      final imagePath = enemy.type.imagePath;
      final image = await Flame.images.load(imagePath);
      
      // Create sprite with proper aspect ratio
      final spriteSize = cellSize * 0.7; // 70% of cell size
      _sprite = SpriteComponent(
        sprite: Sprite(image),
        size: Vector2.all(spriteSize),
        anchor: Anchor.topLeft,
        position: Vector2(0, 20), // Position below the text (20px for health + name)
      );
      
      // Name text above sprite
      _nameText = TextComponent(
        text: enemy.type.displayName,
        textRenderer: TextPaint(
          style: TextStyle(
            color: enemy.color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
            ],
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, 12), // 12px from top (below health)
      );
      
      // Health text above name
      _healthText = TextComponent(
        text: '❤ ${enemy.health}',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
            ],
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, 0), // At the top
      );
      
      // Background for health text (semi-transparent)
      _healthBg = RectangleComponent(
        size: Vector2(spriteSize * 0.6, 14), // Slightly wider than text
        paint: Paint()..color = Colors.black.withValues(alpha: 0.6),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, -1), // Just above health text
      );
      
      await add(_healthBg);
      await add(_sprite);
      await add(_nameText);
      await add(_healthText);
      
      // Set size based on total height (sprite + text)
      size = Vector2(spriteSize, spriteSize + 20);
    } catch (e) {
      print('⚠ Failed to load enemy image: $e');
    }
  }

  /// Update health display when enemy takes damage
  void updateHealth() {
    if (isMounted) {
      _healthText.text = '❤ ${enemy.health}';
    }
  }
}
