/// Represents a game scenario/difficulty level
class GameScenario {
  final String id;
  final String name;
  final String description;
  final int gridSize;
  final int enemyCount;
  final int difficultyLevel; // 1-5

  const GameScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.gridSize,
    required this.enemyCount,
    required this.difficultyLevel,
  });

  /// Built-in scenarios
  static const List<GameScenario> predefined = [
    GameScenario(
      id: 'tutorial',
      name: 'Tutorial',
      description: 'Learn the basics\n2x2 grid, no enemies',
      gridSize: 2,
      enemyCount: 0,
      difficultyLevel: 1,
    ),
    GameScenario(
      id: 'classic',
      name: 'Classic',
      description: 'Classic adventure\n4x4 grid, balanced challenge',
      gridSize: 4,
      enemyCount: 4,
      difficultyLevel: 2,
    ),
  ];

  /// Get a scenario by ID
  static GameScenario? getById(String id) {
    try {
      return predefined.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
