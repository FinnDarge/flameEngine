import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/grid_tile.dart' as models;
import '../models/tile_type.dart';
import '../utils/spritesheet_loader.dart';

/// Visual component for a single room (tile) in the dungeon grid
/// Represents one 10cm x 10cm physical room
class TileComponent extends PositionComponent {
  final models.GridTile tile;
  final double cellSize;
  final SpritesheetLoader? spritesheetLoader;
  
  late RectangleComponent background;
  late RectangleComponent border;
  SpriteComponent? sprite;

  TileComponent({
    required this.tile,
    required this.cellSize,
    required Vector2 position,
    this.spritesheetLoader,
  }) : super(
          position: position,
          size: Vector2.all(cellSize),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Try to load sprite from spritesheet
    bool spriteLoaded = false;
    if (spritesheetLoader != null && spritesheetLoader!.isLoaded) {
      final tileSprite = spritesheetLoader!.getSpriteForTileType(tile.type);
      if (tileSprite != null) {
        sprite = SpriteComponent(
          sprite: tileSprite,
          size: size,
          anchor: Anchor.topLeft,
        );
        add(sprite!);
        spriteLoaded = true;
      }
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

    // Add NFC indicator if this room has an NFC tag
    if (tile.nfcTagId != null) {
      final nfcMarker = CircleComponent(
        radius: cellSize * 0.08,
        position: Vector2(cellSize * 0.85, cellSize * 0.15),
        paint: Paint()..color = Colors.purple,
        anchor: Anchor.center,
      );
      add(nfcMarker);
    }

    // Add player marker if present
    if (tile.hasPlayer) {
      final playerMarker = CircleComponent(
        radius: cellSize * 0.25,
        position: size / 2,
        paint: Paint()..color = const Color(0xFF00FF00),
        anchor: Anchor.center,
      );
      add(playerMarker);
    }
  }

  /// Updates the visual representation when tile state changes
  void updateTile() {
    // Update sprite or background color
    if (sprite != null && spritesheetLoader != null && spritesheetLoader!.isLoaded) {
      final newSprite = spritesheetLoader!.getSpriteForTileType(tile.type);
      if (newSprite != null) {
        sprite!.sprite = newSprite;
      }
    } else if (sprite == null) {
      // Update background color if using colored rectangles
      background.paint.color = Color(tile.type.defaultColor);
    }
    
    // Remove old markers
    removeAll(children.where((child) => child is CircleComponent).toList());

    // Re-add markers based on new state
    if (tile.nfcTagId != null) {
      final nfcMarker = CircleComponent(
        radius: cellSize * 0.08,
        position: Vector2(cellSize * 0.85, cellSize * 0.15),
        paint: Paint()..color = Colors.purple,
        anchor: Anchor.center,
      );
      add(nfcMarker);
    }

    if (tile.hasPlayer) {
      final playerMarker = CircleComponent(
        radius: cellSize * 0.25,
        position: size / 2,
        paint: Paint()..color = const Color(0xFF00FF00),
        anchor: Anchor.center,
      );
      add(playerMarker);
    }
  }
}
