import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../models/character.dart';

/// Visual component for a character sprite positioned on the grid
class CharacterSpriteComponent extends SpriteComponent {
  final Character character;
  final double cellSize;
  
  CharacterSpriteComponent({
    required this.character,
    required this.cellSize,
  }) : super(
          anchor: Anchor.center,
          size: Vector2.all(cellSize * 0.8), // Character takes up 80% of tile
          priority: 10, // Characters render on top of tiles
        ) {
    // Set position based on character's grid position (relative to grid)
    updatePosition();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Load character image
      final imagePath = character.characterClass.imagePath.replaceFirst('assets/images/', '');
      print('🖼 Loading character image: $imagePath');
      final image = await Flame.images.load(imagePath);
      sprite = Sprite(image);
      
      print('✓ Character sprite loaded: ${character.name}');
      
      // Note: Position will be set by setGridOffset() after onLoad completes
    } catch (e) {
      print('⚠ Failed to load character image: $e');
    }
  }

  /// Update visual position based on character's grid position
  void updatePosition() {
    // Convert grid position to pixel position (relative to grid component)
    // Grid position is 0-indexed (0,0) to (rows-1, cols-1)
    // Center the character on the tile
    position = Vector2(
      (character.position.x * cellSize) + (cellSize / 2),
      (character.position.y * cellSize) + (cellSize / 2),
    );
  }
}
