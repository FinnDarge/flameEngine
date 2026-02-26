import 'dart:async' show Timer;
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'game_grid.dart';
import 'game_state.dart';
import 'character.dart';
import 'tile_event.dart';
import '../components/grid_component.dart';
import '../components/character_sprite_component.dart';
import '../controllers/gameplay_orchestrator.dart';
import '../services/management_api_service.dart';
import '../services/session_api_service.dart';
import '../services/tile_input_provider.dart';

/// Main Flame game class
class DungeonGame extends FlameGame {
  late GameState gameState;
  late final GameplayOrchestrator gameplayOrchestrator;
  GridComponent? gridComponent;
  void Function(int row, int col, TileEvent event)? onPendingEventResolution;

  // Track character sprite components
  final Map<Character, CharacterSpriteComponent> characterSprites = {};

  // Track which characters are on which tiles (for sub-position assignment)
  // Key: "row,col", Value: List of characters on that tile
  final Map<String, List<Character>> _tilesOccupancy = {};

  late final double cellSize;

  // Timer for syncing remote player positions
  Timer? _remoteSyncTimer;
  DateTime? _lastVirtualTapAt;
  String? _lastVirtualTapId;

  DungeonGame({int rows = 4, int columns = 4}) {
    // Calculate cell size to make grid fill consistent space regardless of dimensions
    // Target grid size of 400px, so cellSize = 400 / gridDimension
    cellSize = 400.0 / rows.toDouble();

    final grid = GameGrid(rows: rows, columns: columns);
    grid.initializeStaticGrid(); // Static grid - backend drives logic

    // Add test event to demonstrate fog of war system
    if (rows >= 2 && columns >= 2) {
      grid.tiles[1][1].event = TileEvent(
        id: 'demo_loot',
        type: TileEventType.loot,
        description: 'Supply cache - demo event',
        isRevealed: true,
      );
    }

    gameState = GameState(grid: grid);
    gameplayOrchestrator = GameplayOrchestrator(
      gameState: gameState,
      refreshBoardAfterMovement: refreshBoardAfterMovement,
      completeEvent: completeEvent,
      promptEventResolution: _promptEventResolution,
    );
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
      onTileTapped: _handleVirtualTileTap,
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

  @override
  void onRemove() {
    // Clean up the sync timer when game is removed
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = null;
    super.onRemove();
  }


  void _handleVirtualTileTap(int row, int col) {
    final tileId = 'cell_${row + 1}_${col + 1}';
    final now = DateTime.now();
    final isDuplicateTap =
        _lastVirtualTapId == tileId &&
        _lastVirtualTapAt != null &&
        now.difference(_lastVirtualTapAt!).inMilliseconds < 250;
    if (isDuplicateTap) {
      return;
    }

    _lastVirtualTapId = tileId;
    _lastVirtualTapAt = now;
    handleNFCTag(tileId, null, source: TileInputSource.mockTap);
  }

  void _promptEventResolution(int row, int col, TileEvent event) {
    onPendingEventResolution?.call(row, col, event);
  }

  /// Handle NFC tag detection
  Future<void> handleNFCTag(
    String tagId,
    Map<String, dynamic>? data, {
    TileInputSource source = TileInputSource.nfc,
  }) async {
    print('📱 NFC Tag: $tagId');

    // Phase 1: Character Selection
    if (gameState.phase == GamePhase.characterSelection) {
      _handleCharacterSelection(tagId);
      return;
    }

    // Phase 2: Playing - Movement
    if (gameState.phase == GamePhase.playing) {
      await onFieldActivated(tagId, source);
      return;
    }
  }

  Future<void> onFieldActivated(String fieldId, TileInputSource source) {
    return gameplayOrchestrator.onFieldActivated(fieldId, source);
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

  void refreshBoardAfterMovement(Character character) {
    gridComponent?.updateAllTiles();
    _updateCharacterSpritePosition(character);
  }

  /// Load other players from the session and create character sprites for them
  Future<void> _loadSessionPlayers() async {
    if (gameState.sessionUuid == null) {
      print('ℹ No session UUID, skipping loading other players');
      return;
    }

    try {
      print('👥 Fetching other players from session: ${gameState.sessionUuid}');
      final sessionApi = SessionApiService();
      final sessionPlayers =
          await sessionApi.getSessionPlayers(gameState.sessionUuid!);

      // Store session players in game state
      gameState.sessionPlayers = List.unmodifiable(sessionPlayers);

      _ensureLocalCharacterFromSessionPlayers(sessionPlayers);

      print('✓ Loaded ${sessionPlayers.length} session player(s)');

      // For each session player that isn't the local player, create a character
      for (final sessionPlayer in sessionPlayers) {
        // Skip if this session player is the local player
        if (gameState.localApiPlayer != null &&
            sessionPlayer.player == gameState.localApiPlayer!.uuid) {
          continue;
        }

        // Find the matching character class from the role name
        CharacterClass? characterClass;

        if (gameState.gameStartPositions.isNotEmpty) {
          // Find the game piece for this role
          final gamePiece = gameState.gameStartPositions.firstWhere(
            (piece) => piece.role == sessionPlayer.role,
            orElse: () => gameState.gameStartPositions.first,
          );

          if (gamePiece.roleName != null) {
            characterClass = gameState.mapApiNameToCharacterClass(
              gamePiece.roleName!,
            );
          }
        }

        if (characterClass == null) {
          print(
            '⚠ Could not determine character class for session player: ${sessionPlayer.role}',
          );
          // Fallback: assign any available unclaimed character class
          characterClass = _assignAvailableCharacterClass();
          if (characterClass == null) {
            print('⚠ No available character classes to assign');
            continue;
          }
          print(
            '✓ Assigned fallback character class: ${characterClass.name}',
          );
        }

        // Skip if this character is already in the game (i.e., it's the local player)
        if (gameState.characters
            .any((c) => c.characterClass == characterClass)) {
          print(
              'ℹ Character ${characterClass.name} already claimed by local player');
          continue;
        }

        // Create a character for this other player
        final character = Character(
          characterClass: characterClass,
          nfcTagId: '', // Other players don't have NFC tags associated
          position: Vector2(0, 0), // Will be set by startGame()
        );

        gameState.addCharacter(character);
        print('✓ Added other player character: ${character.name}');
      }
    } catch (e) {
      print('⚠ Error loading session players: $e');
    }
  }

  void _ensureLocalCharacterFromSessionPlayers(
    List<SessionPlayer> sessionPlayers,
  ) {
    if (gameState.localPlayer.character != null ||
        gameState.localApiPlayer == null ||
        gameState.gameStartPositions.isEmpty) {
      return;
    }

    SessionPlayer? localAssignment;
    for (final sessionPlayer in sessionPlayers) {
      if (sessionPlayer.player == gameState.localApiPlayer!.uuid) {
        localAssignment = sessionPlayer;
        break;
      }
    }

    if (localAssignment == null) {
      print('ℹ No local role assignment found yet.');
      return;
    }

    ApiGamePiece? localGamePiece;
    for (final gamePiece in gameState.gameStartPositions) {
      if (gamePiece.role == localAssignment.role) {
        localGamePiece = gamePiece;
        break;
      }
    }

    final roleName = localGamePiece?.roleName;
    if (roleName == null) {
      print('⚠ Local role has no mapped roleName in game pieces.');
      return;
    }

    final characterClass = gameState.mapApiNameToCharacterClass(roleName);
    if (characterClass == null) {
      print('⚠ Could not map roleName "$roleName" to a CharacterClass.');
      return;
    }
    final character = Character(
      characterClass: characterClass,
      nfcTagId: characterClass.nfcTagId,
      position: Vector2(0, 0),
    );

    gameState.localPlayer.claimCharacter(character);
    if (!gameState.characters.contains(character)) {
      gameState.addCharacter(character);
    }

    print('✓ Assigned local character from role: ${character.name}');
  }

  /// Assign an available unclaimed character class
  CharacterClass? _assignAvailableCharacterClass() {
    final availableClasses = [
      CharacterClass.controller,
      CharacterClass.engineer,
      CharacterClass.striker,
      CharacterClass.vanguard,
    ];

    for (final characterClass in availableClasses) {
      // Check if this class is already claimed
      if (!gameState.characters
          .any((c) => c.characterClass == characterClass)) {
        return characterClass;
      }
    }

    return null;
  }

  /// Reset the game to initial state
  void resetGame() {
    gameState.grid.initializeStaticGrid();
    gridComponent?.updateAllTiles();

    // Stop remote sync timer
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = null;

    // Remove all character sprites from whichever parent currently owns them.
    // Character sprites are mounted under GridComponent, so removing from
    // DungeonGame directly can assert in Flame.
    for (final sprite in characterSprites.values) {
      sprite.removeFromParent();
    }
    characterSprites.clear();

    // Reset game state
    gameState.characters.clear();
    gameState.localPlayer.releaseCharacter();
    gameState.phase = GamePhase.characterSelection;
    gameState.currentTurnIndex = 0;
    gameState.turnNumber = 1;
    gameState.objectiveProgress = const TeamObjectiveProgress();
    gameState.instability = const GlobalInstability();
    gameState.endgameSummary = null;
    gameState.bossPhaseCompleted = false;
  }

  /// Start the timer to periodically sync remote player positions
  void _startRemotePlayerSync() {
    // Cancel any existing timer
    _remoteSyncTimer?.cancel();

    // Sync every 1 second to keep remote players updated
    _remoteSyncTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _syncRemotePlayerPositions();
      },
    );

    print('🔄 Started remote player position sync (1s interval)');
  }

