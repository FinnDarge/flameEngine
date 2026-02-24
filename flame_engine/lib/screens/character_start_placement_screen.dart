import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

const _characterAsset = 'assets/images/characters/wizard.jpg';

/// Screen instructing the player to physically place their character figure
/// on the starting tile of the physical grid — shown after character selection
/// and before gameplay begins.
class CharacterStartPlacementScreen extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onReady;
  final VoidCallback onBack;

  const CharacterStartPlacementScreen({
    super.key,
    required this.gameState,
    required this.onReady,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final character = gameState.localPlayer.character;
    final characterName = character?.name ?? 'Your Character';
    final characterColor = character != null
        ? Color(character.characterClass.color)
        : Colors.deepPurple;
    final isClassic = gameState.selectedScenario?.id == 'classic';

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: TokenAndBoardAppBar(onBackPressed: onBack),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Text(
                    'Place Your Character',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Put your $characterName figure on the starting tile',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Character badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: characterColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: characterColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        _characterAsset,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          characterName,
                          style: TextStyle(
                            color: characterColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (character != null)
                          Text(
                            character.characterClass.name,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Grid diagram with starting position
            Padding(
              padding: const EdgeInsets.all(24),
              child: isClassic
                  ? _buildClassicGrid(context)
                  : _buildTutorialGrid(context),
            ),

            // Instructions box
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
                    const Text(
                      'Placement Instructions:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _instructionItem(
                      'Locate position 1 — the top-left cell of the grid',
                    ),
                    const SizedBox(height: 6),
                    _instructionItem(
                      'Place your $characterName figure on that tile',
                    ),
                    const SizedBox(height: 6),
                    _instructionItem('Tap "Start Game" when ready'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Start Game button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReady,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

  // ── Grid diagrams ────────────────────────────────────────────────────────

  Widget _buildTutorialGrid(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Starting Position on 2×2 Grid',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
                    isStart: true,
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
        _startLegendItem(),
      ],
    );
  }

  Widget _buildClassicGrid(BuildContext context) {
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
          children: List.generate(2, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(2, (col) {
                final cellNum = tileCells[t][row][col];
                return _buildClassicCell(
                  cellNum,
                  tileColors[t],
                  tileBorderColors[t],
                  isStart: t == 0 && row == 0 && col == 0,
                );
              }),
            );
          }),
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Starting Position on 4×4 Grid',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [buildTile(0), const SizedBox(width: 4), buildTile(1)],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [buildTile(2), const SizedBox(width: 4), buildTile(3)],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _startLegendItem(),
      ],
    );
  }

  // ── Cell widgets ─────────────────────────────────────────────────────────

  Widget _buildGridCell(
    String number,
    Color bgColor,
    Color borderColor, {
    bool isStart = false,
  }) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(
          color: isStart ? Colors.greenAccent : borderColor,
          width: isStart ? 3 : 2,
        ),
        color: isStart ? bgColor.withGreen(80) : bgColor,
        boxShadow: isStart
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isStart)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Image.asset(_characterAsset, fit: BoxFit.cover),
                ),
              ),
            ),
          Align(
            alignment: isStart ? Alignment.bottomRight : Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isStart ? 14 : 28,
                  shadows: const [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicCell(
    String number,
    Color bgColor,
    Color borderColor, {
    bool isStart = false,
  }) {
    return Container(
      width: 65,
      height: 65,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isStart ? Colors.greenAccent : borderColor,
          width: isStart ? 2.5 : 1.5,
        ),
        color: isStart ? bgColor.withGreen(80) : bgColor,
        boxShadow: isStart
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isStart)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(_characterAsset, fit: BoxFit.cover),
                ),
              ),
            ),
          Align(
            alignment: isStart ? Alignment.bottomRight : Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isStart ? 9 : 16,
                  shadows: const [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────────────────

  Widget _instructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 6, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _startLegendItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.greenAccent, width: 2),
            color: Colors.blue.shade900.withGreen(80),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(_characterAsset, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Your Starting Position',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
