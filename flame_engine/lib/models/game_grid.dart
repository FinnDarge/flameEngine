import 'dart:math';
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

  GameGrid({required this.rows, required this.columns, this.cellSizeCm = 10.0})
    : tiles = List.generate(
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

  /// Initializes a basic test dungeon layout
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
    setTileType(1, 2, TileType.door, nfcTagId: 'door_001'); // Right: Door room
    setTileType(0, 1, TileType.enemy, nfcTagId: 'enemy_001'); // Top: Enemy room
    setTileType(
      2,
      1,
      TileType.treasure,
      nfcTagId: 'treasure_001',
    ); // Bottom: Treasure room

    // Center room is where player starts
    setTileType(1, 1, TileType.player);
    tiles[1][1].hasPlayer = true;

    print('✓ Test dungeon initialized: 3x3 grid with 9 rooms');
    print('  - 4 corner rooms: Walls');
    print('  - Center room: Player start');
    print('  - 3 special rooms with NFC: Enemy, Door, Treasure');
    print('  - 1 empty floor room on left');
  }

  /// Generate a random dungeon layout
  /// NFC tags remain fixed (cell_X_Y), but content changes
  void generateRandomDungeon({int? seed}) {
    final random = seed != null ? Random(seed) : Random();

    // Clear grid - all floors initially
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        setTileType(row, col, TileType.floor);
        tiles[row][col].isRevealed = true;
        tiles[row][col].nfcTagId =
            'cell_${row + 1}_${col + 1}'; // Fixed NFC tag per cell
      }
    }

    // Starting position (1,1) = (0,0) - always walkable
    setTileType(0, 0, TileType.floor);

    // Goal position (bottom-right corner) - always walkable
    setTileType(rows - 1, columns - 1, TileType.floor);

    // Randomly place walls (but not on start or goal)
    final numWalls = 2 + random.nextInt(2); // 2-3 walls
    int wallsPlaced = 0;
    while (wallsPlaced < numWalls) {
      final row = random.nextInt(rows);
      final col = random.nextInt(columns);

      // Don't place on start, goal, or already a wall
      if ((row == 0 && col == 0) ||
          (row == rows - 1 && col == columns - 1) ||
          tiles[row][col].type == TileType.wall) {
        continue;
      }

      setTileType(row, col, TileType.wall);
      wallsPlaced++;
    }

    // Place doors (1-2 locked doors)
    final numDoors = 1 + random.nextInt(2);
    int doorsPlaced = 0;
    while (doorsPlaced < numDoors) {
      final row = random.nextInt(rows);
      final col = random.nextInt(columns);

      if ((row == 0 && col == 0) ||
          (row == rows - 1 && col == columns - 1) ||
          tiles[row][col].type != TileType.floor) {
        continue;
      }

      setTileType(row, col, TileType.door);
      tiles[row][col].metadata = {'locked': true, 'keyColor': 'red'};
      doorsPlaced++;
    }

    // Place keys (match number of doors)
    int keysPlaced = 0;
    while (keysPlaced < numDoors) {
      final row = random.nextInt(rows);
      final col = random.nextInt(columns);

      if ((row == 0 && col == 0) ||
          (row == rows - 1 && col == columns - 1) ||
          tiles[row][col].type != TileType.floor) {
        continue;
      }

      setTileType(row, col, TileType.treasure);
      tiles[row][col].metadata = {'contains': 'key_red'};
      keysPlaced++;
    }

    // Place enemies (0-2)
    final numEnemies = random.nextInt(3);
    int enemiesPlaced = 0;
    while (enemiesPlaced < numEnemies) {
      final row = random.nextInt(rows);
      final col = random.nextInt(columns);

      if ((row == 0 && col == 0) ||
          (row == rows - 1 && col == columns - 1) ||
          tiles[row][col].type != TileType.floor) {
        continue;
      }

      setTileType(row, col, TileType.enemy);
      tiles[row][col].metadata = {'enemyType': 'goblin', 'health': 5};
      enemiesPlaced++;
    }

    print('✓ Random dungeon generated!');
    print('  - Walls: $wallsPlaced');
    print('  - Doors: $doorsPlaced');
    print('  - Keys: $keysPlaced');
    print('  - Enemies: $enemiesPlaced');
    print('  - Start: (1,1), Goal: ($rows,$columns)');
  }

  /// Initialize a static grid with all floor tiles
  /// No randomization - just sets up a basic board for backend-driven gameplay
  void initializeStaticGrid() {
    // Set all tiles to floor and assign NFC tags
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        setTileType(row, col, TileType.floor);
        tiles[row][col].isRevealed = true;
        tiles[row][col].nfcTagId = 'cell_${row + 1}_${col + 1}'; // Fixed NFC tag per cell
      }
    }
  }

  @override
  String toString() {
    return 'GameGrid(${rows}x$columns, cellSize: ${cellSizeCm}cm)';
  }
}
