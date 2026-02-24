import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

/// Screen for setting up the physical puzzle grid before character selection
class PuzzleGridSetupScreen extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onSetupComplete;

  const PuzzleGridSetupScreen({
    super.key,
    required this.gameState,
    required this.onSetupComplete,
  });

  void _continueToCharacterSelection() {
    gameState.phase = GamePhase.characterSelection;
    onSetupComplete();
  }

  void _goBack() {
    gameState.phase = GamePhase.scenarioSelection;
    onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: TokenAndBoardAppBar(onBackPressed: _goBack),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Arrange Your Grid Tiles',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSubtitleText(),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Puzzle Grid Diagram
            Padding(
              padding: const EdgeInsets.all(24),
              child: gameState.selectedScenario?.id == 'tutorial'
                  ? _buildTutorialGrid(context)
                  : _buildClassicGrid(context),
            ),
            const SizedBox(height: 32),
            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (gameState.selectedScenario?.id == 'tutorial') ...[
                      _instructionItem(
                        'Grid Tile A (blue) forms the top row: cells 1 and 2',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem(
                        'Grid Tile B (green) forms the bottom row: cells 3 and 4',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem('Together they create a 2x2 game grid'),
                    ] else if (gameState.selectedScenario?.id == 'classic') ...[
                      _instructionItem(
                        'Arrange 8 grid tiles (A-H) to form a 4x4 grid',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem('Tiles A-B form the top row (2 tiles)'),
                      const SizedBox(height: 6),
                      _instructionItem(
                        'Tiles C-D form the second row (2 tiles)',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem(
                        'Tiles E-F form the third row (2 tiles)',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem(
                        'Tiles G-H form the bottom row (2 tiles)',
                      ),
                    ],
                    const SizedBox(height: 6),
                    _instructionItem(
                      'Tap "Ready" below when your tiles are arranged',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: _continueToCharacterSelection,
                icon: const Icon(Icons.check),
                label: const Text('Ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getSubtitleText() {
    if (gameState.selectedScenario?.id == 'tutorial') {
      return 'Grid Tile A and Tile B form a 2x2 grid';
    } else if (gameState.selectedScenario?.id == 'classic') {
      return 'Eight grid tiles form a 4x4 grid';
    }
    return '';
  }

  Widget _buildTutorialGrid(BuildContext context) {
    return Column(
      children: [
        Text(
          'Complete 2x2 Game Grid',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 - Grid Tile A (Blue)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGridCell('1', Colors.blue.shade900, Colors.blue.shade200),
                _buildGridCell('2', Colors.blue.shade900, Colors.blue.shade200),
              ],
            ),
            // Row 2 - Grid Tile B (Green)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGridCell(
                  '3',
                  Colors.green.shade900,
                  Colors.green.shade200,
                ),
                _buildGridCell(
                  '4',
                  Colors.green.shade900,
                  Colors.green.shade200,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem('Grid Tile A', Colors.blue.shade900),
            const SizedBox(width: 24),
            _legendItem('Grid Tile B', Colors.green.shade900),
          ],
        ),
      ],
    );
  }

  Widget _buildClassicGrid(BuildContext context) {
    final colors = [
      Colors.blue.shade900,
      Colors.blue.shade700,
      Colors.green.shade900,
      Colors.green.shade700,
      Colors.purple.shade900,
      Colors.purple.shade700,
      Colors.orange.shade900,
      Colors.orange.shade700,
    ];
    final borderColors = [
      Colors.blue.shade200,
      Colors.blue.shade100,
      Colors.green.shade200,
      Colors.green.shade100,
      Colors.purple.shade200,
      Colors.purple.shade100,
      Colors.orange.shade200,
      Colors.orange.shade100,
    ];
    final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    return Column(
      children: [
        Text(
          'Complete 4x4 Game Grid',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1 - Tiles A (1-2) and B (3-4)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell('1', 'A', colors[0], borderColors[0]),
                _buildClassicGridCell('2', 'A', colors[0], borderColors[0]),
                _buildClassicGridCell('3', 'B', colors[1], borderColors[1]),
                _buildClassicGridCell('4', 'B', colors[1], borderColors[1]),
              ],
            ),
            // Row 2 - Tiles C (5-6) and D (7-8)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell('5', 'C', colors[2], borderColors[2]),
                _buildClassicGridCell('6', 'C', colors[2], borderColors[2]),
                _buildClassicGridCell('7', 'D', colors[3], borderColors[3]),
                _buildClassicGridCell('8', 'D', colors[3], borderColors[3]),
              ],
            ),
            // Row 3 - Tiles E (9-10) and F (11-12)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell('9', 'E', colors[4], borderColors[4]),
                _buildClassicGridCell('10', 'E', colors[4], borderColors[4]),
                _buildClassicGridCell('11', 'F', colors[5], borderColors[5]),
                _buildClassicGridCell('12', 'F', colors[5], borderColors[5]),
              ],
            ),
            // Row 4 - Tiles G (13-14) and H (15-16)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell('13', 'G', colors[6], borderColors[6]),
                _buildClassicGridCell('14', 'G', colors[6], borderColors[6]),
                _buildClassicGridCell('15', 'H', colors[7], borderColors[7]),
                _buildClassicGridCell('16', 'H', colors[7], borderColors[7]),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(8, (index) {
            return _legendItem('Tile ${labels[index]}', colors[index]);
          }),
        ),
      ],
    );
  }

  Widget _buildGridCell(
    String number,
    Color backgroundColor,
    Color borderColor,
  ) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildClassicGridCell(
    String number,
    String tileLabel,
    Color backgroundColor,
    Color borderColor,
  ) {
    return Container(
      width: 65,
      height: 65,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _instructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 6, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30, width: 1),
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
