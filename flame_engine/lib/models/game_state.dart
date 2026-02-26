import 'package:flame/components.dart';
import 'character.dart';
import 'player.dart';
import 'game_grid.dart';
import 'tile_type.dart';
import 'game_scenario.dart';
import '../services/management_api_service.dart'
    show
        ApiPlayer,
        ApiBoard,
        ApiPiece,
        ApiGame,
        ApiGamePiece,
        ManagementApiService;
import '../services/session_api_service.dart' show SessionPlayer;
import '../utils/sample_items.dart';

/// Manages the overall game state
class GameState {
  /// The UUID of the session creator (owner)
  String? sessionCreatorUuid;

  /// The game grid
  final GameGrid grid;

  /// This player (the one using this phone)
  late Player localPlayer;

  /// Selected game scenario
  GameScenario? selectedScenario;

  /// All characters in the game (max 4)
  final List<Character> characters = [];

  /// Current turn index (which character's turn is it)
  int currentTurnIndex = 0;

  /// Game phase
  GamePhase phase = GamePhase.scenarioSelection;

  /// Turn number
  int turnNumber = 1;

  /// Goal position
  final Vector2 goalPosition;

  /// Players loaded from the management API (for multiplayer / lobby).
  List<ApiPlayer> apiPlayers = const [];

  /// Boards loaded from the management API.
  List<ApiBoard> apiBoards = const [];

  /// Pieces loaded from the management API (characters with NFC tags).
  List<ApiPiece> apiPieces = const [];

  /// Game pieces loaded from the backend (/gamePieces endpoint) with starting positions
  List<ApiGamePiece> gameStartPositions = const [];

  /// Access token for the current player (for API authentication)
  String? playerAccessToken;

  /// Games loaded from the management API.
  List<ApiGame> apiGames = const [];

  /// The API game chosen on the scenario screen (used by session creation).
  ApiGame? selectedApiGame;

  /// Session ID for the current multiplayer session (create or join).
  String? sessionId;

  /// Session UUID returned by the backend after create/join.
  String? sessionUuid;

  /// The ApiPlayer that represents the local user (carries the x-user-key).
  ApiPlayer? localApiPlayer;

  /// Session players (all players in the current session with their roles).
  List<SessionPlayer> sessionPlayers = const [];

  GameState({required this.grid, Vector2? goal})
      : goalPosition = goal ??
            Vector2((grid.columns - 1).toDouble(), (grid.rows - 1).toDouble()) {
    // (4,4) in 1-indexed = (3,3) in 0-indexed
    // Create local player with unique ID
    localPlayer = Player(id: DateTime.now().millisecondsSinceEpoch.toString());

    // Add debug starter items for testing inventory
    for (var item in SampleItems.getStarterItems()) {
      localPlayer.inventory.addItem(item);
    }
    // Add some extra test items
    localPlayer.inventory.addItem(SampleItems.device());
    localPlayer.inventory.addItem(SampleItems.oxygenTank());
    localPlayer.inventory.addItem(SampleItems.medkit(quantity: 2));
    localPlayer.inventory.addItem(SampleItems.radio());
  }

  /// Get character whose turn it is
  Character? get currentTurnCharacter {
    if (characters.isEmpty) return null;
    return characters[currentTurnIndex % characters.length];
  }

  /// Check if it's the local player's turn
  bool get isLocalPlayerTurn {
    final currentChar = currentTurnCharacter;
    return currentChar != null && localPlayer.character == currentChar;
  }

  /// Add a character to the game
  void addCharacter(Character character) {
    if (characters.length < 4 && !characters.contains(character)) {
      characters.add(character);
      print(
        '✓ Character added: ${character.characterClass.name} (class: ${character.characterClass}) (${characters.length}/4)',
      );
    }
  }

  /// Reverse NFC tag byte order (e.g., "04:BA:42" <-> "42:BA:04")
  String _reverseNfcTagId(String tagId) {
    final bytes = tagId.split(':');
    return bytes.reversed.join(':');
  }

  /// Check if two NFC tag IDs match (forward or reverse byte order)
  bool _nfcTagMatches(String tag1, String tag2) {
    if (tag1 == tag2) return true;
    if (tag1 == _reverseNfcTagId(tag2)) return true;
    if (_reverseNfcTagId(tag1) == tag2) return true;
    return false;
  }

