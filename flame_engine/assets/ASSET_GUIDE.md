# Asset Requirements

This file lists the image assets you should add to complete the visual design.

## Required Assets

### Tiles (assets/images/tiles/)

| Filename | Size | Description | Usage |
|----------|------|-------------|-------|
| floor.png | 100x100px | Stone/wood floor texture | Walkable ground tiles |
| wall.png | 100x100px | Stone wall texture | Obstacles |
| door.png | 100x100px | Wooden door | Room entrance/exit |
| treasure.png | 100x100px | Treasure chest | Loot containers |
| trap.png | 100x100px | Spike trap or similar | Hazard tiles |
| special.png | 100x100px | Magical rune/portal | Special event tiles |

### Characters (assets/images/characters/)

| Filename | Size | Description | Usage |
|----------|------|-------------|-------|
| player.png | 80x80px | Player character/marker | Player position indicator |

### Enemies (assets/images/enemies/)

| Filename | Size | Description | Usage |
|----------|------|-------------|-------|
| enemy.png | 80x80px | Generic enemy | Enemy encounter tiles |

## Optional Assets (For Future Development)

### Characters
- player_warrior.png
- player_mage.png
- player_rogue.png
- player_cleric.png

### Enemies
- enemy_goblin.png
- enemy_skeleton.png
- enemy_dragon.png
- enemy_boss.png

### UI Elements
- heart.png (health indicator)
- coin.png (currency)
- shield.png (armor)
- sword.png (attack)

### Items
- potion_health.png
- potion_mana.png
- sword_basic.png
- shield_basic.png

## Asset Guidelines

### Size & Resolution
- **Base size**: 100x100 pixels for tiles
- **Character markers**: 80x80 pixels
- **High DPI**: Provide @2x and @3x versions for better quality
  - Example: floor.png, floor@2x.png, floor@3x.png

### File Format
- **PNG with transparency** (recommended)
- 32-bit color depth
- Transparency for character sprites

### Style Guidelines
- **Consistent art style** across all assets
- **Clear silhouettes** for easy recognition
- **High contrast** for visibility
- **Avoid fine details** that don't scale well

### Color Palette Suggestions
- Floor: Gray/brown tones (#8B7355, #A0826D)
- Walls: Dark gray (#333333, #4A4A4A)
- Enemies: Red tints (#8B0000, #DC143C)
- Treasures: Gold (#FFD700, #FFA500)
- Player: Bright colors (#00FF00, #0080FF)

## Asset Sources

### Free Resources
- **OpenGameArt.org** - CC0 and open source game art
- **Kenney.nl** - Free game assets
- **itch.io** - Free and paid game assets
- **Pixabay** - Free images (check license)

### Creating Your Own
- **Pixel art tools**: Aseprite, Piskel, Pixelorama
- **Vector tools**: Inkscape, Figma
- **Photo editing**: GIMP, Photoshop

### Commission Custom Art
- **Fiverr** - Freelance artists
- **Upwork** - Professional designers
- **ArtStation** - Portfolio-based hiring

## Directory Structure

```
assets/
  images/
    tiles/
      floor.png
      wall.png
      door.png
      treasure.png
      trap.png
      special.png
    characters/
      player.png
      player_warrior.png  (optional)
      player_mage.png     (optional)
      player_rogue.png    (optional)
    enemies/
      enemy.png
      enemy_goblin.png    (optional)
      enemy_skeleton.png  (optional)
      enemy_boss.png      (optional)
    ui/                   (optional)
      heart.png
      coin.png
      shield.png
      sword.png
    items/                (optional)
      potion_health.png
      potion_mana.png
```

## How to Add Assets

1. **Save images** into the correct folders
2. **Verify filenames** match exactly (case-sensitive)
3. **Run** `flutter pub get` after adding new assets
4. **Uncomment sprite loading** in `lib/components/tile_component.dart` (line 40-51)
5. **Test** in the app

## Current Status

The app currently uses **colored rectangles** as placeholders:
- Green = Player
- Light Gray = Floor
- Dark Gray = Wall
- Red = Enemy
- Gold = Treasure
- Brown = Door
- Purple = Special Event

Once you add the PNG files, these will be replaced with actual sprites!

## Image Optimization

Before adding to the project:
1. **Compress images** - Use TinyPNG or similar
2. **Remove metadata** - Reduces file size
3. **Convert to PNG-8** if possible (for smaller files)
4. Keep total assets **under 10MB** for better app performance

---

**Note**: The game will work without custom assets using the colored placeholder system. Add assets when you're ready to enhance the visual experience!
