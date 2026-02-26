import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart';
import '../models/dungeon_game.dart';
import '../widgets/token_and_board_app_bar.dart';
import '../widgets/inventory_overlay.dart';
import '../widgets/session_info_footer.dart';

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
  bool showInventory = false;

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
      unawaited(_startNFCScanning());
    }
  }

  Future<void> _startNFCScanning() async {
    try {
      await widget.nfcService.startScanning((tagId, data) {
        // Pass NFC event to game logic (fire and forget)
        unawaited(widget.game.handleNFCTag(tagId, data));

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
    widget.nfcService.stopScanning();
    super.dispose();
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
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
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
                  ? 'YOUR TURN - Tap destination field (${localCharacter?.name ?? "your character"} will move)'
                  : 'Current turn: ${currentCharacter?.name ?? "Waiting for players..."}',
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
          // Game widget
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
