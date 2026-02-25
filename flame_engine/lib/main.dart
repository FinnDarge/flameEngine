import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'models/dungeon_game.dart';
import 'services/nfc_service.dart';
import 'services/management_api_service.dart';
import 'services/mock_nfc_data.dart' show applyApiData;
import 'screens/scenario_selection_screen.dart';
import 'screens/grid_setup_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/character_start_placement_screen.dart';
import 'screens/gameplay_screen.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: GameNavigator()),
  );
}

/// Main navigation widget that switches between screens based on game phase
class GameNavigator extends StatefulWidget {
  const GameNavigator({super.key});

  @override
  State<GameNavigator> createState() => _GameNavigatorState();
}

class _GameNavigatorState extends State<GameNavigator> {
  // Set to true to skip backend API calls and use hardcoded mock data.
  // Toggle back to false when the server is reachable again.
  static const bool _kSkipApi = true;

  late DungeonGame game;
  final NFCService nfcService = NFCService();
  final ManagementApiService _api = ManagementApiService();
  bool _apiLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiThenStart();
  }

  Future<void> _loadApiThenStart() async {
    if (!_kSkipApi) {
      await _api.load();
      // Overwrite mock NFC character data with live pieces from the API
      applyApiData(_api);
    }

    // Build the game using board dimensions from the API (fallback 4×4)
    final board = _kSkipApi ? null : _api.primaryBoard;
    final rows = board?.height ?? 4;
    final cols = board?.width ?? 4;
    game = DungeonGame(rows: rows, columns: cols);

    // Store API players in game state for multiplayer use
    game.gameState.apiPlayers = _kSkipApi
        ? const []
        : List.unmodifiable(_api.players);
    game.gameState.apiBoards = _kSkipApi
        ? const []
        : List.unmodifiable(_api.boards);

    if (mounted) setState(() => _apiLoading = false);
  }

  void _onCharacterSelectionComplete() {
    // Go to start placement screen before gameplay
    game.gameState.phase = GamePhase.characterStartPlacement;
    setState(() {});
  }

  void _onStartPlacementReady() {
    game.startGameplay(); // This sets phase to playing and ensures character sprites exist
    setState(() {});
  }

  void _onStartPlacementBack() {
    game.gameState.phase = GamePhase.characterSelection;
    setState(() {});
  }

  void _onCharacterSelectionBack() {
    // Go back to scenario selection
    game.gameState.localPlayer.releaseCharacter();
    game.gameState.phase = GamePhase.scenarioSelection;
    setState(() {});
  }

  void _onScenarioSelected() {
    // Move to character selection
    setState(() {});
  }

  void _onGameplayBack() {
    game.gameState.phase = GamePhase.characterStartPlacement;
    setState(() {});
  }

  void _onGameEnd() {
    // Reset and go back to scenario selection
    game.resetGame();
    setState(() {});
  }

  @override
  void dispose() {
    nfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while the API is loading
    if (_apiLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 20),
              Text(
                'Loading game data...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<GamePhase>(
      stream: _createPhaseStream(),
      builder: (context, snapshot) {
        final phase = game.gameState.phase;

        if (phase == GamePhase.scenarioSelection) {
          return ScenarioSelectionScreen(
            gameState: game.gameState,
            onScenarioSelected: _onScenarioSelected,
          );
        } else if (phase == GamePhase.puzzleGridSetup) {
          return GridSetupScreen(
            gameState: game.gameState,
            onSetupComplete: _onScenarioSelected,
          );
        } else if (phase == GamePhase.characterSelection) {
          return CharacterSelectionScreen(
            gameState: game.gameState,
            nfcService: nfcService,
            onCharacterSelected: _onCharacterSelectionComplete,
            onBack: _onCharacterSelectionBack,
          );
        } else if (phase == GamePhase.characterStartPlacement) {
          return CharacterStartPlacementScreen(
            gameState: game.gameState,
            onReady: _onStartPlacementReady,
            onBack: _onStartPlacementBack,
          );
        } else {
          return GameplayScreen(
            game: game,
            gameState: game.gameState,
            nfcService: nfcService,
            onGameEnd: _onGameEnd,
            onBack: _onGameplayBack,
          );
        }
      },
    );
  }

  // Simple stream to trigger rebuilds when game state changes
  Stream<GamePhase> _createPhaseStream() async* {
    while (true) {
      yield game.gameState.phase;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
