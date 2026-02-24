import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'models/dungeon_game.dart';
import 'services/nfc_service.dart';
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
  late DungeonGame game;
  final NFCService nfcService = NFCService();

  @override
  void initState() {
    super.initState();
    game = DungeonGame();
  }

  void _onCharacterSelectionComplete() {
    // Go to start placement screen before gameplay
    game.gameState.phase = GamePhase.characterStartPlacement;
    setState(() {});
  }

  void _onStartPlacementReady() {
    game.gameState.phase = GamePhase.playing;
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
