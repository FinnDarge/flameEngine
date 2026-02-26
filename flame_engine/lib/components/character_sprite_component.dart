import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/character.dart';

/// Visual component for a character sprite positioned on the grid
class CharacterSpriteComponent extends PositionComponent {
  final Character character;
  final double cellSize;
  
  /// Sub-position within tile (0-3): 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right
  int subPosition;
  
  late SpriteComponent _sprite;
  late TextComponent _nameText;
  late TextComponent _healthText;
  
  CharacterSpriteComponent({
    required this.character,
    required this.cellSize,
    this.subPosition = 0,
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
      
      // Create sprite at 1/4 size for 2x2 sub-grid (0.35 = 35% of cell)
      final spriteSize = cellSize * 0.35; // 35% of cell size (allows 2x2 grid)
      _sprite = SpriteComponent(
        sprite: Sprite(image),
        size: Vector2.all(spriteSize),
        anchor: Anchor.topLeft,
        position: Vector2(0, 14), // Position below the text (14px for health + name)
      );
      
      // Name text above sprite (smaller for compact display)
      _nameText = TextComponent(
        text: character.name,
        textRenderer: TextPaint(
          style: TextStyle(
            color: Color(character.color),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 1, offset: Offset(0.5, 0.5)),
            ],
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, 8), // 8px from top (below health)
      );
      
      // Health text above name (smaller)
      _healthText = TextComponent(
        text: '❤ ${character.health}',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.red,
            fontSize: 7,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 1, offset: Offset(0.5, 0.5)),
            ],
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, 0), // At the top
      );
      
      // Background for health text (semi-transparent)
      final healthBg = RectangleComponent(
        size: Vector2(spriteSize * 0.8, 10), // Cover text area
        paint: Paint()..color = Colors.black.withValues(alpha: 0.6),
        anchor: Anchor.topCenter,
        position: Vector2(spriteSize / 2, -1), // Just above health text
      );
      
      await add(healthBg);
      await add(_sprite);
      await add(_nameText);
      await add(_healthText);
      
      // Set size based on total height (sprite + text, smaller for sub-grid)
      size = Vector2(spriteSize, spriteSize + 14);
      
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
    
    // Calculate sub-grid offset within the tile
    // 2x2 sub-grid: 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right
    final subRow = subPosition ~/ 2; // 0 or 1 (top or bottom)
    final subCol = subPosition % 2;  // 0 or 1 (left or right)
    
    // Each sub-position takes half the cell (0.5)
    // Position at center of each quadrant: 0.25 or 0.75 of cellSize
    final offsetX = (subCol == 0) ? cellSize * 0.25 : cellSize * 0.75;
    final offsetY = (subRow == 0) ? cellSize * 0.25 : cellSize * 0.75;
    
    final newPosition = Vector2(
      (character.position.x * cellSize) + offsetX,
      (character.position.y * cellSize) + offsetY,
    );
    
    position = newPosition;
    
    // Update health display
    if (isMounted) {
      _healthText.text = '❤ ${character.health}';
    }
  }
  
  /// Update the sub-position within the tile
  void updateSubPosition(int newSubPosition) {
    subPosition = newSubPosition;
    updatePosition();
  }
}
