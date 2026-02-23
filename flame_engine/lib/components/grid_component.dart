import 'package:flame/components.dart';
import '../models/game_grid.dart';
import '../utils/spritesheet_loader.dart';
import 'tile_component.dart';

/// Component that renders the entire game grid
/// Each room is 10cm x 10cm on the physical board
class GridComponent extends PositionComponent {
  final GameGrid grid;
  final double cellSize;
  final SpritesheetLoader? spritesheetLoader;
  final List<List<TileComponent>> tileComponents = [];

  GridComponent({
    required this.grid,
    this.cellSize = 100.0,
    this.spritesheetLoader,
  }) : super(
          size: Vector2(
            grid.columns * cellSize,
            grid.rows * cellSize,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create visual components for each room
    for (int row = 0; row < grid.rows; row++) {
      final rowComponents = <TileComponent>[];
      for (int col = 0; col < grid.columns; col++) {
        final tile = grid.getTile(row, col)!;
        final tileComponent = TileComponent(
          tile: tile,
          cellSize: cellSize,
          position: Vector2(
            col * cellSize,
            row * cellSize,
          ),
          spritesheetLoader: spritesheetLoader,
        );

        await add(tileComponent);
        rowComponents.add(tileComponent);
      }
      tileComponents.add(rowComponents);
    }
    
    print('✓ Grid rendered: ${grid.rows}x${grid.columns} rooms (${size.x}x${size.y} pixels)');
  }

  /// Updates the visual representation of a specific tile
  void updateTile(int row, int col) {
    if (row >= 0 && row < grid.rows && col >= 0 && col < grid.columns) {
      tileComponents[row][col].updateTile();
    }
  }

  /// Updates all tiles
  void updateAllTiles() {
    for (int row = 0; row < grid.rows; row++) {
      for (int col = 0; col < grid.columns; col++) {
        tileComponents[row][col].updateTile();
      }
    }
  }

  /// Centers the grid on the screen
  void centerOnScreen(Vector2 screenSize) {
    position = (screenSize - size) / 2;
  }
}
