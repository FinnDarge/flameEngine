import 'package:flame/components.dart';
import '../services/mock_nfc_data.dart'
    show kWizardCharacterName, kWizardNfcTagId, kWizardUuid, kWarriorNfcTagId;

/// Represents a playable character in the game
class Character {
  /// Character type/class
  final CharacterClass characterClass;

  /// Unique NFC tag ID for this character figure
  final String nfcTagId;

  /// Current grid position (row, col)
  Vector2 position;

  /// Character stats
  int health;
  final int maxHealth;
  int attack;
  int defense;

  /// Inventory - items collected
  final List<String> inventory;

  /// Is this character defeated?
  bool isDefeated;

  Character({
    required this.characterClass,
    required this.nfcTagId,
    required this.position,
    this.maxHealth = 10,
    this.attack = 3,
    this.defense = 1,
  }) : health = maxHealth,
       inventory = [],
       isDefeated = false;

  /// Take damage
  void takeDamage(int damage) {
    final actualDamage = (damage - defense).clamp(0, 999);
    health = (health - actualDamage).clamp(0, maxHealth);
    if (health <= 0) {
      isDefeated = true;
    }
  }

  /// Heal character
  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
    if (health > 0) {
      isDefeated = false;
    }
  }

  /// Add item to inventory
  void addItem(String item) {
    inventory.add(item);
  }

  /// Check if character has an item
  bool hasItem(String item) {
    return inventory.contains(item);
  }

  /// Remove item from inventory
  bool removeItem(String item) {
    return inventory.remove(item);
  }

  /// Get character color for UI
  int get color => characterClass.color;

  /// Get character name
  String get name => characterClass.name;

  @override
  String toString() {
    return '$name at ($position) - HP: $health/$maxHealth';
  }
}

/// Character classes/types
enum CharacterClass {
  warrior,
  wizard;

  String get name {
    switch (this) {
      case CharacterClass.warrior:
        return 'Warrior';
      case CharacterClass.wizard:
        return kWizardCharacterName;
    }
  }

  int get color {
    switch (this) {
      case CharacterClass.warrior:
        return 0xFFFF4444; // Red
      case CharacterClass.wizard:
        return 0xFFAA44FF; // Purple
    }
  }

  /// Get NFC tag ID for this character class
  String get nfcTagId {
    switch (this) {
      case CharacterClass.warrior:
        return kWarriorNfcTagId;
      case CharacterClass.wizard:
        return kWizardNfcTagId;
    }
  }

  /// Asset path for the character image
  String get imagePath {
    switch (this) {
      case CharacterClass.warrior:
        return 'assets/images/characters/warrior.jpg';
      case CharacterClass.wizard:
        return 'assets/images/characters/wizard.jpg';
    }
  }

  /// UUID for this character class (used for persistent identity)
  String? get uuid {
    switch (this) {
      case CharacterClass.wizard:
        return kWizardUuid;
      default:
        return null;
    }
  }
}
