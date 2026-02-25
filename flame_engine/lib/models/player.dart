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

  @override
  String toString() {
    final playerName = name ?? 'Player $id';
    if (hasCharacter) {
      return '$playerName (${character!.name})';
    }
    return '$playerName (no character)';
  }
}
