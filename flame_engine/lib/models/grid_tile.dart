import 'package:flame/components.dart';
import 'tile_type.dart';

/// Represents a single room (cell) in the game grid
/// Each room is 10cm x 10cm on the physical board
class GridTile {
  /// Grid position (row, column)
  final Vector2 gridPosition;
  
  /// Type of room/tile
  TileType type;
  
  /// NFC tag ID associated with this room (if any)
  String? nfcTagId;
  
  /// Whether this room has been revealed/discovered
  bool isRevealed;
  
  /// Whether this room is currently occupied by a player
  bool hasPlayer;
  
  /// Additional metadata for special rooms
  Map<String, dynamic>? metadata;

  GridTile({
    required this.gridPosition,
    this.type = TileType.empty,
    this.nfcTagId,
    this.isRevealed = false,
    this.hasPlayer = false,
    this.metadata,
  });

  /// Creates a copy of this tile with optional modifications
  GridTile copyWith({
    Vector2? gridPosition,
    TileType? type,
    String? nfcTagId,
    bool? isRevealed,
    bool? hasPlayer,
    Map<String, dynamic>? metadata,
  }) {
    return GridTile(
      gridPosition: gridPosition ?? this.gridPosition,
      type: type ?? this.type,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      isRevealed: isRevealed ?? this.isRevealed,
      hasPlayer: hasPlayer ?? this.hasPlayer,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Gets the row index
  int get row => gridPosition.y.toInt();

  /// Gets the column index
  int get col => gridPosition.x.toInt();

  @override
  String toString() {
    return 'GridTile(pos: ($row, $col), type: $type, nfc: $nfcTagId, revealed: $isRevealed)';
  }
}
