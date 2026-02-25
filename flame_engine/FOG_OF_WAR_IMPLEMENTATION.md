# Fog of War & Events Implementation

## ✅ Completed Features

### 1. Enemy System
**Models**: `lib/models/enemy.dart`
- **4 Enemy Types**:
  - **Behemoth**: Tank (100 HP, 15 ATK, 8 DEF) - Red
  - **Planetary Avatar**: Boss (150 HP, 20 ATK, 12 DEF) - Purple
  - **Sporeling**: Swarm (30 HP, 8 ATK, 3 DEF) - Green
  - **Synapse**: Controller (50 HP, 12 ATK, 5 DEF) - Cyan

**Component**: `lib/components/enemy_sprite_component.dart`
- Visual representation with health/name display
- Same styling as character sprites
- Priority 9 (renders below characters)

**Images**: `assets/images/enemies/`
- BehemothSingle.png
- PlanetaryAvatarSingle.png
- SporelingSingle.png
- SynapseSingle.png

### 2. Fog of War
**Updated**: `lib/models/grid_tile.dart`
- Added `isRevealed` boolean (already existed)
- Tiles start hidden by default

**Visual**: `lib/components/tile_component.dart`
- Black overlay (85% opacity) on unrevealed tiles
- Overlay removed when tile revealed
- `updateTile()` method handles dynamic reveal

### 3. Field Events
**Models**: `lib/models/tile_event.dart`
- **6 Event Types**:
  - **Trap**: Red danger icon
  - **Loot**: Gold diamond icon
  - **Encounter**: Orange group icon
  - **Objective**: Green flag icon
  - **Portal**: Purple portal icon
  - **Hazard**: Orange warning icon

**Visual**: `lib/components/tile_component.dart`
- Colored circle indicator in top-right corner
- Only visible on revealed, uncompleted events
- Auto-updates when event state changes

**Updated**: `lib/models/grid_tile.dart`
- Added `Enemy? enemy` field
- Added `TileEvent? event` field
- Updated `copyWith()` method

---

## 🔌 Backend Integration Guide

### Expected JSON Structure

#### Enemy Data
```json
{
  "id": "enemy_123",
  "type": "behemoth",
  "health": 80,
  "maxHealth": 100,
  "attack": 15,
  "defense": 8
}
```

#### Tile Event Data
```json
{
  "id": "event_456",
  "type": "trap",
  "description": "Pressure plate trap - take 10 damage!",
  "isRevealed": true,
  "isCompleted": false
}
```

#### Grid State from Backend
The backend should return grid state including:
```json
{
  "tiles": [
    {
      "row": 0,
      "col": 0,
      "isRevealed": true,
      "enemy": { /* enemy data */ },
      "event": { /* event data */ }
    }
  ]
}
```

---

## 🎮 Usage Examples

### Revealing Tiles (Frontend receives from backend)
```dart
// When backend reveals a tile
final tile = gameState.grid.getTile(row, col);
if (tile != null && !tile.isRevealed) {
  tile.isRevealed = true;
  gridComponent?.updateTile(row, col); // Updates visual
}
```

### Adding Enemies (Backend spawns)
```dart
// Backend response includes enemy
final enemyData = {
  'id': 'enemy_1',
  'type': 'sporeling',
  'health': 30,
};

final enemy = Enemy.fromJson(enemyData);
final tile = gameState.grid.getTile(row, col);
tile?.enemy = enemy;

// Spawn sprite (to be added to DungeonGame)
// game.addEnemySprite(enemy, Vector2(row, col));
```

### Adding Events (Backend places)
```dart
// Backend response includes event
final eventData = {
  'id': 'evt_1',
  'type': 'loot',
  'description': 'You found a supply cache!',
  'isRevealed': true,
  'isCompleted': false,
};

final event = TileEvent.fromJson(eventData);
final tile = gameState.grid.getTile(row, col);
tile?.event = event;
gridComponent?.updateTile(row, col); // Shows indicator
```

---

## 🚧 TODO: Backend-Driven Gameplay

### Required Backend Endpoints

1. **Initialize Game Session**
   - `POST /api/game/start`
   - Returns initial grid state with fog of war

2. **Submit Player Move**
   - `POST /api/game/move`
   - Backend validates move
   - Returns updated game state (revealed tiles, spawned enemies, triggered events)

3. **Get Current Game State**
   - `GET /api/game/state/{sessionId}`
   - Returns all visible tiles, enemies, events, character positions

4. **Trigger Event**
   - `POST /api/game/event/{eventId}`
   - Backend resolves event (loot, trap, etc.)
   - Returns updated player/enemy state

### Frontend Responsibilities
- ✅ Display fog of war
- ✅ Render enemies with health
- ✅ Show event indicators
- ✅ Animate character movement
- ✅ Show inventory/stats
- ⏳ Handle backend responses to update visuals
- ⏳ Send NFC scans to backend for validation

### Backend Responsibilities
- ⏳ Track fog of war state per player
- ⏳ Spawn enemies based on difficulty
- ⏳ Generate/trigger field events
- ⏳ Validate all moves
- ⏳ Manage combat resolution
- ⏳ Handle multiplayer synchronization

---

## 📝 Next Steps

1. **Test the Visual Features**:
   - Hot restart app
   - Tiles should show fog overlay (dark)
   - Modify `GameGrid.initializeStaticGrid()` to test:
     ```dart
     tiles[0][0].isRevealed = true; // Reveal starting tile
     tiles[1][1].event = TileEvent(
       id: 'test_event',
       type: TileEventType.loot,
       description: 'Test loot',
       isRevealed: true,
     );
     ```

2. **Connect to Backend API**:
   - Update `ManagementApiService` with game session endpoints
   - Map backend responses to Enemy/TileEvent models
   - Update DungeonGame to sync with backend state

3. **Add Enemy Sprite Management**:
   - Create `addEnemySprite()` method in DungeonGame
   - Similar to character sprite system
   - Update when backend reports enemy defeated

4. **Implement Combat UI**:
   - Show popup when entering enemy tile
   - Display combat results from backend
   - Animate damage/death

