import 'package:flame/components.dart';
import 'character.dart';
import 'player.dart';
import 'game_grid.dart';
import 'tile_type.dart';
import 'game_scenario.dart';

/// Manages the overall game state
class GameState {
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

  GameState({required this.grid, Vector2? goal})
    : goalPosition = goal ?? Vector2(3, 3) {
    // (4,4) in 1-indexed = (3,3) in 0-indexed
    // Create local player with unique ID
    localPlayer = Player(id: DateTime.now().millisecondsSinceEpoch.toString());
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
      print('✓ Character added: ${character.name} (${characters.length}/4)');
    }
  }

  /// Claim a character for the local player
  bool claimCharacter(String nfcTagId) {
    // Check if already claimed
    if (localPlayer.hasCharacter) {
      print('⚠ Player already has a character: ${localPlayer.character!.name}');
      return false;
    }

    // Find matching character class
    CharacterClass? characterClass;
    for (var cls in CharacterClass.values) {
      if (cls.nfcTagId == nfcTagId) {
        characterClass = cls;
        break;
      }
    }

    if (characterClass == null) {
      print('⚠ Not a character NFC tag: $nfcTagId');
      return false;
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

    print('✓ Player claimed: ${character.name}');
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

    // Place all characters at starting position
    final startTile = grid.getTile(0, 0);
    if (startTile != null) {
      for (var character in characters) {
        character.position = Vector2(0, 0); // (1,1) in 1-indexed
        startTile.charactersHere.add(character);
      }
      startTile.hasPlayer = true;
    }

    print('🎮 Game started! ${characters.length} players');
    print(
      'Goal: Reach (${goalPosition.x.toInt() + 1}, ${goalPosition.y.toInt() + 1})',
    );
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
}

/// Game phases
enum GamePhase {
  scenarioSelection,
  puzzleGridSetup,
  characterSelection,
  characterStartPlacement,
  playing,
  victory,
  defeat,
}