  /// Map API character names/colors to CharacterClass enum
  /// The backend stores pieces by color (Red, White, Blue, Purple)
  /// but we need to map them to proper class types
  CharacterClass? mapApiNameToCharacterClass(String apiName) {
    final lower = apiName.toLowerCase();

    // Direct class name matches
    if (lower == 'controller') return CharacterClass.controller;
    if (lower == 'engineer') return CharacterClass.engineer;
    if (lower == 'striker') return CharacterClass.striker;
    if (lower == 'vanguard') return CharacterClass.vanguard;

    // Color name mappings (consistent: red-vanguard, white-controller, blue-engineer, purple-striker)
    if (lower == 'red') return CharacterClass.vanguard;
    if (lower == 'white') return CharacterClass.controller;
    if (lower == 'blue') return CharacterClass.engineer;
    if (lower == 'purple') return CharacterClass.striker;

    // Fallback to controller if unknown
    print('⚠️ Unknown API character name: $apiName, defaulting to controller');
    return CharacterClass.controller;
  }

  /// Claim a character for the local player
  bool claimCharacter(String nfcTagId) {
    // Check if already claimed
    if (localPlayer.hasCharacter) {
      print('⚠ Player already has a character: ${localPlayer.character!.name}');
      return false;
    }

    // Find matching character class from API pieces FIRST
    CharacterClass? characterClass;
    String? characterName;

    if (apiPieces.isNotEmpty) {
      print('🔍 Looking up NFC tag in API pieces: $nfcTagId');
      print('   (Also checking reversed: ${_reverseNfcTagId(nfcTagId)})');
      for (var piece in apiPieces) {
        print('   Checking: ${piece.nfcTagId} (${piece.name})');
        if (_nfcTagMatches(piece.nfcTagId, nfcTagId)) {
          // Map from API piece name to CharacterClass enum
          characterClass = mapApiNameToCharacterClass(piece.name);
          characterName = piece.name;
          print('   ✓ MATCH FOUND: ${piece.name} -> ${characterClass?.name}');
          print('      API tag: ${piece.nfcTagId}');
          print('      Scanned: $nfcTagId');
          break;
        }
      }

      if (characterClass == null) {
        print('❌ NFC tag not found in API pieces!');
        print('   Scanned tag: $nfcTagId');
        print('   Reversed:    ${_reverseNfcTagId(nfcTagId)}');
        print('   Available API pieces:');
        for (var p in apiPieces) {
          print('      - ${p.name}: ${p.nfcTagId}');
        }
        return false;
      }
    } else {
      // Fallback to mock data if no API pieces loaded
      print('⚠ No API pieces loaded, using mock CharacterClass enum');
      for (var cls in CharacterClass.values) {
        if (_nfcTagMatches(cls.nfcTagId, nfcTagId)) {
          characterClass = cls;
          break;
        }
      }

      if (characterClass == null) {
        print('⚠ Not a character NFC tag: $nfcTagId');
        return false;
      }
    }

    // Check if already claimed by someone
    final alreadyClaimed = characters.any(
      (c) => c.characterClass == characterClass,
    );
    if (alreadyClaimed) {
      print('⚠ Character already claimed: ${characterClass.name}');
      return false;
    }

    // Create and claim character
    final character = Character(
      characterClass: characterClass,
      nfcTagId: nfcTagId,
      position: Vector2(0, 0), // Start at (1,1) in 1-indexed
    );

    localPlayer.claimCharacter(character);
    addCharacter(character);

    print(
      '✓ Player claimed: ${character.characterClass.name} (API name: ${characterName ?? "enum"})',
    );
    return true;
  }

