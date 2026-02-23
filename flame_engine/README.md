# Hybrid NFC Board Game - Dungeon Crawler

A cooperative roguelite dungeon crawler that combines a physical board game with NFC tags and a Flutter/Flame digital companion app.

## Project Structure

### Models (`lib/models/`)
- **tile_type.dart** - Enum defining different tile types (floor, wall, enemy, treasure, etc.)
- **grid_tile.dart** - Data model for individual grid tiles
- **game_grid.dart** - Grid management and game board logic

### Components (`lib/components/`)
- **tile_component.dart** - Visual Flame component for rendering tiles
- **grid_component.dart** - Container component that manages the entire grid display

### Services (`lib/services/`)
- **nfc_service.dart** - NFC tag reading and writing functionality

### Assets (`assets/images/`)
```
assets/
  images/
    tiles/          # Tile sprites (floor, wall, door, treasure, trap, etc.)
    characters/     # Player character sprites
    enemies/        # Enemy sprites
```

## Current Features ✅

### Completed
- ✅ Basic 3x3 grid system
- ✅ NFC integration (reading and writing)
- ✅ Tile type system with multiple types
- ✅ Visual grid rendering with colors
- ✅ Test dungeon layout
- ✅ NFC tag-to-tile mapping
- ✅ Basic UI with status display
- ✅ Reset functionality

### Grid Layout (Test Dungeon)
```
[Wall]    [Enemy*]  [Wall]
[Floor]   [Player]  [Door*]
[Wall]    [Treasure*] [Wall]

* = Has NFC tag
```

## NFC Tag Programming

### Tag IDs for Test Dungeon
Your physical tiles should be programmed with these NFC tag IDs:

| Tile Type | Position | NFC Tag ID | Purpose |
|-----------|----------|------------|---------|
| Enemy | (0,1) | `enemy_001` | Triggers combat encounter |
| Door | (1,2) | `door_001` | Exit/entrance to next room |
| Treasure | (2,1) | `treasure_001` | Loot/reward |

### Programming Your NFC Tags

1. **Using the App**: The NFC service includes a `writeToTag()` method
2. **Using NFC Tools App**: Available on Android/iOS app stores
3. **Content**: Write plain text with the tag ID (e.g., "enemy_001")

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Platform Configuration

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NFCReaderUsageDescription</key>
<string>This app needs NFC to read game tiles</string>
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
```

### 3. Add Your Assets
Place your sprite images in:
- `assets/images/tiles/` - floor.png, wall.png, door.png, etc.
- `assets/images/characters/` - player.png
- `assets/images/enemies/` - enemy.png

Uncomment the sprite loading code in `tile_component.dart` (line 40) when ready.

### 4. Run the App
```bash
flutter run
```

## How to Play

1. **Launch the app** on your NFC-enabled device
2. **Check NFC status** - Green icon means ready
3. **Tap physical tiles** with your phone to scan NFC tags
4. **The app reveals** the tile type and handles game logic
5. **Use Reset button** to restart the dungeon

## Next Steps 🚀

### Immediate Tasks
- [ ] Add your custom sprite assets
- [ ] Program physical NFC tiles
- [ ] Test NFC scanning with real tiles
- [ ] Design player character system

### Future Enhancements
- [ ] Player movement tracking
- [ ] Combat system
- [ ] Health/inventory management
- [ ] Multiple dungeon rooms
- [ ] Enemy AI and encounters
- [ ] Loot and item system
- [ ] Save/load game state
- [ ] Sound effects and music
- [ ] Animations for combat/movement
- [ ] Multiplayer support

## Technical Details

### Grid System
- **Size**: 3x3 (each cell 10cm x 10cm physical)
- **Coordinate System**: (row, col) starting from (0,0) top-left
- **Cell Size**: 100 pixels per cell in app

### NFC Tags
- **Only special tiles** have NFC tags (not every cell)
- **Tag Format**: Plain text NDEF records
- **Tag IDs**: Format: `{type}_{number}` (e.g., "enemy_001")

### Tile Types
- **Floor**: Basic walkable tile
- **Wall**: Obstacle (not walkable)
- **Door**: Room entrance/exit
- **Enemy**: Combat encounter (NFC)
- **Treasure**: Loot/rewards (NFC)
- **Trap**: Hazard (NFC)
- **Special Event**: Custom events (NFC)
- **Empty**: Unrevealed/void space

## Troubleshooting

### NFC Not Working
1. Check device supports NFC (Settings > Connected Devices > NFC)
2. Ensure NFC is enabled
3. Verify permissions in AndroidManifest.xml / Info.plist
4. Hold phone close to tag (< 5cm)

### Tiles Not Appearing
1. Check console logs for errors
2. Verify `initializeTestDungeon()` is called
3. Ensure grid is centered on screen

### Assets Not Loading
1. Verify files exist in `assets/images/`
2. Check file names match `tile_type.dart` paths
3. Run `flutter pub get` after adding assets
4. Uncomment sprite loading in `tile_component.dart`

## Development

### Running Tests
```bash
flutter test
```

### Building for Release
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Project Architecture

```
Physical Board (NFC Tags)
        ↓
    NFC Reader
        ↓
   NFCService → DungeonGame → GameGrid
                     ↓
              GridComponent
                     ↓
              TileComponents
                     ↓
              Screen Rendering
```

## Built With
- Flutter
- Flame Engine
- nfc_manager plugin

