import 'package:flutter/material.dart';

/// Types of events that can occur on a tile
enum TileEventType {
  trap('Trap', Icons.dangerous, Colors.red),
  loot('Loot', Icons.diamond, Colors.amber),
  encounter('Encounter', Icons.group, Colors.orange),
  objective('Objective', Icons.flag, Colors.green),
  portal('Portal', Icons.album, Colors.purple),
  hazard('Hazard', Icons.warning, Colors.deepOrange);

  final String displayName;
  final IconData icon;
  final Color color;

  const TileEventType(this.displayName, this.icon, this.color);
}

/// An event on a specific tile
class TileEvent {
  final String id;
  final TileEventType type;
  final String description;
  final bool isRevealed;
  final bool isCompleted;

  const TileEvent({
    required this.id,
    required this.type,
    required this.description,
    this.isRevealed = false,
    this.isCompleted = false,
  });

  /// Create from backend JSON response
  factory TileEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = TileEventType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TileEventType.encounter,
    );

    return TileEvent(
      id: json['id'] as String,
      type: type,
      description: json['description'] as String,
      isRevealed: json['isRevealed'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'isRevealed': isRevealed,
        'isCompleted': isCompleted,
      };

  TileEvent copyWith({
    String? id,
    TileEventType? type,
    String? description,
    bool? isRevealed,
    bool? isCompleted,
  }) {
    return TileEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      isRevealed: isRevealed ?? this.isRevealed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
