import 'package:flame/components.dart';
import '../services/mock_nfc_data.dart'
    show
        kControllerNfcTagId,
        kControllerUuid,
        kEngineerNfcTagId,
        kEngineerUuid,
        kStrikerNfcTagId,
        kStrikerUuid,
        kVanguardNfcTagId,
        kVanguardUuid;

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
    int? maxHealth,
    int? attack,
    int? defense,
  })  : maxHealth = maxHealth ?? characterClass.maxHealth,
        attack = attack ?? characterClass.attack,
        defense = defense ?? characterClass.defense,
        health = maxHealth ?? characterClass.maxHealth,
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
  controller,
  engineer,
  striker,
  vanguard;

  String get name {
    switch (this) {
      case CharacterClass.controller:
        return 'Controller';
      case CharacterClass.engineer:
        return 'Engineer';
      case CharacterClass.striker:
        return 'Striker';
      case CharacterClass.vanguard:
        return 'Vanguard';
    }
  }

  int get color {
    switch (this) {
      case CharacterClass.controller:
        return 0xFFFFFFFF; // White
      case CharacterClass.engineer:
        return 0xFF2196F3; // Blue
      case CharacterClass.striker:
        return 0xFF9C27B0; // Purple
      case CharacterClass.vanguard:
        return 0xFFF44336; // Red
    }
  }

  /// Get NFC tag ID for this character class
  String get nfcTagId {
    switch (this) {
      case CharacterClass.controller:
        return kControllerNfcTagId;
      case CharacterClass.engineer:
        return kEngineerNfcTagId;
      case CharacterClass.striker:
        return kStrikerNfcTagId;
      case CharacterClass.vanguard:
        return kVanguardNfcTagId;
    }
  }

  /// Asset path for the character image
  String get imagePath {
    switch (this) {
      case CharacterClass.controller:
        return 'assets/images/characters/ControllerSingle.png';
      case CharacterClass.engineer:
        return 'assets/images/characters/EngineerSingle.png';
      case CharacterClass.striker:
        return 'assets/images/characters/StrikerSingle.png';
      case CharacterClass.vanguard:
        return 'assets/images/characters/VanguardSingle.png';
    }
  }

  /// UUID for this character class (used for persistent identity)
  String? get uuid {
    switch (this) {
      case CharacterClass.controller:
        return kControllerUuid;
      case CharacterClass.engineer:
        return kEngineerUuid;
      case CharacterClass.striker:
        return kStrikerUuid;
      case CharacterClass.vanguard:
        return kVanguardUuid;
    }
  }

  /// Base max health for this character class
  int get maxHealth {
    switch (this) {
      case CharacterClass.controller:
        return 10;
      case CharacterClass.engineer:
        return 10;
      case CharacterClass.striker:
        return 8;
      case CharacterClass.vanguard:
        return 14;
    }
  }

  /// Base attack for this character class
  int get attack {
    switch (this) {
      case CharacterClass.controller:
        return 2;
      case CharacterClass.engineer:
        return 3;
      case CharacterClass.striker:
        return 6;
      case CharacterClass.vanguard:
        return 3;
    }
  }

  /// Base defense for this character class
  int get defense {
    switch (this) {
      case CharacterClass.controller:
        return 4;
      case CharacterClass.engineer:
        return 3;
      case CharacterClass.striker:
        return 1;
      case CharacterClass.vanguard:
        return 3;
    }
  }
}
