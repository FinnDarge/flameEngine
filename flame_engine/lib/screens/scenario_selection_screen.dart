import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

/// Screen shown at startup — single entry point to create/join an online game.
class ScenarioSelectionScreen extends StatelessWidget {
  final GameState gameState;
  final bool serverOffline;
  final VoidCallback onScenarioSelected;

  const ScenarioSelectionScreen({
    super.key,
    required this.gameState,
    required this.onScenarioSelected,
    this.serverOffline = false,
  });

  void _startOnlineGame() {
    gameState.selectedApiGame = null;
    gameState.selectedScenario = null;
    gameState.phase = GamePhase.sessionSelection;
    onScenarioSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            SvgPicture.asset(
              'assets/images/TB_logo.svg',
              width: 72,
              height: 72,
              colorFilter: ColorFilter.mode(
                Colors.blue.shade300,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Token & Board Adventures',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ready to play? Start a new online game.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Server status indicator (below the "Ready to play" text)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: serverOffline
                        ? Colors.red.shade400
                        : Colors.green.shade400,
                    boxShadow: [
                      BoxShadow(
                        color: (serverOffline ? Colors.red : Colors.green)
                            .shade400,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  serverOffline ? 'Backend Offline' : 'Backend Online',
                  style: TextStyle(
                    color: serverOffline
                        ? Colors.red.shade400
                        : Colors.green.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Single action card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startOnlineGame,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.deepPurple.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.public_rounded,
                          color: Colors.deepPurple.shade200,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Online Game',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a new session or join an existing one with a join code',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
