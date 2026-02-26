import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import '../models/grid_tile.dart' as models;
import '../models/tile_type.dart';

/// Visual component for a single room (tile) in the dungeon grid
/// Represents one 10cm x 10cm physical room
class TileComponent extends PositionComponent with TapCallbacks {
  final models.GridTile tile;
  final double cellSize;
  final bool isCorner;
  final String? cornerType; // 'topleft', 'topright', 'bottomleft', 'bottomright'
  final int row;
  final int col;
  final void Function(int row, int col)? onTileTapped;
  
  late RectangleComponent background;
  late RectangleComponent border;
  SpriteComponent? sprite;
  RectangleComponent? fogOverlay;
  CircleComponent? eventIndicator;

  TileComponent({
    required this.tile,
    required this.cellSize,
    required Vector2 position,
    required this.row,
    required this.col,
    this.onTileTapped,
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
      
      final image = await Flame.images.load(imagePath);
      sprite = SpriteComponent(
        sprite: Sprite(image),
        size: size,
        anchor: Anchor.topLeft,
      );
      add(sprite!);
      spriteLoaded = true;
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

    // Add fog of war overlay if tile not revealed
    if (!tile.isRevealed) {
      fogOverlay = RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.black.withValues(alpha: 0.85),
        priority: 5, // Above background but below characters
      );
      add(fogOverlay!);
    }

    // Add event indicator if tile has an event
    if (tile.event != null && tile.isRevealed && !tile.event!.isCompleted) {
      eventIndicator = CircleComponent(
        radius: cellSize * 0.12,
        paint: Paint()..color = tile.event!.type.color,
        position: Vector2(cellSize * 0.85, cellSize * 0.15),
        anchor: Anchor.center,
        priority: 6,
      );
      add(eventIndicator!);
    }

    // NFC markers removed - not needed for visual display
    // Character sprites are shown on top of grid
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTileTapped?.call(row, col);
    super.onTapUp(event);
  }

  /// Updates the visual representation when tile state changes
  void updateTile() {
    // Update fog of war
    if (tile.isRevealed && fogOverlay != null) {
      remove(fogOverlay!);
      fogOverlay = null;
    } else if (!tile.isRevealed && fogOverlay == null) {
      fogOverlay = RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.black.withValues(alpha: 0.85),
        priority: 5,
      );
      add(fogOverlay!);
    }

    // Update event indicator
    final shouldShowEvent = tile.event != null && 
                            tile.isRevealed && 
                            !tile.event!.isCompleted;
    
    if (shouldShowEvent && eventIndicator == null) {
      eventIndicator = CircleComponent(
        radius: cellSize * 0.12,
        paint: Paint()..color = tile.event!.type.color,
        position: Vector2(cellSize * 0.85, cellSize * 0.15),
        anchor: Anchor.center,
        priority: 6,
      );
      add(eventIndicator!);
    } else if (!shouldShowEvent && eventIndicator != null) {
      remove(eventIndicator!);
      eventIndicator = null;
    }
  }
}
