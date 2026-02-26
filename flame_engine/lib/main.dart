import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'models/game_state.dart';
import 'models/dungeon_game.dart';
import 'services/nfc_service.dart';
import 'services/tile_input_provider.dart';
import 'services/management_api_service.dart';
import 'services/session_api_service.dart';
import 'controllers/session_flow_controller.dart';
import 'screens/scenario_selection_screen.dart';
import 'screens/session_selection_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/character_start_placement_screen.dart';
import 'screens/gameplay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService().init();
  runApp(
    // Listener at the root catches the very first pointer-down event and
    // starts audio – required by the browser autoplay policy on web.
    Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => AudioService().start(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GameNavigator(),
      ),
    ),
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
  static const bool _kSkipApi = false;

  late DungeonGame game;
  final NFCService nfcService = NFCService();
  late final TileInputProvider _tileInputProvider;
  final ManagementApiService _api = ManagementApiService();
  final SessionApiService _sessionApi = SessionApiService();
  late final SessionFlowController _sessionFlow;
  bool _apiLoading = true;
  bool _serverOffline = false;

  @override
  void initState() {
    super.initState();
    _sessionFlow = SessionFlowController(sessionApi: _sessionApi);
    _tileInputProvider = NfcTileInputProvider(nfcService: nfcService);
    _loadApiThenStart();
  }

  Future<void> _loadApiThenStart() async {
    if (!_kSkipApi) {
      print('\n🚀 App starting with REAL API mode (_kSkipApi = false)');
      print('   Using API pieces directly (no mock data)\n');
      await _api.load();
      print('\n📦 API data loaded:');
      print('   Players: ${_api.players.length}');
      print('   Boards: ${_api.boards.length}');
      print('   Pieces: ${_api.pieces.length}');
      if (_api.pieces.isNotEmpty) {
        print('   Available pieces:');
        for (var piece in _api.pieces) {
          print('      - ${piece.name}: ${piece.nfcTagId}');
        }
      }
    } else {
      print('\n🚀 App starting with MOCK mode (_kSkipApi = true)');
      print('   Skipping API calls, using hardcoded data\n');
    }

    // Build the game with default 4x4 grid (will be recreated when scenario is selected)
    final board = _kSkipApi ? null : _api.primaryBoard;
    final rows = board?.height ?? 4;
    final cols = board?.width ?? 4;
    game = DungeonGame(rows: rows, columns: cols);

    // Store API data in game state
    game.gameState.apiPlayers =
        _kSkipApi ? const [] : List.unmodifiable(_api.players);
    game.gameState.apiBoards =
        _kSkipApi ? const [] : List.unmodifiable(_api.boards);
    game.gameState.apiPieces =
        _kSkipApi ? const [] : List.unmodifiable(_api.pieces);
    game.gameState.apiGames =
        _kSkipApi ? const [] : List.unmodifiable(_api.games);

    print('\n✅ Game state initialized:');
    print('   gameState.apiPlayers: ${game.gameState.apiPlayers.length}');
    print('   gameState.apiBoards: ${game.gameState.apiBoards.length}');
    print('   gameState.apiPieces: ${game.gameState.apiPieces.length}');
    if (game.gameState.apiPieces.isNotEmpty) {
      print('   Pieces in game state:');
      for (var piece in game.gameState.apiPieces) {
        print('      - ${piece.name}: ${piece.nfcTagId}');
      }
    }
    print('');

    // Check if server is offline (no games and no players retrieved)
    if (!_kSkipApi &&
        game.gameState.apiGames.isEmpty &&
        game.gameState.apiPlayers.isEmpty) {
      _serverOffline = true;
      print('⚠️  WARNING: Game server appears to be offline!');
      print('   No games and no players could be retrieved from the backend.');
    }

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

  Future<void> _onSessionReady() async {
    try {
      await _sessionFlow.ensureLobbyReady(game.gameState);
      if (!mounted) return;
      game.gameState.phase = GamePhase.characterSelection;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to enter lobby: $e')),
      );
    }
  }

  void _onSessionBack() {
    game.gameState.sessionId = null;
    game.gameState.phase = GamePhase.scenarioSelection;
    setState(() {});
  }

  void _onCharacterSelectionBack() {
    // Go back to session selection
    game.gameState.localPlayer.releaseCharacter();
    game.gameState.phase = GamePhase.sessionSelection;
    setState(() {});
  }

  void _onScenarioSelected() {
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
    _tileInputProvider.stop();
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
            serverOffline: _serverOffline,
            onScenarioSelected: _onScenarioSelected,
          );
        } else if (phase == GamePhase.sessionSelection) {
          return SessionSelectionScreen(
            gameState: game.gameState,
            sessionFlow: _sessionFlow,
            onSessionReady: _onSessionReady,
            onBack: _onSessionBack,
          );
        } else if (phase == GamePhase.characterSelection) {
          return CharacterSelectionScreen(
            gameState: game.gameState,
            nfcService: nfcService,
            sessionFlow: _sessionFlow,
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
            tileInputProvider: _tileInputProvider,
            onGameEnd: _onGameEnd,
            sessionFlow: _sessionFlow,
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
