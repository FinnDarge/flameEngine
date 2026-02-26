import 'package:flutter/material.dart';

/// Types of events that can occur on a tile.
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

class TileEventChoice {
  final String id;
  final String label;
  final String? linkedOutcomeId;

  const TileEventChoice({
    required this.id,
    required this.label,
    this.linkedOutcomeId,
  });

  factory TileEventChoice.fromJson(Map<String, dynamic> json) {
    return TileEventChoice(
      id: json['id'] as String,
      label: json['label'] as String,
      linkedOutcomeId: json['linkedOutcomeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'linkedOutcomeId': linkedOutcomeId,
      };
}

class TileEventStateDelta {
  final int hp;
  final int energy;
  final int credits;
  final int instability;

  const TileEventStateDelta({
    this.hp = 0,
    this.energy = 0,
    this.credits = 0,
    this.instability = 0,
  });

  factory TileEventStateDelta.fromJson(Map<String, dynamic> json) {
    return TileEventStateDelta(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      energy: (json['energy'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      instability: (json['instability'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'hp': hp,
        'energy': energy,
        'credits': credits,
        'instability': instability,
      };
}

class TileEventOutcome {
  final String id;
  final String text;
  final bool isDefault;
  final TileEventStateDelta stateDelta;

  const TileEventOutcome({
    required this.id,
    required this.text,
    this.isDefault = false,
    this.stateDelta = const TileEventStateDelta(),
  });

  factory TileEventOutcome.fromJson(Map<String, dynamic> json) {
    return TileEventOutcome(
      id: json['id'] as String,
      text: json['text'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      stateDelta: json['stateDelta'] is Map<String, dynamic>
          ? TileEventStateDelta.fromJson(
              json['stateDelta'] as Map<String, dynamic>,
            )
          : const TileEventStateDelta(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDefault': isDefault,
        'stateDelta': stateDelta.toJson(),
      };
}

/// An event on a specific tile.
class TileEvent {
  final String id;
  final TileEventType type;
  final String title;
  final String flavor;
  final List<TileEventChoice> choices;
  final List<TileEventOutcome> outcomes;
  final TileEventStateDelta stateDelta;
  final bool isRevealed;
  final bool isCompleted;

  TileEvent({
    required this.id,
    required this.type,
    String? title,
    String? flavor,
    @Deprecated('Use flavor instead.') String? description,
    this.choices = const [],
    this.outcomes = const [],
    this.stateDelta = const TileEventStateDelta(),
    this.isRevealed = false,
    this.isCompleted = false,
  })  : title = title ?? type.displayName,
        flavor = flavor ?? description ?? '';

  /// Backwards-compatible alias used by existing UI logs.
  String get description => flavor;

  /// Create from backend JSON response.
  factory TileEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? '').toString();
    final type = TileEventType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TileEventType.encounter,
    );

    final flavor = (json['flavor'] ?? json['description'] ?? '') as String;
    final title = (json['title'] ?? type.displayName) as String;

    return TileEvent(
      id: json['id'] as String,
      type: type,
      title: title,
      flavor: flavor,
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TileEventChoice.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      outcomes: (json['outcomes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TileEventOutcome.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      stateDelta: json['stateDelta'] is Map<String, dynamic>
          ? TileEventStateDelta.fromJson(
              json['stateDelta'] as Map<String, dynamic>,
            )
          : const TileEventStateDelta(),
      isRevealed: json['isRevealed'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'flavor': flavor,
        'description': flavor,
        'choices': choices.map((choice) => choice.toJson()).toList(),
        'outcomes': outcomes.map((outcome) => outcome.toJson()).toList(),
        'stateDelta': stateDelta.toJson(),
        'isRevealed': isRevealed,
        'isCompleted': isCompleted,
      };

  TileEvent copyWith({
    String? id,
    TileEventType? type,
    String? title,
    String? flavor,
    List<TileEventChoice>? choices,
    List<TileEventOutcome>? outcomes,
    TileEventStateDelta? stateDelta,
    bool? isRevealed,
    bool? isCompleted,
  }) {
    return TileEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      flavor: flavor ?? this.flavor,
      choices: choices ?? this.choices,
      outcomes: outcomes ?? this.outcomes,
      stateDelta: stateDelta ?? this.stateDelta,
      isRevealed: isRevealed ?? this.isRevealed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
