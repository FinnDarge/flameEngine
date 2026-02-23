import 'character.dart';

/// Represents a player in the game (person with a phone)
class Player {
  /// Player ID (auto-generated)
  final String id;
  
  /// Player name (optional)
  String? name;
  
  /// Character this player controls (null until claimed)
  Character? character;
  
  /// Has this player completed character selection?
  bool get hasCharacter => character != null;
  
  Player({
    required this.id,
    this.name,
    this.character,
  });

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
