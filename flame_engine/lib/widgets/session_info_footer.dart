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

  List<Widget> _buildRemotePlayersList() {
    final remoteCharacters = gameState.characters
        .where((c) => c != gameState.localPlayer.character)
        .toList();

    if (remoteCharacters.isEmpty) {
      return [
        Text(
          'None',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ];
    }

    return remoteCharacters.map((character) {
      final posX = (character.position.x.toInt() + 1);
      final posY = (character.position.y.toInt() + 1);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SelectableText(
          '${character.name} @ ($posX, $posY)',
          style: TextStyle(
            color: Color(character.characterClass.color),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }).toList();
  }

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
          // Claimed role (character class)
          if (gameState.localPlayer.hasCharacter)
            Column(
              children: [
                Text(
                  'Claimed Role',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  gameState.localPlayer.character?.name ?? 'Unknown',
                  style: TextStyle(
                    color: Color(
                        gameState.localPlayer.character?.characterClass.color ??
                            0xFF00d9ff),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          // Remote players
          if (gameState.sessionPlayers.isNotEmpty)
            Column(
              children: [
                Text(
                  'Other Players',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                ..._buildRemotePlayersList(),
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
