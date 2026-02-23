import 'package:flutter/material.dart';
import '../models/game_scenario.dart';
import '../models/game_state.dart';
import '../widgets/token_and_board_app_bar.dart';

/// Screen for selecting a game scenario
class ScenarioSelectionScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onScenarioSelected;

  const ScenarioSelectionScreen({
    super.key,
    required this.gameState,
    required this.onScenarioSelected,
  });

  @override
  State<ScenarioSelectionScreen> createState() =>
      _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelectionScreen> {
  GameScenario? selectedScenario;

  void _selectScenario(GameScenario scenario) {
    setState(() {
      selectedScenario = scenario;
    });
  }

  void _confirmSelection() {
    if (selectedScenario != null) {
      widget.gameState.selectedScenario = selectedScenario;
      // Route to puzzle grid setup for tutorial and classic scenarios
      if (selectedScenario!.id == 'tutorial' ||
          selectedScenario!.id == 'classic') {
        widget.gameState.phase = GamePhase.puzzleGridSetup;
      } else {
        widget.gameState.phase = GamePhase.characterSelection;
      }
      widget.onScenarioSelected();
    }
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.terrain, size: 64, color: Colors.blue.shade300),
                const SizedBox(height: 16),
                Text(
                  'Token & Board Adventures',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a scenario to begin',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Scenario List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: GameScenario.predefined.length,
              itemBuilder: (context, index) {
                final scenario = GameScenario.predefined[index];
                final isSelected = selectedScenario?.id == scenario.id;
                final diffColor = _getDifficultyColor(scenario.difficultyLevel);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectScenario(scenario),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? diffColor.withOpacity(0.2)
                              : const Color(0xFF2d2d2d),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? diffColor : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Difficulty Badge
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: diffColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: diffColor, width: 2),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: diffColor,
                                      size: 24,
                                    ),
                                    Text(
                                      scenario.difficultyLevel.toString(),
                                      style: TextStyle(
                                        color: diffColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Scenario Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scenario.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scenario.description,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: diffColor.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${scenario.gridSize}x${scenario.gridSize} Grid',
                                          style: TextStyle(
                                            color: diffColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${scenario.enemyCount} Enemies',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Selection Indicator
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: diffColor,
                                size: 32,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: selectedScenario != null
                      ? _confirmSelection
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
