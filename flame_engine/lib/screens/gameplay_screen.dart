import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart';
import '../models/dungeon_game.dart';
import '../widgets/token_and_board_app_bar.dart';

/// Gameplay screen for the actual game
class GameplayScreen extends StatefulWidget {
  final DungeonGame game;
  final GameState gameState;
  final NFCService nfcService;
  final VoidCallback onGameEnd;
  final VoidCallback? onBack;

  const GameplayScreen({
    super.key,
    required this.game,
    required this.gameState,
    required this.nfcService,
    required this.onGameEnd,
    this.onBack,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  bool nfcAvailable = false;
  String nfcStatus = 'Initialising NFC...';

  @override
  void initState() {
    super.initState();
    _initNFC();
  }

  Future<void> _initNFC() async {
    final available = await widget.nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available ? _getDefaultNFCStatus() : 'NFC Not Available';
    });
    if (available) {
      _startNFCScanning();
    }
  }

  void _startNFCScanning() {
    widget.nfcService.startScanning((tagId, data) {
      // Pass NFC event to game logic
      widget.game.handleNFCTag(tagId, data);

      setState(() {
        nfcStatus = 'Tag detected: $tagId';
      });

      // Auto-restart scanning after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            nfcStatus = _getDefaultNFCStatus();
          });
        }
      });
    });
  }

  String _getDefaultNFCStatus() {
    if (widget.gameState.phase == GamePhase.playing) {
      return 'Tap character, then cell';
    } else {
      return 'Game complete';
    }
  }

  @override
  void dispose() {
    widget.nfcService.stopScanning();
    super.dispose();
  }

  Widget _buildCharacterPortrait(Character character) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xCC1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(character.color).withOpacity(0.8),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Image.asset(
              character.characterClass.imagePath,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 68,
                height: 68,
                color: Color(character.color).withOpacity(0.3),
                child: Icon(
                  Icons.person,
                  color: Color(character.color),
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              character.name,
              style: TextStyle(
                color: Color(character.color),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnStatus(
    // ignore: avoid_positional_boolean_parameters
    bool isYourTurn,
    Character? currentCharacter,
    Character? localCharacter,
  ) {
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
                  ? 'YOUR TURN - Tap ${localCharacter?.name}, then tap destination'
                  : 'Current turn: ${currentCharacter?.name ?? "Unknown"}',
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

  @override
  Widget build(BuildContext context) {
    final phase = widget.gameState.phase;
    final player = widget.gameState.localPlayer;
    final currentTurn = widget.gameState.currentTurnCharacter;

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
              ],
            ),
          ),
          // Game widget with character portrait overlay
          Expanded(
            child: Stack(
              children: [
                GameWidget(game: widget.game),
                if (player.character != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildCharacterPortrait(player.character!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
