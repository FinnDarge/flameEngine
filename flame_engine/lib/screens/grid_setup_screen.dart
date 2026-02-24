import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

/// Screen for setting up the physical grid before character selection
class GridSetupScreen extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onSetupComplete;

  const GridSetupScreen({
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
            // Grid Diagram
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
                        'Place Grid Tile A (blue) — it is the complete 2x2 game grid',
                      ),
                    ] else if (gameState.selectedScenario?.id == 'classic') ...[
                      _instructionItem(
                        'Arrange 4 grid tiles (A–D), each 2x2, to form a 4x4 grid',
                      ),
                      const SizedBox(height: 6),
                      _instructionItem('Tile A: top-left quadrant'),
                      const SizedBox(height: 6),
                      _instructionItem('Tile B: top-right quadrant'),
                      const SizedBox(height: 6),
                      _instructionItem('Tile C: bottom-left quadrant'),
                      const SizedBox(height: 6),
                      _instructionItem('Tile D: bottom-right quadrant'),
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
      return 'One 2x2 grid tile forms the complete 2x2 grid';
    } else if (gameState.selectedScenario?.id == 'classic') {
      return 'Four 2x2 grid tiles form a 4x4 grid';
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
        // Grid Tile A is the entire 2x2 grid
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGridCell(
                    '1',
                    Colors.blue.shade900,
                    Colors.blue.shade200,
                  ),
                  _buildGridCell(
                    '2',
                    Colors.blue.shade900,
                    Colors.blue.shade200,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGridCell(
                    '3',
                    Colors.blue.shade900,
                    Colors.blue.shade200,
                  ),
                  _buildGridCell(
                    '4',
                    Colors.blue.shade900,
                    Colors.blue.shade200,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _legendItem('Grid Tile A', Colors.blue.shade900),
      ],
    );
  }

  Widget _buildClassicGrid(BuildContext context) {
    // 4 tiles, each 2x2, arranged in a 2x2 tile layout to form a 4x4 grid
    final tileColors = [
      Colors.blue.shade900,
      Colors.green.shade900,
      Colors.purple.shade900,
      Colors.orange.shade900,
    ];
    final tileBorderColors = [
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.purple.shade200,
      Colors.orange.shade200,
    ];
    final labels = ['A', 'B', 'C', 'D'];

    // Cell numbers per tile:
    // Tile A (top-left):    1,2 / 5,6
    // Tile B (top-right):   3,4 / 7,8
    // Tile C (bottom-left): 9,10 / 13,14
    // Tile D (bottom-right):11,12 / 15,16
    final tileCells = [
      [
        ['1', '2'],
        ['5', '6'],
      ],
      [
        ['3', '4'],
        ['7', '8'],
      ],
      [
        ['9', '10'],
        ['13', '14'],
      ],
      [
        ['11', '12'],
        ['15', '16'],
      ],
    ];

    Widget buildTile(int t) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: tileBorderColors[t], width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell(
                  tileCells[t][0][0],
                  labels[t],
                  tileColors[t],
                  tileBorderColors[t],
                ),
                _buildClassicGridCell(
                  tileCells[t][0][1],
                  labels[t],
                  tileColors[t],
                  tileBorderColors[t],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildClassicGridCell(
                  tileCells[t][1][0],
                  labels[t],
                  tileColors[t],
                  tileBorderColors[t],
                ),
                _buildClassicGridCell(
                  tileCells[t][1][1],
                  labels[t],
                  tileColors[t],
                  tileBorderColors[t],
                ),
              ],
            ),
          ],
        ),
      );
    }

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
            // Top row: Tile A (top-left) + Tile B (top-right)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [buildTile(0), const SizedBox(width: 4), buildTile(1)],
            ),
            const SizedBox(height: 4),
            // Bottom row: Tile C (bottom-left) + Tile D (bottom-right)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [buildTile(2), const SizedBox(width: 4), buildTile(3)],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(4, (index) {
            return _legendItem('Tile ${labels[index]}', tileColors[index]);
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
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
            ],
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
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
            ],
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
