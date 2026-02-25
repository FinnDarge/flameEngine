import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import '../models/grid_tile.dart' as models;
import '../models/tile_type.dart';

/// Visual component for a single room (tile) in the dungeon grid
/// Represents one 10cm x 10cm physical room
class TileComponent extends PositionComponent {
  final models.GridTile tile;
  final double cellSize;
  final bool isCorner;
  final String? cornerType; // 'topleft', 'topright', 'bottomleft', 'bottomright'
  
  late RectangleComponent background;
  late RectangleComponent border;
  SpriteComponent? sprite;

  TileComponent({
    required this.tile,
    required this.cellSize,
    required Vector2 position,
    this.isCorner = false,
    this.cornerType,
  }) : super(
          position: position,
          size: Vector2.all(cellSize),
          priority: 0, // Tiles render at base priority
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load appropriate tile image
    bool spriteLoaded = false;
    try {
      String imagePath;
      
      // Use corner images for corner tiles
      if (isCorner) {
        // Alternate between corner images based on position
        if (cornerType == 'topleft' || cornerType == 'bottomright') {
          imagePath = 'tiles/StoneCorner1.jpg';
        } else {
          imagePath = 'tiles/StoneCorner2.jpg';
        }
      } else {
        // Use Stone2.jpg for all other tiles
        imagePath = 'tiles/Stone2.jpg';
      }
      
      print('🖼 Loading tile image: $imagePath');
      final image = await Flame.images.load(imagePath);
      sprite = SpriteComponent(
        sprite: Sprite(image),
        size: size,
        anchor: Anchor.topLeft,
      );
      add(sprite!);
      spriteLoaded = true;
      print('✓ Tile image loaded successfully');
    } catch (e) {
      print('⚠ Failed to load tile image: $e');
      print('  Falling back to colored background');
    }

    // If sprite not loaded, use colored background as fallback
    if (!spriteLoaded) {
      background = RectangleComponent(
        size: size,
        paint: Paint()..color = Color(tile.type.defaultColor),
      );
      add(background);
    }

    // Room border (thicker for better visibility)
    border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(border);

    // NFC markers removed - not needed for visual display
    // Character sprites are shown on top of grid
  }

  /// Updates the visual representation when tile state changes
  void updateTile() {
    // Note: We don't change the background tile image as it's static
    // Character sprites are handled separately in DungeonGame
  }
}