  /// Sync remote player positions from the backend API
  Future<void> _syncRemotePlayerPositions() async {
    if (gameState.sessionId == null || gameState.playerAccessToken == null) {
      return;
    }

    try {
      final apiService = ManagementApiService();
      final boardState = await apiService.getSessionBoard(
        sessionId: gameState.sessionId!,
        accessToken: gameState.playerAccessToken!,
      );

      if (boardState == null) {
        return;
      }

      // Parse board state to extract character positions
      // The board state should contain information about all characters on the board
      // Expected format: { "board": { "pieces": [{ "role": "...", "field": { "x": ..., "y": ... } }, ...] } }

      await _updateRemoteCharactersFromBoardState(boardState);
    } catch (e) {
      // Silently fail on sync errors - don't spam logs
      // print('⚠ Error syncing remote player positions: $e');
    }
  }

  /// Update remote character positions from board state
  Future<void> _updateRemoteCharactersFromBoardState(
    Map<String, dynamic> boardState,
  ) async {
    try {
      // Extract pieces from board state - handle various possible API response formats
      List<dynamic> pieces = [];

      // Try format: { "board": { "pieces": [...] } }
      if (boardState.containsKey('board')) {
        final board = boardState['board'];
        if (board is Map && board.containsKey('pieces')) {
          pieces = board['pieces'] as List<dynamic>;
        }
      }

      // Try format: { "pieces": [...] }
      if (pieces.isEmpty && boardState.containsKey('pieces')) {
        pieces = boardState['pieces'] as List<dynamic>;
      }

      // Try format: direct array or other structure
      if (pieces.isEmpty && boardState.containsKey('characters')) {
        pieces = boardState['characters'] as List<dynamic>;
      }

      // Update each piece's position
      for (final piece in pieces) {
        if (piece is! Map<String, dynamic>) continue;

        // Extract role/character identifier
        final role = piece['role'] as String?;
        final roleName = piece['roleName'] as String?;

        if (role == null && roleName == null) continue;

        // Find matching character in game state
        final searchName = (roleName ?? role ?? '').toLowerCase();
        Character? character;
        try {
          character = gameState.characters.firstWhere(
            (c) => c.characterClass.name.toLowerCase() == searchName,
          );
        } catch (e) {
          // Character not found
          character = null;
        }

        // Skip local player's character (we update that directly through user input)
        if (character == null || character == gameState.localPlayer.character) {
          continue;
        }

        // Extract position from piece data
        // Try format: { "field": { "x": ..., "y": ... } }
        Vector2? newPosition;

        if (piece.containsKey('field')) {
          final field = piece['field'];
          if (field is Map) {
            final x = field['x'];
            final y = field['y'];
            if (x != null && y != null) {
              newPosition = Vector2(
                (x is int ? x.toDouble() : x as double),
                (y is int ? y.toDouble() : y as double),
              );
            }
          }
        }

        // Try format: { "position": { "x": ..., "y": ... } }
        if (newPosition == null && piece.containsKey('position')) {
          final pos = piece['position'];
          if (pos is Map) {
            final x = pos['x'];
            final y = pos['y'];
            if (x != null && y != null) {
              newPosition = Vector2(
                (x is int ? x.toDouble() : x as double),
                (y is int ? y.toDouble() : y as double),
              );
            }
          }
        }

        // Try format: { "x": ..., "y": ... } at root level
        if (newPosition == null) {
          final x = piece['x'];
          final y = piece['y'];
          if (x != null && y != null) {
            newPosition = Vector2(
              (x is int ? x.toDouble() : x as double),
              (y is int ? y.toDouble() : y as double),
            );
          }
        }

        // Update character position if we found it
        if (newPosition != null && newPosition != character.position) {
          print(
            '🔄 Updating ${character.name} position from ${character.position} to $newPosition',
          );
          character.position = newPosition;
          _updateCharacterSpritePosition(character);
        }
      }
    } catch (e) {
      // Silently fail - don't spam logs during regular sync
      // print('⚠ Error parsing board state: $e');
    }
  }

