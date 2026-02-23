# Spritesheet Configuration Guide

Your spritesheet is now integrated! The file is loaded from:
**`assets/images/tiles/spritesheet/roguelikeDungeon_transparent.png`**

## Current Configuration

The spritesheet loader is configured in: [lib/utils/spritesheet_loader.dart](lib/utils/spritesheet_loader.dart)

### Default Settings

- **Tile Size**: 16x16 pixels (adjust if your tiles are different)
- **Tile Positions**: Currently using placeholder positions

## How to Configure Your Spritesheet

### Step 1: Determine Your Tile Size

Look at your spritesheet and determine the size of each individual tile:
- Common sizes: 16x16, 32x32, 48x48, 64x64 pixels

Edit line 9 in `lib/utils/spritesheet_loader.dart`:
```dart
static const double tileSize = 16.0;  // Change this to your tile size
```

### Step 2: Map Tile Positions

Your spritesheet is organized in a grid. Each tile has a position defined by (row, column).

**Grid coordinates start at (0, 0) in the top-left corner:**
```
     Col 0    Col 1    Col 2    Col 3
Row 0 [Tile]  [Tile]  [Tile]  [Tile]
Row 1 [Tile]  [Tile]  [Tile]  [Tile]
Row 2 [Tile]  [Tile]  [Tile]  [Tile]
```

### Step 3: Update Tile Mapping

Edit the `tileMapping` in `lib/utils/spritesheet_loader.dart` (around line 14):

```dart
static const Map<TileType, TilePosition> tileMapping = {
  TileType.floor: TilePosition(row: 0, col: 0),      // Your floor tile position
  TileType.wall: TilePosition(row: 0, col: 1),       // Your wall tile position
  TileType.door: TilePosition(row: 1, col: 0),       // Your door tile position
  TileType.enemy: TilePosition(row: 2, col: 0),      // Your enemy tile position
  TileType.treasure: TilePosition(row: 3, col: 0),   // Your treasure tile position
  TileType.trap: TilePosition(row: 4, col: 0),       // Your trap tile position
  TileType.specialEvent: TilePosition(row: 5, col: 0), // Your special tile position
  TileType.player: TilePosition(row: 6, col: 0),     // Your player tile position (optional)
  TileType.empty: TilePosition(row: 7, col: 0),      // Your empty/black tile position
};
```

## Example: Standard Roguelike Dungeon Tileset

If your spritesheet follows a common roguelike pattern:

```
Row 0: [Floor] [Wall Stone] [Wall Brick] [Wall Wood]
Row 1: [Door Closed] [Door Open] [Stairs Down] [Stairs Up]
Row 2: [Chest Closed] [Chest Open] [Barrel] [Crate]
Row 3: [Enemy Goblin] [Enemy Orc] [Enemy Skeleton] [Enemy Rat]
Row 4: [Trap Spike] [Trap Arrow] [Trap Fire] [Water]
```

Configuration would be:
```dart
TileType.floor: TilePosition(row: 0, col: 0),
TileType.wall: TilePosition(row: 0, col: 1),
TileType.door: TilePosition(row: 1, col: 0),
TileType.treasure: TilePosition(row: 2, col: 0),
TileType.enemy: TilePosition(row: 3, col: 0),
TileType.trap: TilePosition(row: 4, col: 0),
```

## Testing Your Configuration

1. **Update the tile positions** in `spritesheet_loader.dart`
2. **Save the file**
3. **Run the app**: `flutter run`
4. **Check the console** for loading messages:
   - `✓ Spritesheet loaded` = Success!
   - `✗ Failed to load` = Check file path and format

## Troubleshooting

### Sprites Not Showing
1. **Check tile size** - Make sure `tileSize` matches your actual tiles
2. **Check file path** - Verify the PNG is in the correct folder
3. **Check transparency** - The PNG should support transparency
4. **Check format** - Must be a PNG file

### Wrong Tiles Appearing
1. **Verify row/column positions** - Count carefully from (0,0)
2. **Check sprite alignment** - Ensure tiles are grid-aligned in the image

### Sprites Look Stretched/Squashed
- Adjust the `tileSize` value
- Ensure your spritesheet has uniform tile sizes

## Fallback Behavior

If the spritesheet fails to load or specific tiles aren't found:
- The app automatically falls back to **colored rectangles**
- This ensures the game always works, even without proper sprite configuration

## Advanced: Using Different Sizes

If you want different display sizes:
1. The `cellSize` in the grid is 100x100 pixels
2. Your spritesheet tiles will be scaled to fit this size
3. Small tiles (16x16) will be scaled up
4. Large tiles (64x64) will be scaled down

---

**Need Help?** Check your browser's developer console or terminal output for detailed load messages!