  /// Move a character to a new position
  bool moveCharacter(Character character, Vector2 newPosition) {
    // Validate it's this character's turn
    if (currentTurnCharacter != character) {
      print('⚠ Not ${character.name}\'s turn!');
      return false;
    }

    // Validate movement is orthogonal and adjacent
    if (!isValidMove(character.position, newPosition)) {
      print('⚠ Invalid move! Must move to adjacent cell (no diagonal)');
      return false;
    }

    // Validate destination is walkable
    final tile = grid.getTile(newPosition.y.toInt(), newPosition.x.toInt());
    if (tile == null || !tile.type.isWalkable) {
      print('⚠ Cannot move to that cell!');
      return false;
    }

    // Validate destination tile has space (max 4 entities: characters + enemies)
    final entityCount =
        tile.charactersHere.length + (tile.enemy != null ? 1 : 0);
    if (entityCount >= 4) {
      print('⚠ The Field is full and cannot hold any more Characters!');
      return false;
    }

    // Remove from old tile
    final oldTile = grid.getTile(
      character.position.y.toInt(),
      character.position.x.toInt(),
    );
    if (oldTile != null) {
      oldTile.charactersHere.remove(character);
      oldTile.hasPlayer = oldTile.charactersHere.isNotEmpty;
    }

    // Update character position
    character.position = newPosition;

    // Add to new tile
    tile.charactersHere.add(character);
    tile.hasPlayer = true;

    print(
      '✓ ${character.name} moved to (${newPosition.x.toInt() + 1}, ${newPosition.y.toInt() + 1})',
    );

    // Check for goal
    if (newPosition.x == goalPosition.x && newPosition.y == goalPosition.y) {
      print('🎯 ${character.name} reached the goal!');
    }

    return true;
  }