  /// Start the game after character selection
  Future<void> startGameplay() async {
    // Fetch starting positions from backend before starting the game
    if (gameState.selectedApiGame != null &&
        gameState.gameStartPositions.isEmpty) {
      print('📋 Fetching game piece starting positions from backend...');
      final apiService = ManagementApiService();
      final gamePieces =
          await apiService.getGamePieces(gameState.selectedApiGame!.uuid);
      gameState.gameStartPositions = List.unmodifiable(gamePieces);

      if (gamePieces.isNotEmpty) {
        print(
            '✓ Loaded ${gamePieces.length} game piece(s) with starting positions');
      } else {
        print(
            '⚠ No game pieces returned from backend (will use default positions)');
      }
    }

    // Load other players from the session
    await _loadSessionPlayers();

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

    // Start syncing remote player positions if we have a session
    if (gameState.sessionId != null && gameState.playerAccessToken != null) {
      _startRemotePlayerSync();
    }
  }

  /// Ensure character sprites exist for all characters that have been claimed
  Future<void> ensureCharacterSprites() async {
    // Add sprites for all characters in the game
    for (final character in gameState.characters) {
      if (!characterSprites.containsKey(character)) {
        await _addCharacterSprite(character);
      }
    }
  }

  /// Add a character sprite component to the game
  Future<void> _addCharacterSprite(Character character) async {
    // Don't add if already exists
    if (characterSprites.containsKey(character)) return;

    // Wait for grid component to be fully loaded
    if (gridComponent == null) return;

    // Wait for grid to finish loading (tile images, etc.)
    await gridComponent!.loaded;

    // Determine sub-position based on how many characters are already on this tile
    final subPos = _getNextAvailableSubPosition(character.position);

    final sprite = CharacterSpriteComponent(
      character: character,
      cellSize: cellSize,
      subPosition: subPos,
    );

    // Add sprite as a child of the grid component so it moves with the grid
    await gridComponent!.add(sprite);
    characterSprites[character] = sprite;

    // Track this character's position
    _addCharacterToTile(character);
  }

