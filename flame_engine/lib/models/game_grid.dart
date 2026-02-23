import 'package:flame/components.dart';
import 'grid_tile.dart';
import 'tile_type.dart';

/// Represents the game board grid
class GameGrid {
  /// Number of rows
  final int rows;
  
  /// Number of columns
  final int columns;
  
  /// Physical size of each cell in cm
  final double cellSizeCm;
  
  /// All tiles in the grid
  final List<List<GridTile>> tiles;

  GameGrid({
    required this.rows,
    required this.columns,
    this.cellSizeCm = 10.0,
  }) : tiles = List.generate(
          rows,
          (row) => List.generate(
            columns,
            (col) => GridTile(
              gridPosition: Vector2(col.toDouble(), row.toDouble()),
              type: TileType.empty,
            ),
          ),
        );

  /// Gets a tile at the specified grid position
  GridTile? getTile(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) {
      return null;
    }
    return tiles[row][col];
  }

  /// Sets a tile type at the specified position
  void setTileType(int row, int col, TileType type, {String? nfcTagId}) {
    final tile = getTile(row, col);
    if (tile != null) {
      tile.type = type;
      if (nfcTagId != null) {
        tile.nfcTagId = nfcTagId;
      }
    }
  }

  /// Finds a tile by NFC tag ID
  GridTile? findTileByNFC(String nfcTagId) {
    for (var row in tiles) {
      for (var tile in row) {
        if (tile.nfcTagId == nfcTagId) {
          return tile;
        }
      }
    }
    return null;
  }

  /// Gets all tiles of a specific type
  List<GridTile> getTilesByType(TileType type) {
    final result = <GridTile>[];
    for (var row in tiles) {
      for (var tile in row) {
        if (tile.type == type) {
          result.add(tile);
        }
      }
    }
    return result;
  }

  /// Checks if a position is valid and walkable
  bool isWalkable(int row, int col) {
    final tile = getTile(row, col);
    return tile != null && tile.type.isWalkable;
  }

  /// Initializes a basic 3x3 dungeon layout for testing
  /// Creates simple rooms with different properties
  void initializeTestDungeon() {
    // Set all rooms to floor first (basic walkable rooms)
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        setTileType(row, col, TileType.floor);
        tiles[row][col].isRevealed = true; // All visible for now
      }
    }

    // Corner rooms are walls (obstacles)
    setTileType(0, 0, TileType.wall);
    setTileType(0, 2, TileType.wall);
    setTileType(2, 0, TileType.wall);
    setTileType(2, 2, TileType.wall);

    // Add special rooms with NFC tags
    setTileType(1, 2, TileType.door, nfcTagId: 'door_001');      // Right: Door room
    setTileType(0, 1, TileType.enemy, nfcTagId: 'enemy_001');    // Top: Enemy room
    setTileType(2, 1, TileType.treasure, nfcTagId: 'treasure_001'); // Bottom: Treasure room

    // Center room is where player starts
    setTileType(1, 1, TileType.player);
    tiles[1][1].hasPlayer = true;
    
    print('✓ Test dungeon initialized: 3x3 grid with 9 rooms');
    print('  - 4 corner rooms: Walls');
    print('  - Center room: Player start');
    print('  - 3 special rooms with NFC: Enemy, Door, Treasure');
    print('  - 1 empty floor room on left');
  }

  @override
  String toString() {
    return 'GameGrid(${rows}x$columns, cellSize: ${cellSizeCm}cm)';
  }
}