  /// Validate movement is orthogonal and adjacent
  bool isValidMove(Vector2 from, Vector2 to) {
    final dx = (to.x - from.x).abs();
    final dy = (to.y - from.y).abs();

    // Must move exactly 1 cell
    // Orthogonal: either dx=1 and dy=0, or dx=0 and dy=1
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  /// Advance to next turn
  void nextTurn() {
    if (characters.isEmpty) return;
    currentTurnIndex++;
    if (currentTurnIndex % characters.length == 0) {
      turnNumber++;
      print('--- Turn $turnNumber ---');
    }
    print('Current turn: ${currentTurnCharacter?.name ?? "Unknown"}');
  }

  /// Start the game (after character selection)
  void startGame() {
    if (characters.isEmpty) {
      print('⚠ No characters selected!');
      return;
    }

    phase = GamePhase.playing;
    currentTurnIndex = 0;
    turnNumber = 1;

    // Clear all character positions on tiles first
    for (int row = 0; row < grid.rows; row++) {
      for (int col = 0; col < grid.columns; col++) {
        final tile = grid.getTile(row, col);
        if (tile != null) {
          tile.charactersHere.clear();
          tile.hasPlayer = false;
        }
      }
    }

    // Define clockwise corner positions: upper-left, upper-right, lower-right, lower-left
    final cornerPositions = [
      Vector2(0, 0), // Upper left
      Vector2((grid.columns - 1).toDouble(), 0), // Upper right
      Vector2((grid.columns - 1).toDouble(),
          (grid.rows - 1).toDouble()), // Lower right
      Vector2(0, (grid.rows - 1).toDouble()), // Lower left
    ];

    // Create list of (character, backendPosition) tuples for sorting
    final characterWithPositions = <(Character, Vector2?)>[];

    for (var character in characters) {
      Vector2? backendPosition;

      if (gameStartPositions.isNotEmpty) {
        // Try to match character to a game piece by character class name
        final characterClassName = character.characterClass.name;

        for (final gamePiece in gameStartPositions) {
          // Match by role name (which should correspond to character class)
          if (gamePiece.roleName != null &&
              gamePiece.roleName!.toLowerCase() ==
                  characterClassName.toLowerCase() &&
              gamePiece.positionX != null &&
              gamePiece.positionY != null) {
            backendPosition = Vector2(
              gamePiece.positionX!,
              gamePiece.positionY!,
            );
            print(
              '✓ Found backend start position for ${character.name}: ($backendPosition.x, $backendPosition.y)',
            );
            break;
          }
        }

        // Fallback: try to match by NFC tag
        if (backendPosition == null) {
          for (final gamePiece in gameStartPositions) {
            // Match piece by NFC tag ID through apiPieces
            for (final piece in apiPieces) {
              if (piece.nfcTagId == character.nfcTagId &&
                  piece.name.toLowerCase() ==
                      gamePiece.pieceName?.toLowerCase() &&
                  gamePiece.positionX != null &&
                  gamePiece.positionY != null) {
                backendPosition = Vector2(
                  gamePiece.positionX!,
                  gamePiece.positionY!,
                );
                print(
                  '✓ Found backend start position for ${character.name} via NFC: ($backendPosition.x, $backendPosition.y)',
                );
                break;
              }
            }
            if (backendPosition != null) break;
          }
        }
      }

      if (backendPosition == null && gameStartPositions.isNotEmpty) {
        print(
            '⚠ No matching backend position found for ${character.name}, will use corner position');
      } else if (backendPosition == null) {
        print(
            '⚠ No backend game pieces loaded, will use corner position for ${character.name}');
      }

      characterWithPositions.add((character, backendPosition));
    }

    // Sort characters by backend position for clockwise arrangement
    // Sort by (x + y) to get a diagonal ordering, then by x for consistency
    characterWithPositions.sort((a, b) {
      final posA = a.$2;
      final posB = b.$2;

      if (posA == null && posB == null) return 0;
      if (posA == null) return 1;
      if (posB == null) return -1;

      final sumA = posA.x + posA.y;
      final sumB = posB.x + posB.y;

      if (sumA != sumB) {
        return sumA.compareTo(sumB);
      }
      return posA.x.compareTo(posB.x);
    });

    // Place characters at clockwise corner positions
    for (int i = 0;
        i < characterWithPositions.length && i < cornerPositions.length;
        i++) {
      final character = characterWithPositions[i].$1;
      final startPosition = cornerPositions[i];

      character.position = startPosition;
      final startTile =
          grid.getTile(startPosition.y.toInt(), startPosition.x.toInt());
      if (startTile != null) {
        startTile.charactersHere.add(character);
        startTile.hasPlayer = true;
      }

      print(
        '✓ ${character.name} placed at clockwise position ${i + 1}: (${startPosition.x.toInt()}, ${startPosition.y.toInt()})',
      );
    }
  }

  /// Check victory condition
  bool checkVictory() {
    // All characters must reach the goal
    return characters.every(
      (char) =>
          char.position.x == goalPosition.x &&
          char.position.y == goalPosition.y,
    );
  }

  /// Sync board state from backend API
  /// This updates field UUIDs and piece positions from the server
  Future<bool> syncBoardFromBackend(ManagementApiService apiService) async {
    if (sessionId == null || playerAccessToken == null) {
      print('⚠ Cannot sync board: no session configured');
      return false;
    }

    final boardData = await apiService.getSessionBoard(
      sessionId: sessionId!,
      accessToken: playerAccessToken!,
    );

    if (boardData == null) {
      print('❌ Failed to sync board from backend');
      return false;
    }

    print('🔄 Syncing board state from backend...');

    // Extract fields list from response
    // Expected structure: { fields: [{uuid, position: {x, y}, pieces: [...]}] }
    final fieldsList = boardData['fields'] as List<dynamic>?;
    if (fieldsList == null) {
      print('⚠ No fields data in response');
      return false;
    }

    // Map field UUIDs to grid tiles based on position
    int mappedFields = 0;
    for (final fieldData in fieldsList) {
      final fieldMap = fieldData as Map<String, dynamic>;
      final fieldUuid = fieldMap['uuid'] as String?;
      final positionMap = fieldMap['position'] as Map<String, dynamic>?;

      if (fieldUuid == null || positionMap == null) continue;

      // API uses {x, y} position, we use row/col
      final x = (positionMap['x'] as num?)?.toInt();
      final y = (positionMap['y'] as num?)?.toInt();

      if (x == null || y == null) continue;

      // Map API position to grid tile (adjust if needed based on API convention)
      final tile = grid.getTile(y, x);
      if (tile != null) {
        tile.fieldUuid = fieldUuid;
        mappedFields++;
      }
    }

    print('✓ Synced $mappedFields field UUIDs to grid tiles');
    return true;
  }
}

/// Game phases
enum GamePhase {
  scenarioSelection,
  puzzleGridSetup,
  sessionSelection,
  characterSelection,
  characterStartPlacement,
  playing,
  victory,
  defeat,
}