  /// Update a character sprite's position
  void _updateCharacterSpritePosition(Character character) {
    final sprite = characterSprites[character];
    if (sprite != null) {
      // Remove from old tile
      _removeCharacterFromTile(character);

      // Reassign sub-positions for all characters on the new tile
      _reassignSubPositionsForTile(character.position);

      // Add to new tile
      _addCharacterToTile(character);

      sprite.updatePosition();
    }
  }

  /// Get the tile key for tracking occupancy
  String _getTileKey(Vector2 position) {
    return '${position.y.toInt()},${position.x.toInt()}';
  }

  /// Add a character to tile occupancy tracking
  void _addCharacterToTile(Character character) {
    final key = _getTileKey(character.position);
    _tilesOccupancy.putIfAbsent(key, () => []);
    if (!_tilesOccupancy[key]!.contains(character)) {
      _tilesOccupancy[key]!.add(character);
    }
  }

  /// Remove a character from tile occupancy tracking
  void _removeCharacterFromTile(Character character) {
    // Find and remove from all tiles (in case position changed)
    _tilesOccupancy.forEach((key, characters) {
      characters.remove(character);
    });
  }

  /// Get the next available sub-position (0-3) for a tile
  /// Takes into account both characters AND enemies (max 4 entities total)
  int _getNextAvailableSubPosition(Vector2 position) {
    final tile = gameState.grid.getTile(
      position.y.toInt(),
      position.x.toInt(),
    );

    if (tile == null) return 0;

    // Count all entities: characters + enemy (if present)
    final entityCount =
        tile.charactersHere.length + (tile.enemy != null ? 1 : 0);

    // Return the count as the next position (0-3, max 4 entities)
    final nextPos = entityCount;
    return nextPos.clamp(0, 3);
  }

