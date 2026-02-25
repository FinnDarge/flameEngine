import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/character.dart';

/// Visual component for a character sprite positioned on the grid
class CharacterSpriteComponent extends PositionComponent {
  final Character character;
  final double cellSize;
  
  late SpriteComponent _sprite;
  late TextComponent _nameText;
  late TextComponent _healthText;
  
  CharacterSpriteComponent({
    required this.character,
    required this.cellSize,
  }) : super(
          anchor: Anchor.center,
          priority: 10, // Characters render on top of tiles
        ) {
    // Position will be set after loading is complete
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Load character image
      final imagePath = character.characterClass.imagePath.replaceFirst('assets/images/', '');
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
        text: character.name,
        textRenderer: TextPaint(
          style: TextStyle(
            color: Color(character.color),
            fontSize: 12,
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
        text: '❤ ${character.health}',
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
      final healthBg = RectangleComponent(
        size: Vector2(spriteSize * 0.6, 14), // Slightly wider than text
        paint: Paint()..color = Colors.black.withValues(alpha: 0.6),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, -1), // Just above health text
      );
      
      await add(healthBg);
      await add(_sprite);
      await add(_nameText);
      await add(_healthText);
      
      // Set size based on total height (sprite + text)
      size = Vector2(spriteSize, spriteSize + 20);
      
      // Set position after sprite is fully loaded and mounted
      updatePosition();
    } catch (e) {
      print('⚠ Failed to load character image: $e');
    }
  }

  /// Update visual position and health display
  void updatePosition() {
    // Convert grid position to pixel position (relative to grid component)
    // Grid position is 0-indexed (0,0) to (rows-1, cols-1)
    // Center the character on the tile
    final newPosition = Vector2(
      (character.position.x * cellSize) + (cellSize / 2),
      (character.position.y * cellSize) + (cellSize / 2),
    );
    
    position = newPosition;
    
    // Update health display
    if (isMounted) {
      _healthText.text = '❤ ${character.health}';
    }
  }
}
