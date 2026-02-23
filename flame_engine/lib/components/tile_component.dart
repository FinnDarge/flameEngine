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

    // Add character markers
    _addCharacterMarkers();
  }

  /// Add character markers for all characters on this tile
  void _addCharacterMarkers() {
    final count = tile.charactersHere.length;
    if (count == 0) return;

    // Position characters in a grid if multiple
    final positions = _getCharacterPositions(count);
    
    for (int i = 0; i < count; i++) {
      final character = tile.charactersHere[i];
      final charMarker = CircleComponent(
        radius: cellSize * 0.2,
        position: positions[i],
        paint: Paint()..color = Color(character.characterClass.color),
        anchor: Anchor.center,
      );
      add(charMarker);
    }
  }

  /// Get positions for character markers based on count
  List<Vector2> _getCharacterPositions(int count) {
    final center = size / 2;
    final offset = cellSize * 0.15;
    
    if (count == 1) {
      return [center];
    } else if (count == 2) {
      return [
        Vector2(center.x - offset, center.y),
        Vector2(center.x + offset, center.y),
      ];
    } else if (count == 3) {
      return [
        Vector2(center.x, center.y - offset),
        Vector2(center.x - offset, center.y + offset),
        Vector2(center.x + offset, center.y + offset),
      ];
    } else {
      return [
        Vector2(center.x - offset, center.y - offset),
        Vector2(center.x + offset, center.y - offset),
        Vector2(center.x - offset, center.y + offset),
        Vector2(center.x + offset, center.y + offset),
      ];
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
    
    // Remove old character markers (but keep NFC markers and borders)
    final componentsToRemove = children.where((child) {
      if (child is CircleComponent) {
        // Keep NFC marker (purple, small, top-right)
        if (child.paint.color == Colors.purple) return false;
        // Remove character markers
        return true;
      }
      return false;
    }).toList();
    removeAll(componentsToRemove);

    // Re-add character markers
    _addCharacterMarkers();
  }
}