  /// Reassign sub-positions for all entities on a specific tile
  /// Enemies take priority for position 0, then characters fill remaining positions
  void _reassignSubPositionsForTile(Vector2 position) {
    final tile = gameState.grid.getTile(
      position.y.toInt(),
      position.x.toInt(),
    );

    if (tile == null) return;

    int currentPos = 0;

    // Enemy gets position 0 if present (enemies are stationary/priority)
    if (tile.enemy != null) {
      currentPos++; // Skip position 0 for enemy
      // TODO: Update enemy sprite sub-position when enemy sprite system is implemented
    }

    // Assign remaining positions to characters
    for (final character in tile.charactersHere) {
      if (currentPos >= 4) break; // Max 4 entities per tile

      final sprite = characterSprites[character];
      if (sprite != null) {
        sprite.updateSubPosition(currentPos);
      }
      currentPos++;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Backend Integration Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reveal a tile (called when backend reveals fog of war)
  void revealTile(int row, int col) {
    final tile = gameState.grid.getTile(row, col);
    if (tile != null && !tile.isRevealed) {
      tile.isRevealed = true;
      gridComponent?.updateTile(row, col);
    }
  }

  /// Reveal multiple tiles at once
  void revealTiles(List<Vector2> positions) {
    for (final pos in positions) {
      revealTile(pos.y.toInt(), pos.x.toInt());
    }
  }

  /// Add or update an event on a tile (from backend)
  void setTileEvent(int row, int col, TileEvent? event) {
    final tile = gameState.grid.getTile(row, col);
    if (tile != null) {
      tile.event = event;
      gridComponent?.updateTile(row, col);
    }
  }

  /// Complete an event (mark as done)
  void completeEvent(int row, int col) {
    final tile = gameState.grid.getTile(row, col);
    if (tile?.event != null) {
      tile!.event = tile.event!.copyWith(isCompleted: true);
      gridComponent?.updateTile(row, col);
    }
  }
}
