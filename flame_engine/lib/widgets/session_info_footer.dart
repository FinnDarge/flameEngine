import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Displays the current player name and session code in a footer bar.
/// Shows on all screens after the session selection screen.
class SessionInfoFooter extends StatelessWidget {
  final GameState gameState;

  const SessionInfoFooter({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF1a1a1a),
      child: Column(
        children: [
          // Player name
          if (gameState.localApiPlayer != null)
            Column(
              children: [
                Text(
                  'Player',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  gameState.localApiPlayer!.name,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          // Session code
          Text(
            'Session Code',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            gameState.sessionId ?? gameState.sessionUuid ?? '',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
