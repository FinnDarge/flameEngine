# NFC Tag Setup Guide

This guide will help you program your physical NFC tags for use with the Dungeon Crawler board game.

## What You'll Need

1. **NFC Tags** (NTAG213, NTAG215, or NTAG216 recommended)
   - At least 3 tags for the test dungeon
   - More for additional tiles and expansions
   
2. **NFC-Enabled Smartphone** (Android or iOS)

3. **NFC Writing App** (one of):
   - NFC Tools (Android/iOS) - Recommended
   - NFC TagWriter (Android/iOS)
   - This app's built-in writer (coming soon)

## Tag IDs for Test Dungeon

Program your tags with these exact text values:

| Physical Tile | Tag ID | Location | Game Effect |
|--------------|---------|----------|-------------|
| Enemy Tile | `enemy_001` | Grid (0,1) | Triggers combat encounter |
| Door Tile | `door_001` | Grid (1,2) | Exit to next room |
| Treasure Tile | `treasure_001` | Grid (2,1) | Opens loot screen |

## Programming Steps

### Using NFC Tools App

1. **Download NFC Tools**
   - Android: Google Play Store
   - iOS: App Store

2. **Open the app** and go to "Write" tab

3. **Add a record**:
   - Select "Add a record"
   - Choose "Text"
   - Enter the Tag ID (e.g., `enemy_001`)
   - Language: English (or leave default)

4. **Write to tag**:
   - Tap "Write"
   - Hold your phone near the NFC tag
   - Wait for confirmation

5. **Verify**:
   - Go to "Read" tab
   - Scan the tag
   - Verify the text matches

### Using This App (In Development)

Future feature: The app will include an NFC tag programming mode.

```dart
// Example usage (for developers):
final nfcService = NFCService();
await nfcService.writeToTag('enemy_001');
```

## Tag Placement on Physical Board

```
┌─────────────────────────────────┐
│  Wall   │  Enemy*  │   Wall     │
│         │ (0,1)    │            │
├─────────┼──────────┼────────────┤
│  Floor  │  Player  │   Door*    │
│         │ (1,1)    │   (1,2)    │
├─────────┼──────────┼────────────┤
│  Wall   │Treasure* │   Wall     │
│         │ (2,1)    │            │
└─────────────────────────────────┘

* = Place NFC tag here
```

## Physical Tag Recommendations

### Sticker Tags
- **Pros**: Easy to attach to tiles, inexpensive
- **Cons**: Can peel off over time
- **Best for**: Prototyping, temporary setups

### Embedded Tags
- **Pros**: More durable, professional
- **Cons**: Requires custom tile manufacturing
- **Best for**: Final production

### Card Tags
- **Pros**: Durable, reusable
- **Cons**: Need to design tile holders
- **Best for**: Semi-permanent setups

## Tag Format & Structure

### Basic Text Format (Recommended)
```
Tag ID: enemy_001
Type: Plain Text (NDEF)
Encoding: UTF-8
```

### Advanced JSON Format (Future)
```json
{
  "id": "enemy_001",
  "type": "enemy",
  "level": 1,
  "health": 10,
  "attack": 5
}
```

## Expanding Your Collection

### Naming Convention
Use a consistent format: `{type}_{number}`

Examples:
- Enemies: `enemy_001`, `enemy_002`, `enemy_003`
- Treasures: `treasure_001`, `treasure_002`
- Doors: `door_001`, `door_002`
- Traps: `trap_001`, `trap_002`
- Special: `special_boss_001`, `special_shrine_001`

### Creating New Tile Types

1. **Add to the code** (lib/models/tile_type.dart)
2. **Program NFC tags** with new IDs
3. **Update game logic** to handle new types
4. **Create physical tiles** with the tags

## Testing Your Tags

1. **Launch the app**
2. **Check NFC icon** turns green
3. **Tap NFC Status** to verify system ready
4. **Scan each tag** and verify:
   - Tag is detected
   - Correct position is revealed
   - Tile type matches expectation

## Troubleshooting

### Tag Not Detected
- **Check distance**: Hold phone within 2-5cm of tag
- **Try different position**: NFC antenna varies by phone
- **Check tag format**: Ensure it's NDEF formatted
- **Verify tag works**: Test with NFC Tools app first

### Wrong Tile Revealed
- **Check Tag ID**: Scan with NFC Tools to verify
- **Reprogram if needed**: Overwrite with correct ID
- **Check app code**: Verify tag mapping in `initializeTestDungeon()`

### Tag Reads Slowly
- **Use quality tags**: NTAG213/215/216 recommended
- **Check phone compatibility**: Some phones have better NFC
- **Reduce interference**: Remove phone case if metal
- **Clean surface**: Dirt can interfere with reading

## Security & Anti-Cheating

### For Competitive Play
- **Lock tags** after programming (permanent)
- **Use encrypted data** (advanced)
- **Physical sealing** to prevent tag replacement

### For Casual Play
- Tags can remain writable for easy editing
- Trust-based system

## Bulk Programming

For large sets of tiles:

1. **Create a spreadsheet** of Tag ID mappings
2. **Use automation** (advanced):
   - NFC Task Launcher (Android)
   - Custom scripts with phone NFC API
3. **Label tags immediately** after programming
4. **Test in batches** to ensure quality

## Future Features

- [ ] In-app tag programming interface
- [ ] Tag verification mode
- [ ] Batch tag management
- [ ] Tag encryption for competitive play
- [ ] Cloud sync for custom tag libraries

## Resources

- [NFC Forum](https://nfc-forum.org/) - Technical specifications
- [NFC Tools App](https://www.wakdev.com/en/apps/nfc-tools.html) - Free tag reader/writer
- [TagInfo App](https://play.google.com/store/apps/details?id=at.mroland.android.apps.nfc.taginfo) - Advanced tag analysis

## Tips for Physical Board Design

1. **Mark tag locations** clearly on tiles
2. **Use consistent orientation** for easier scanning
3. **Consider tile thickness** - thinner allows better reading
4. **Avoid metal** near tags (interferes with NFC)
5. **Weatherproof tags** with clear coating if needed
6. **Test before sealing** - always verify tags work first

---

**Happy dungeon crawling! 🗡️🎲**
