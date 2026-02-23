import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'models/game_grid.dart';
import 'models/game_state.dart';
import 'models/character.dart';
import 'models/player.dart';
import 'components/grid_component.dart';
import 'services/nfc_service.dart';
import 'utils/spritesheet_loader.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    ),
  );
}

/// Main game screen widget
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DungeonGame game;
  final NFCService nfcService = NFCService();
  bool nfcAvailable = false;
  bool nfcScanning = false;
  String nfcStatus = 'NFC Not Started';

  @override
  void initState() {
    super.initState();
    game = DungeonGame();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    final available = await nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available ? 'NFC Available - Tap button to start' : 'NFC Not Available';
    });
  }

  void _toggleNFCScanning() {
    if (!nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC not available on this device')),
      );
      return;
    }

    if (nfcScanning) {
      _stopNFCScanning();
    } else {
      _startNFCScanning();
    }
  }

  void _startNFCScanning() {
    nfcService.startScanning((tagId, data) {
      // Handle NFC tag discovery
      game.handleNFCTag(tagId, data);
      
      // Update UI after NFC processing
      setState(() {
        nfcStatus = 'Tag detected: $tagId';
      });

      // Auto-restart scanning after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && nfcScanning) {
          setState(() {
            nfcStatus = _getDefaultNFCStatus();
          });
        }
      });
    });

    setState(() {
      nfcScanning = true;
      nfcStatus = _getDefaultNFCStatus();
    });
  }

  String _getDefaultNFCStatus() {
    if (game.gameState.phase == GamePhase.characterSelection) {
      return 'Tap character figure to claim';
    } else if (game.gameState.phase == GamePhase.playing) {
      return 'Tap character, then cell';
    } else {
      return 'Game complete';
    }
  }

  void _stopNFCScanning() {
    nfcService.stopScanning();
    setState(() {
      nfcScanning = false;
      nfcStatus = 'NFC Stopped';
    });
  }

  @override
  void dispose() {
    nfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = game.gameState.phase;
    final player = game.gameState.localPlayer;
    final currentTurn = game.gameState.currentTurnCharacter;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(_getPhaseTitle(phase)),
        backgroundColor: _getPhaseColor(phase),
        actions: [
          IconButton(
            icon: Icon(
              nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
              color: nfcScanning ? Colors.green : (nfcAvailable ? Colors.orange : Colors.red),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(nfcStatus)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Column(
              children: [
                // NFC Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nfcStatus,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      'Turn: ${game.gameState.turnNumber}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Character Selection Status or Turn Info
                if (phase == GamePhase.characterSelection)
                  _buildCharacterSelectionStatus(player)
                else if (phase == GamePhase.playing)
                  _buildTurnStatus(player, currentTurn),
              ],
            ),
          ),
          // Game widget
          Expanded(
            child: GameWidget(game: game),
          ),
          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        game.resetGame();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grid reset!')),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                    if (phase == GamePhase.characterSelection)
                      ElevatedButton.icon(
                        onPressed: player.character != null
                            ? () {
                                game.startGameplay();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Game started!')),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: nfcAvailable ? _toggleNFCScanning : null,
                      icon: Icon(nfcScanning ? Icons.stop : Icons.nfc),
                      label: Text(nfcScanning ? 'Stop NFC' : 'Start NFC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nfcScanning ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Physical board: 10cm x 10cm cells with NFC tags',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseTitle(GamePhase phase) {
    switch (phase) {
      case GamePhase.characterSelection:
        return 'Character Selection';
      case GamePhase.playing:
        return 'Dungeon Crawler - Playing';
      case GamePhase.victory:
        return '🎉 VICTORY!';
      case GamePhase.defeat:
        return '💀 Defeat';
    }
  }

  Color _getPhaseColor(GamePhase phase) {
    switch (phase) {
      case GamePhase.characterSelection:
        return const Color(0xFF2d4d8d);
      case GamePhase.playing:
        return const Color(0xFF2d2d2d);
      case GamePhase.victory:
        return const Color(0xFF2d8d2d);
      case GamePhase.defeat:
        return const Color(0xFF8d2d2d);
    }
  }

  Widget _buildCharacterSelectionStatus(Player player) {
    if (player.character == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tap your character figure to claim it',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    } else {
      final char = player.character!;
      final charColor = Color(char.characterClass.color);
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: charColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: charColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You are: ${char.name} (${char.characterClass.name.toUpperCase()})',
                style: TextStyle(color: charColor),
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      );
    }
  }

  Widget _buildTurnStatus(Player player, Character? currentTurn) {
    final isYourTurn = game.gameState.isLocalPlayerTurn;
    final char = player.character;
    
    if (char == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isYourTurn 
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isYourTurn ? Icons.play_circle : Icons.pause_circle,
            color: isYourTurn ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isYourTurn
                  ? 'YOUR TURN - Tap ${char.name}, then tap destination'
                  : 'Current turn: ${currentTurn?.name ?? "Unknown"}',
              style: TextStyle(
                color: isYourTurn ? Colors.green : Colors.white70,
                fontWeight: isYourTurn ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main Flame game class
class DungeonGame extends FlameGame {
  late GameState gameState;
  GridComponent? gridComponent;
  final SpritesheetLoader spritesheetLoader = SpritesheetLoader();
  
  // Track last tapped NFC tag for movement flow
  String? lastTappedCharacterNfc;

  DungeonGame() {
    final grid = GameGrid(rows: 3, columns: 3);
    grid.generateRandomDungeon(); // Dynamic dungeon!
    
    gameState = GameState(grid: grid);
    print('✓ DungeonGame created - Phase: ${gameState.phase.name}');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the spritesheet first
    await spritesheetLoader.load();

    // Create visual grid component
    gridComponent = GridComponent(
      grid: gameState.grid,
      cellSize: 100.0,
      spritesheetLoader: spritesheetLoader,
    );

    await add(gridComponent!);
    print('✓ Game loaded successfully');
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
    }
  }

  /// Handle movement during gameplay
  void _handleMovement(String tagId) {
    // Check if it's a character NFC tag
    final isCharacterTag = CharacterClass.values.any((c) => c.nfcTagId == tagId);
    
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
      print('⚠ Not your turn! Current turn: ${gameState.currentTurnCharacter?.name}');
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
      final character = gameState.localPlayer.character!;
      final moved = gameState.moveCharacter(character, destination);

      if (moved) {
        // Update visual
        gridComponent?.updateAllTiles();

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
    gameState.grid.generateRandomDungeon();
    gridComponent?.updateAllTiles();
    
    // Reset game state
    gameState.characters.clear();
    gameState.localPlayer.releaseCharacter();
    gameState.phase = GamePhase.characterSelection;
    gameState.currentTurnIndex = 0;
    gameState.turnNumber = 1;
    lastTappedCharacterNfc = null;
    
    print('🔄 Game reset - Select your character!');
  }

  /// Start the game after character selection
  void startGameplay() {
    gameState.startGame();
    gridComponent?.updateAllTiles();
  }
}

