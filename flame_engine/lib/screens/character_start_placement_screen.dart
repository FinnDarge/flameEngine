import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

String _characterAsset(CharacterClass? cls) =>
    cls?.imagePath ?? 'assets/images/characters/ControllerSingle.png';

/// Combined screen that shows:
///   Step 1 — arrange the physical grid tiles
///   Step 2 — place the character figure on the starting tile
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

  bool get _isTutorial {
    final apiGame = gameState.selectedApiGame;
    if (apiGame != null) return apiGame.name.toLowerCase().contains('tutorial');
    return gameState.selectedScenario?.id == 'tutorial';
  }

  @override
  Widget build(BuildContext context) {
    final character = gameState.localPlayer.character;
    final characterName = character?.name ?? 'Your Character';
    final characterColor = character != null
        ? Color(character.characterClass.color)
        : Colors.deepPurple;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: TokenAndBoardAppBar(onBackPressed: onBack),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Game Setup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Complete both steps below before starting',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            // Step 1: Grid tile arrangement
            _stepCard(
              context,
              step: 1,
              title: 'Arrange Your Grid Tiles',
              subtitle: _isTutorial
                  ? 'One 2x2 grid tile forms the complete game board'
                  : 'Four 2x2 grid tiles form a 4x4 game board',
              color: Colors.blue.shade700,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isTutorial
                        ? _buildSetupTutorialGrid()
                        : _buildSetupClassicGrid(),
                  ),
                  _instructionsBox(
                    title: 'Setup Instructions:',
                    items: _isTutorial
                        ? [
                            'Place Grid Tile A (blue) — the complete 2x2 game board',
                            'Tap "Start Game" below when arranged',
                          ]
                        : [
                            'Arrange 4 grid tiles (A-D), each 2x2, to form a 4x4 board',
                            'Tile A: top-left  |  Tile B: top-right',
                            'Tile C: bottom-left  |  Tile D: bottom-right',
                            'Tap "Start Game" below when arranged',
                          ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Step 2: Character placement
            _stepCard(
              context,
              step: 2,
              title: 'Place Your Character',
              subtitle: 'Put your $characterName figure on the starting tile',
              color: Colors.green.shade700,
              child: Column(
                children: [
                  // Character badge
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                              _characterAsset(character?.characterClass),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _isTutorial
                        ? _buildPlacementTutorialGrid()
                        : _buildPlacementClassicGrid(),
                  ),

                  _instructionsBox(
                    title: 'Placement Instructions:',
                    items: [
                      'Locate position 1 — the top-left cell of the board',
                      'Place your $characterName figure on that tile',
                    ],
                  ),
                ],
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Layout helpers

  Widget _stepCard(
    BuildContext context, {
    required int step,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color,
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }

  Widget _instructionsBox({
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 5, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1 grid diagrams (tile arrangement, no character)

  Widget _buildSetupTutorialGrid() {
    return Column(
      children: [
        const Text(
          'Complete 2x2 Game Board',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200, width: 3),
            image: const DecorationImage(
              image: AssetImage('assets/images/tiles/tileA.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _setupCell('1', Colors.blue.shade200),
                  _setupCell('2', Colors.blue.shade200),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _setupCell('3', Colors.blue.shade200),
                  _setupCell('4', Colors.blue.shade200),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _legendItem('Grid Tile A', Colors.blue.shade900),
      ],
    );
  }

  Widget _buildSetupClassicGrid() {
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
    const tileImages = [
      'assets/images/tiles/tileA.jpg',
      'assets/images/tiles/tileB.jpg',
      'assets/images/tiles/tileC.jpg',
      'assets/images/tiles/tileD.jpg',
    ];
    final labels = ['A', 'B', 'C', 'D'];
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
          image: DecorationImage(
            image: AssetImage(tileImages[t]),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(2, (col) {
                return _setupCellSmall(
                  tileCells[t][row][col],
                  tileBorderColors[t],
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
          'Complete 4x4 Game Board',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: List.generate(
            4,
            (i) => _legendItem('Tile ${labels[i]}', tileColors[i]),
          ),
        ),
      ],
    );
  }

  // Step 2 grid diagrams (with character on starting cell)

  Widget _buildPlacementTutorialGrid() {
    return Column(
      children: [
        const Text(
          'Starting Position on 2x2 Board',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200, width: 3),
            image: const DecorationImage(
              image: AssetImage('assets/images/tiles/tileA.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _placementCell('1', Colors.blue.shade200, isStart: true),
                  _placementCell('2', Colors.blue.shade200),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _placementCell('3', Colors.blue.shade200),
                  _placementCell('4', Colors.blue.shade200),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _startLegendItem(),
      ],
    );
  }

  Widget _buildPlacementClassicGrid() {
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

    const tileImages = [
      'assets/images/tiles/tileA.jpg',
      'assets/images/tiles/tileB.jpg',
      'assets/images/tiles/tileC.jpg',
      'assets/images/tiles/tileD.jpg',
    ];

    Widget buildTile(int t) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: tileBorderColors[t], width: 3),
          image: DecorationImage(
            image: AssetImage(tileImages[t]),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(2, (col) {
                return _placementCellSmall(
                  tileCells[t][row][col],
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
          'Starting Position on 4x4 Board',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        _startLegendItem(),
      ],
    );
  }

  // Cell widgets

  Widget _setupCell(String number, Color borderColor) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        color: Colors.transparent,
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setupCellSmall(String number, Color borderColor) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        color: Colors.transparent,
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placementCell(
    String number,
    Color borderColor, {
    bool isStart = false,
  }) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(
          color: isStart ? Colors.greenAccent : borderColor,
          width: isStart ? 3 : 2,
        ),
        color: isStart
            ? Colors.greenAccent.withOpacity(0.25)
            : Colors.transparent,
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
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    _characterAsset(
                      gameState.localPlayer.character?.characterClass,
                    ),
                    fit: BoxFit.cover,
                  ),
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
                  fontSize: isStart ? 12 : 24,
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

  Widget _placementCellSmall(
    String number,
    Color borderColor, {
    bool isStart = false,
  }) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isStart ? Colors.greenAccent : borderColor,
          width: isStart ? 2.5 : 1.5,
        ),
        color: isStart
            ? Colors.greenAccent.withOpacity(0.25)
            : Colors.transparent,
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
                  width: 28,
                  height: 28,
                  child: Image.asset(
                    _characterAsset(
                      gameState.localPlayer.character?.characterClass,
                    ),
                    fit: BoxFit.cover,
                  ),
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
                  fontSize: isStart ? 8 : 14,
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

  // Legend helpers

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _startLegendItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.greenAccent, width: 2),
            color: Colors.blue.shade900.withGreen(80),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              _characterAsset(gameState.localPlayer.character?.characterClass),
              fit: BoxFit.cover,
            ),
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
