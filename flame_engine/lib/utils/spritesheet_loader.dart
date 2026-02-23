import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import '../models/tile_type.dart';

/// Manages loading and accessing sprites from the roguelike dungeon spritesheet
class SpritesheetLoader {
  static const String spritesheetPath = 'tiles/spritesheet/roguelikeDungeon_transparent.png';
  
  /// Size of each tile in the spritesheet (in pixels)
  /// Common sizes: 16x16, 32x32, 48x48
  /// Adjust this based on your actual spritesheet
  static const double tileSize = 16.0;
  
  SpriteSheet? _spriteSheet;
  bool _isLoaded = false;
  
  /// Mapping of tile types to their spritesheet coordinates (row, col)
  /// Adjust these positions based on your actual spritesheet layout
  static const Map<TileType, TilePosition> tileMapping = {
    TileType.floor: TilePosition(row: 1, col: 10),     // Column 11, Row 2 (0-indexed: col 10, row 1)
    TileType.wall: TilePosition(row: 0, col: 1),       // Adjust to your wall tile
    TileType.door: TilePosition(row: 1, col: 0),       // Adjust to your door tile
    TileType.enemy: TilePosition(row: 2, col: 0),      // Adjust to your enemy tile
    TileType.treasure: TilePosition(row: 3, col: 0),   // Adjust to your treasure tile
    TileType.trap: TilePosition(row: 4, col: 0),       // Adjust to your trap tile
    TileType.specialEvent: TilePosition(row: 5, col: 0), // Adjust to your special tile
    TileType.player: TilePosition(row: 6, col: 0),     // Adjust to your player tile
    TileType.empty: TilePosition(row: 7, col: 0),      // Adjust to your empty/black tile
  };
  
  /// Load the spritesheet
  Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      // Load the image using Flame's image cache
      final image = await Flame.images.load(spritesheetPath);
      
      _spriteSheet = SpriteSheet(
        image: image,
        srcSize: Vector2.all(tileSize),
      );
      
      _isLoaded = true;
      print('✓ Spritesheet loaded: $spritesheetPath');
      print('  Image size: ${image.width}x${image.height}');
      print('  Tile size: ${tileSize}x$tileSize');
      print('  Grid: ${(image.width / tileSize).floor()}x${(image.height / tileSize).floor()} tiles');
    } catch (e) {
      print('✗ Failed to load spritesheet: $e');
      print('  Path attempted: assets/images/$spritesheetPath');
      _isLoaded = false;
    }
  }
  
  /// Get a sprite for a specific tile type
  Sprite? getSpriteForTileType(TileType type) {
    if (!_isLoaded || _spriteSheet == null) {
      print('⚠ Spritesheet not loaded yet');
      return null;
    }
    
    final position = tileMapping[type];
    if (position == null) {
      print('⚠ No mapping found for tile type: $type');
      return null;
    }
    
    return _spriteSheet!.getSprite(position.row, position.col);
  }
  
  /// Get a sprite at specific coordinates
  Sprite? getSpriteAt(int row, int col) {
    if (!_isLoaded || _spriteSheet == null) {
      return null;
    }
    
    return _spriteSheet!.getSprite(row, col);
  }
  
  bool get isLoaded => _isLoaded;
}

/// Helper class to store tile positions in the spritesheet
class TilePosition {
  final int row;
  final int col;
  
  const TilePosition({required this.row, required this.col});
}
