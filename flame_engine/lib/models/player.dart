import 'character.dart';
import 'inventory.dart';

/// Represents a player in the game (person with a phone)
class Player {
  /// Player ID (auto-generated)
  final String id;
  
  /// Player name (optional)
  String? name;
  
  /// Character this player controls (null until claimed)
  Character? character;

  /// Player's inventory system
  final Inventory inventory;
  
  /// Has this player completed character selection?
  bool get hasCharacter => character != null;
  
  Player({
    required this.id,
    this.name,
    this.character,
    Inventory? inventory,
  }) : inventory = inventory ?? Inventory();

  /// Claim a character
  void claimCharacter(Character char) {
    character = char;
  }

  /// Release character (if needed)
  void releaseCharacter() {
    character = null;
  }

  /// Get effective attack (base + equipment bonuses)
  int get effectiveAttack {
    if (character == null) return 0;
    final bonus = inventory.getTotalStats()['attack'] ?? 0;
    return character!.attack + bonus;
  }

  /// Get effective defense (base + equipment bonuses)
  int get effectiveDefense {
    if (character == null) return 0;
    final bonus = inventory.getTotalStats()['defense'] ?? 0;
    return character!.defense + bonus;
  }

  /// Get effective max health (base + equipment bonuses)
  int get effectiveMaxHealth {
    if (character == null) return 0;
    final bonus = inventory.getTotalStats()['maxHealth'] ?? 0;
    return character!.maxHealth + bonus;
  }

  @override
  String toString() {
    final playerName = name ?? 'Player $id';
    if (hasCharacter) {
      return '$playerName (${character!.name})';
    }
    return '$playerName (no character)';
  }
}
