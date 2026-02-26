import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart';
import '../services/tile_input_provider.dart';
import '../controllers/session_flow_controller.dart';
import '../services/session_api_service.dart';
import '../services/management_api_service.dart' show ApiPiece, ApiGamePiece;
import '../models/dungeon_game.dart';
import '../widgets/token_and_board_app_bar.dart';
import '../widgets/inventory_overlay.dart';
import '../widgets/session_info_footer.dart';

/// Gameplay screen for the actual game
class GameplayScreen extends StatefulWidget {
  final DungeonGame game;
  final GameState gameState;
  final NFCService nfcService;
  final TileInputProvider tileInputProvider;
  final VoidCallback onGameEnd;
  final SessionFlowController sessionFlow;
  final VoidCallback? onBack;

  const GameplayScreen({
    super.key,
    required this.game,
    required this.gameState,
    required this.nfcService,
    required this.tileInputProvider,
    required this.onGameEnd,
    required this.sessionFlow,
    this.onBack,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  bool nfcAvailable = false;
  String nfcStatus = 'Initialising NFC...';
  bool showInventory = false;
  Timer? _sessionPollTimer;
  StreamSubscription<TileActivationInput>? _tileInputSubscription;

  bool get isSessionOwner {
    final local = widget.gameState.localApiPlayer;
    final creatorUuid = widget.gameState.sessionCreatorUuid;
    if (local == null || creatorUuid == null) return false;
    return local.uuid == creatorUuid;
  }

  Future<void> _handleStartGame() async {
    try {
      await widget.sessionFlow.startSession(widget.gameState);
      // Optionally, trigger any local state update or fetch
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start game: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tileInputSubscription = widget.tileInputProvider.inputs.listen(
      _handleTileActivationInput,
    );
    _initNFC();
    // Start polling session state every 5 seconds
    _sessionPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      print('[Polling] 5s interval: polling session state...');
      pollSessionState();
    });
  }

  /// Poll the session state from the backend and update the game state
  Future<void> pollSessionState() async {
    // Only poll if in a session and playing
    if (widget.gameState.sessionId == null ||
        widget.gameState.playerAccessToken == null) {
      return;
    }
    if (widget.gameState.phase != GamePhase.playing) return;

    try {
      final sessionApi = SessionApiService();
      final boardFields = await sessionApi.getSessionBoard(
        sessionUuid: widget.gameState.sessionId!,
        userKey: widget.gameState.playerAccessToken!,
      );

      // Build a map of piece UUID to field position
      final Map<String, PointObject> piecePositions = {};
      for (final field in boardFields) {
        for (final pieceUuid in field.pieces) {
          piecePositions[pieceUuid] = field.position;
        }
      }

      // Map each character to its piece UUID (via apiPieces and gameStartPositions)
      for (final character in widget.gameState.characters) {
        // Find the piece UUID for this character
        String? pieceUuid;
        // Try to match by NFC tag ID via apiPieces
        ApiPiece? apiPiece;
        try {
          apiPiece = widget.gameState.apiPieces.firstWhere(
            (p) => p.nfcTagId == character.nfcTagId,
          );
        } catch (_) {
          apiPiece = null;
        }
        if (apiPiece != null) {
          ApiGamePiece? gamePiece;
          try {
            gamePiece = widget.gameState.gameStartPositions.firstWhere(
              (gp) => gp.piece == apiPiece!.uuid,
            );
          } catch (_) {
            gamePiece = null;
          }
          if (gamePiece != null && gamePiece.piece != null) {
            pieceUuid = gamePiece.piece;
          }
        }
        // Fallback: try to match by role name
        if (pieceUuid == null) {
          ApiGamePiece? gamePiece;
          try {
            gamePiece = widget.gameState.gameStartPositions.firstWhere(
              (gp) =>
                  gp.roleName?.toLowerCase() ==
                  character.characterClass.name.toLowerCase(),
            );
          } catch (_) {
            gamePiece = null;
          }
          if (gamePiece != null && gamePiece.piece != null) {
            pieceUuid = gamePiece.piece;
          }
        }
        // If we have a piece UUID and a position, update the character
        if (pieceUuid != null && piecePositions.containsKey(pieceUuid)) {
          final pos = piecePositions[pieceUuid]!;
          final newPosition = Vector2(pos.x.toDouble(), pos.y.toDouble());
          if (character.position != newPosition) {
            character.position = newPosition;
          }
        }
      }
      setState(() {}); // Trigger UI update
    } catch (e) {
      // Ignore polling errors
    }
  }

  Future<void> _initNFC() async {
    final available = await widget.nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available ? _getDefaultNFCStatus() : 'NFC Not Available';
    });
    if (available) {
      unawaited(_startNFCScanning());
    }
  }

  void _handleTileActivationInput(TileActivationInput input) {
    // Pass input to game logic (fire and forget)
    unawaited(widget.game.handleNFCTag(input.tileId, input.data));

    if (!mounted) {
      return;
    }

    setState(() {
      nfcStatus = 'Tag detected: ${input.tileId}';
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          nfcStatus = _getDefaultNFCStatus();
        });
      }
    });
  }

  Future<void> _startNFCScanning() async {
    try {
      await widget.tileInputProvider.start();
    } catch (e) {
      if (mounted) {
        setState(() {
          nfcStatus = 'NFC error: $e';
        });
      }
    }
  }

  String _getDefaultNFCStatus() {
    if (widget.gameState.phase == GamePhase.playing) {
      return 'Tap destination field to move';
    } else {
      return 'Game complete';
    }
  }

  @override
  void dispose() {
    _tileInputSubscription?.cancel();
    unawaited(widget.tileInputProvider.stop());
    _sessionPollTimer?.cancel();
    super.dispose();
  }

  Widget _buildTurnStatus(
    // ignore: avoid_positional_boolean_parameters
    bool isYourTurn,
    Character? currentCharacter,
    Character? localCharacter,
  ) {
    final color = Color(
      (isYourTurn
          ? (localCharacter?.characterClass.color ?? 0xFFFFFFFF)
          : (currentCharacter?.characterClass.color ?? 0xFFFFFFFF)),
    );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(isYourTurn ? 0.3 : 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isYourTurn ? Icons.play_circle : Icons.pause_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isYourTurn
                  ? 'YOUR TURN - Tap destination field (${localCharacter?.name ?? "your character"} will move)'
                  : 'Current turn: ${currentCharacter?.name ?? "Waiting for players..."}',
              style: TextStyle(
                color: color,
                fontWeight: isYourTurn ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.gameState.phase;
    final player = widget.gameState.localPlayer;
    final currentTurn = widget.gameState.currentTurnCharacter;

    final localPlayerUuid = widget.gameState.localApiPlayer?.uuid;
    // Build a map of roleUuid to player name for all session players
    final Map<String, String> roleToPlayerName = {
      for (final sp in widget.gameState.sessionPlayers)
        sp.role: (widget.gameState.apiPlayers
                .where((ap) => ap.uuid == sp.player)
                .firstOrNull
                ?.name ??
            'Unknown')
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(onBackPressed: widget.onBack),
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
                      'Turn: ${widget.gameState.turnNumber}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Turn Status
                if (phase == GamePhase.playing)
                  _buildTurnStatus(
                    widget.gameState.isLocalPlayerTurn,
                    currentTurn,
                    player.character,
                  ),
                // Start Game button for session owner
                if (phase == GamePhase.characterSelection && isSessionOwner)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00d9ff),
                        foregroundColor: Color(0xFF1a1a1a),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _handleStartGame,
                    ),
                  ),
              ],
            ),
          ),
          // Game widget and other players
          Expanded(
            child: Row(
              children: [
                // Main game area
                Expanded(
                  child: Stack(
                    children: [
                      GameWidget(game: widget.game),
                      // Inventory overlay
                      if (showInventory)
                        InventoryOverlay(
                          player: player,
                          onClose: () {
                            setState(() {
                              showInventory = false;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                // Other players section
                Container(
                  width: 180,
                  color: const Color(0xFF232b36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Other Players',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: widget.gameState.sessionPlayers
                              .where((sp) => sp.player != localPlayerUuid)
                              .map((sp) {
                            final roleName = widget.gameState.gameStartPositions
                                    .where((gp) =>
                                        gp.role == sp.role &&
                                        gp.roleName != null)
                                    .firstOrNull
                                    ?.roleName ??
                                'Role';
                            final playerName =
                                roleToPlayerName[sp.role] ?? 'Player';
                            return ListTile(
                              title: Text(
                                '$roleName@$playerName',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Session info footer
          SessionInfoFooter(gameState: widget.gameState),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            showInventory = !showInventory;
          });
        },
        backgroundColor: const Color(0xFF1a2332),
        foregroundColor: const Color(0xFF00d9ff),
        elevation: 8,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00d9ff).withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 24),
            ),
            if (player.inventory.usedSlots > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00d9ff), Color(0xFF0088cc)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF1a2332), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d9ff).withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(
                    child: Text(
                      '${player.inventory.usedSlots}',
                      style: const TextStyle(
                        color: Color(0xFF1a2332),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        label: const Text(
          'INVENTORY',
          style: TextStyle(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
