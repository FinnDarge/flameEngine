import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'models/game_grid.dart';
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
      setState(() {
        nfcStatus = 'Tag detected: $tagId';
      });

      // Auto-restart scanning after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && nfcScanning) {
          setState(() {
            nfcStatus = 'NFC Scanning - Tap a tile';
          });
        }
      });
    });

    setState(() {
      nfcScanning = true;
      nfcStatus = 'NFC Scanning - Tap a tile';
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text('Dungeon Crawler - 3x3 Grid'),
        backgroundColor: const Color(0xFF2d2d2d),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nfcStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  'Grid: ${game.grid.rows}x${game.grid.columns}',
                  style: const TextStyle(color: Colors.white70),
                ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grid reset!')),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Grid'),
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
                  'Each room is 10cm x 10cm on physical board',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Main Flame game class
class DungeonGame extends FlameGame {
  GameGrid grid;
  GridComponent? gridComponent;
  final SpritesheetLoader spritesheetLoader = SpritesheetLoader();

  DungeonGame() : grid = GameGrid(rows: 3, columns: 3) {
    // Initialize grid with basic layout
    grid.initializeTestDungeon();
    print('✓ DungeonGame created');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the spritesheet first
    await spritesheetLoader.load();

    // Create visual grid component
    gridComponent = GridComponent(
      grid: grid,
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
    print('NFC Tag detected: $tagId');
    print('Data: $data');

    // Find the tile with this NFC tag
    final tile = grid.findTileByNFC(tagId);
    if (tile != null) {
      print('Found tile at (${tile.row}, ${tile.col}) - Type: ${tile.type}');

      // Reveal the tile
      tile.isRevealed = true;

      // Update visual
      gridComponent?.updateTile(tile.row, tile.col);

      // TODO: Handle different tile types (enemy encounter, treasure, etc.)
    } else {
      print('No tile found with NFC tag: $tagId');
    }
  }

  /// Reset the game to initial state
  void resetGame() {
    grid.initializeTestDungeon();
    gridComponent?.updateAllTiles();
  }
}

