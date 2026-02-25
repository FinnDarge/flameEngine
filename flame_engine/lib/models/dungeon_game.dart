import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'game_grid.dart';
import 'game_state.dart';
import 'character.dart';
import '../components/grid_component.dart';
import '../components/character_sprite_component.dart';

/// Main Flame game class
class DungeonGame extends FlameGame {
  late GameState gameState;
  GridComponent? gridComponent;
  
  // Track character sprite components
  final Map<Character, CharacterSpriteComponent> characterSprites = {};
  late final double cellSize;

  // Track last tapped NFC tag for movement flow
  String? lastTappedCharacterNfc;

  DungeonGame({int rows = 4, int columns = 4}) {
    // Calculate cell size to make grid fill consistent space regardless of dimensions
    // Target grid size of 400px, so cellSize = 400 / gridDimension
    cellSize = 400.0 / rows.toDouble();
    
    final grid = GameGrid(rows: rows, columns: columns);
    grid.initializeStaticGrid(); // Static grid - backend drives logic

    gameState = GameState(grid: grid);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload tile images to catch any loading errors early
    try {
      await Flame.images.load('tiles/Stone2.jpg');
      await Flame.images.load('tiles/StoneCorner1.jpg');
      await Flame.images.load('tiles/StoneCorner2.jpg');
    } catch (e) {
      print('⚠ Error preloading tile images: $e');
    }

    // Create visual grid component
    gridComponent = GridComponent(
      grid: gameState.grid,
      cellSize: cellSize,
    );

    await add(gridComponent!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Center the grid when screen size changes
    if (gridComponent != null) {
      gridComponent!.centerOnScreen(size);
    }
  }

  /// Handle NFC tag detection
  void handleNFCTag(String tagId, Map<String, dynamic>? data) {
    print('📱 NFC Tag: $tagId');

    // Phase 1: Character Selection
    if (gameState.phase == GamePhase.characterSelection) {
      _handleCharacterSelection(tagId);
      return;
    }

    // Phase 2: Playing - Movement
    if (gameState.phase == GamePhase.playing) {
      _handleMovement(tagId);
      return;
    }
  }

  /// Handle character selection phase
  void _handleCharacterSelection(String tagId) {
    final success = gameState.claimCharacter(tagId);
    if (success) {
      print('✓ You claimed: ${gameState.localPlayer.character!.name}');
      print('  Tap "Start Game" when all players are ready!');
      // Add character sprite for the selected character
      _addCharacterSprite(gameState.localPlayer.character!);
    }
  }

  /// Handle movement during gameplay
  void _handleMovement(String tagId) {
    // Check if it's a character NFC tag
    final isCharacterTag = CharacterClass.values.any(
      (c) => c.nfcTagId == tagId,
    );

    if (isCharacterTag) {
      // Step 1: Player taps their character figure
      _handleCharacterTap(tagId);
    } else {
      // Step 2: Player taps destination cell
      _handleCellTap(tagId);
    }
  }

  /// Handle tapping a character figure
  void _handleCharacterTap(String characterNfc) {
    // Verify it's the local player's character
    if (gameState.localPlayer.character?.nfcTagId != characterNfc) {
      print('⚠ That\'s not your character!');
      return;
    }

    // Verify it's their turn
    if (!gameState.isLocalPlayerTurn) {
      print(
        '⚠ Not your turn! Current turn: ${gameState.currentTurnCharacter?.name}',
      );
      return;
    }

    // Remember this tap
    lastTappedCharacterNfc = characterNfc;
    print('✓ Character selected. Now tap destination cell...');
  }

  /// Handle tapping a grid cell
  void _handleCellTap(String cellNfc) {
    // Must have tapped character first
    if (lastTappedCharacterNfc == null) {
      print('⚠ Tap your character figure first!');
      return;
    }

    // Parse cell NFC tag (format: cell_X_Y where X,Y are 1-indexed)
    final parts = cellNfc.split('_');
    if (parts.length != 3 || parts[0] != 'cell') {
      print('⚠ Invalid cell NFC tag: $cellNfc');
      lastTappedCharacterNfc = null;
      return;
    }

    try {
      final row = int.parse(parts[1]) - 1; // Convert to 0-indexed
      final col = int.parse(parts[2]) - 1;
      final destination = Vector2(col.toDouble(), row.toDouble());

      // Attempt move
      final character = gameState.localPlayer.character;
      if (character == null) {
        print('⚠ No character selected for this player!');
        lastTappedCharacterNfc = null;
        return;
      }
      final moved = gameState.moveCharacter(character, destination);

      if (moved) {
        // Update visual
        gridComponent?.updateAllTiles();
        
        // Update character sprite position
        _updateCharacterSpritePosition(character);

        // End turn
        gameState.nextTurn();

        // Check victory
        if (gameState.checkVictory()) {
          print('🎉 VICTORY! All players reached the goal!');
          gameState.phase = GamePhase.victory;
        }
      }
    } catch (e) {
      print('⚠ Error parsing cell position: $e');
    }

    // Reset for next move
    lastTappedCharacterNfc = null;
  }

  /// Reset the game to initial state
  void resetGame() {
    gameState.grid.initializeStaticGrid();
    gridComponent?.updateAllTiles();

    // Remove all character sprites
    for (final sprite in characterSprites.values) {
      remove(sprite);
    }
    characterSprites.clear();

    // Reset game state
    gameState.characters.clear();
    gameState.localPlayer.releaseCharacter();
    gameState.phase = GamePhase.characterSelection;
    gameState.currentTurnIndex = 0;
    gameState.turnNumber = 1;
    lastTappedCharacterNfc = null;
  }

  /// Start the game after character selection
  Future<void> startGameplay() async {
    gameState.startGame();
    gridComponent?.updateAllTiles();
    
    // Wait for the game to fully load (onLoad complete)
    await loaded;
    
    // Ensure character sprites exist for all players
    await ensureCharacterSprites();
    
    // Update all character sprite positions to match their grid positions
    for (final entry in characterSprites.entries) {
      entry.value.updatePosition();
    }
  }
  
  /// Ensure character sprites exist for all characters that have been claimed
  Future<void> ensureCharacterSprites() async {
    // Add sprite for local player's character if it exists and doesn't have a sprite
    final localCharacter = gameState.localPlayer.character;
    if (localCharacter != null && !characterSprites.containsKey(localCharacter)) {
      await _addCharacterSprite(localCharacter);
    }
    
    // TODO: Add sprites for other players' characters when multiplayer is implemented
  }
  
  /// Add a character sprite component to the game
  Future<void> _addCharacterSprite(Character character) async {
    // Don't add if already exists
    if (characterSprites.containsKey(character)) return;
    
    // Wait for grid component to be fully loaded
    if (gridComponent == null) return;
    
    // Wait for grid to finish loading (tile images, etc.)
    await gridComponent!.loaded;
    
    final sprite = CharacterSpriteComponent(
      character: character,
      cellSize: cellSize,
    );
    
    // Add sprite as a child of the grid component so it moves with the grid
    await gridComponent!.add(sprite);
    characterSprites[character] = sprite;
  }
  
  /// Update a character sprite's position
  void _updateCharacterSpritePosition(Character character) {
    final sprite = characterSprites[character];
    if (sprite != null) {
      sprite.updatePosition();
    }
  }
}
