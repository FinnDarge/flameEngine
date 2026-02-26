import 'package:flutter/material.dart';

/// Types of enemies that can appear in the dungeon
enum EnemyType {
  behemoth('Behemoth', 'characters/BehemothSingle.png', 100, 15, 8),
  planetaryAvatar('Planetary Avatar', 'characters/PlanetaryAvatarSingle.png', 150, 20, 12),
  sporeling('Sporeling', 'characters/SporelingSingle.png', 30, 8, 3),
  synapse('Synapse', 'characters/SynapseSingle.png', 50, 12, 5);

  final String displayName;
  final String imagePath;
  final int baseHealth;
  final int baseAttack;
  final int baseDefense;

  const EnemyType(
    this.displayName,
    this.imagePath,
    this.baseHealth,
    this.baseAttack,
    this.baseDefense,
  );
}

/// An enemy instance in the game
class Enemy {
  final String id;
  final EnemyType type;
  int health;
  final int maxHealth;
  final int attack;
  final int defense;

  Enemy({
    required this.id,
    required this.type,
    int? health,
    int? maxHealth,
    int? attack,
    int? defense,
  })  : maxHealth = maxHealth ?? type.baseHealth,
        health = health ?? (maxHealth ?? type.baseHealth),
        attack = attack ?? type.baseAttack,
        defense = defense ?? type.baseDefense;

  /// Create from backend JSON response
  factory Enemy.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = EnemyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => EnemyType.sporeling,
    );

    return Enemy(
      id: json['id'] as String,
      type: type,
      health: json['health'] as int?,
      maxHealth: json['maxHealth'] as int?,
      attack: json['attack'] as int?,
      defense: json['defense'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'health': health,
        'maxHealth': maxHealth,
        'attack': attack,
        'defense': defense,
      };

  bool get isAlive => health > 0;

  /// Enemy color for UI
  Color get color {
    switch (type) {
      case EnemyType.behemoth:
        return const Color(0xFFFF4444); // Red
      case EnemyType.planetaryAvatar:
        return const Color(0xFFAA00FF); // Purple
      case EnemyType.sporeling:
        return const Color(0xFF44FF44); // Green
      case EnemyType.synapse:
        return const Color(0xFF00AAFF); // Cyan
    }
  }
}
