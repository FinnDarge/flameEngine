/// Different types of tiles in the dungeon
enum TileType {
  floor,        // Basic walkable tile
  wall,         // Non-walkable obstacle
  door,         // Entrance/exit
  enemy,        // Enemy encounter
  treasure,     // Loot/treasure
  trap,         // Trap tile
  specialEvent, // Special NFC-triggered event
  player,       // Player position
  empty,        // Not yet revealed
}

/// Extension to get display properties for each tile type
extension TileTypeExtension on TileType {
  /// Returns the default color for this tile type (used when no asset available)
  int get defaultColor {
    switch (this) {
      case TileType.floor:
        return 0xFFCCCCCC;
      case TileType.wall:
        return 0xFF333333;
      case TileType.door:
        return 0xFF8B4513;
      case TileType.enemy:
        return 0xFFFF0000;
      case TileType.treasure:
        return 0xFFFFD700;
      case TileType.trap:
        return 0xFFFF6347;
      case TileType.specialEvent:
        return 0xFF9370DB;
      case TileType.player:
        return 0xFF0000FF;
      case TileType.empty:
        return 0xFF000000;
    }
  }

  /// Returns the asset path for this tile type
  String? get assetPath {
    switch (this) {
      case TileType.floor:
        return 'assets/images/tiles/floor.png';
      case TileType.wall:
        return 'assets/images/tiles/wall.png';
      case TileType.door:
        return 'assets/images/tiles/door.png';
      case TileType.enemy:
        return 'assets/images/enemies/enemy.png';
      case TileType.treasure:
        return 'assets/images/tiles/treasure.png';
      case TileType.trap:
        return 'assets/images/tiles/trap.png';
      case TileType.specialEvent:
        return 'assets/images/tiles/special.png';
      case TileType.player:
        return 'assets/images/characters/player.png';
      case TileType.empty:
        return null;
    }
  }

  /// Whether this tile is walkable
  bool get isWalkable {
    switch (this) {
      case TileType.floor:
      case TileType.door:
      case TileType.treasure:
      case TileType.trap:
      case TileType.specialEvent:
        return true;
      default:
        return false;
    }
  }

  /// Whether this tile has an NFC tag
  bool get hasNFC {
    switch (this) {
      case TileType.door:
      case TileType.enemy:
      case TileType.treasure:
      case TileType.trap:
      case TileType.specialEvent:
        return true;
      default:
        return false;
    }
  }
}
