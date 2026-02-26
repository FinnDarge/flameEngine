import '../models/tile_event.dart';

/// Seeded event cards grouped by instability tiers.
class EventsSeed {
  static final Map<String, List<TileEvent>> byInstabilityTier = {
    '0-3': _lowInstability,
    '4-6': _midInstability,
    '7-9': _highInstability,
  };

  static final List<TileEvent> _lowInstability = [
    TileEvent(
      id: 'loot_supply_cache',
      type: TileEventType.loot,
      title: 'Supply Cache',
      flavor: 'A sealed crate hums quietly in the dim corridor.',
      choices: [
        TileEventChoice(id: 'open', label: 'Open the crate'),
        TileEventChoice(id: 'mark', label: 'Mark it and move on'),
      ],
      outcomes: [
        TileEventOutcome(
          id: 'safe_loot',
          text: 'You recover salvageable supplies.',
          isDefault: true,
          stateDelta: TileEventStateDelta(credits: 2),
        ),
        TileEventOutcome(
          id: 'spoiled_loot',
          text: 'Most contents are ruined, but a battery survives.',
          stateDelta: TileEventStateDelta(energy: 1),
        ),
      ],
      stateDelta: TileEventStateDelta(credits: 1),
    ),
    TileEvent(
      id: 'objective_signal_ping',
      type: TileEventType.objective,
      title: 'Signal Ping',
      flavor: 'A weak telemetry ping appears on your scanner.',
      choices: [TileEventChoice(id: 'trace', label: 'Trace the signal')],
      outcomes: [
        TileEventOutcome(
          id: 'progress',
          text: 'The team refines the objective coordinates.',
          isDefault: true,
          stateDelta: TileEventStateDelta(energy: 1),
        ),
      ],
      stateDelta: TileEventStateDelta(energy: 1),
    ),
  ];

  static final List<TileEvent> _midInstability = [
    TileEvent(
      id: 'hazard_coolant_leak',
      type: TileEventType.hazard,
      title: 'Coolant Leak',
      flavor: 'The floor is slick with freezing coolant vapor.',
      choices: [
        TileEventChoice(id: 'cross', label: 'Cross carefully'),
        TileEventChoice(id: 'reroute', label: 'Reroute power first'),
      ],
      outcomes: [
        TileEventOutcome(
          id: 'slip',
          text: 'You slip, but stay upright after a rough impact.',
          isDefault: true,
          stateDelta: TileEventStateDelta(hp: -1),
        ),
        TileEventOutcome(
          id: 'stabilized',
          text: 'The coolant flow stabilizes temporarily.',
          stateDelta: TileEventStateDelta(energy: -1, instability: -1),
        ),
      ],
      stateDelta: TileEventStateDelta(hp: -1),
    ),
    TileEvent(
      id: 'encounter_scavenger_patrol',
      type: TileEventType.encounter,
      title: 'Scavenger Patrol',
      flavor: 'A hostile patrol emerges from maintenance shafts.',
      choices: [TileEventChoice(id: 'ambush', label: 'Set an ambush')],
      outcomes: [
        TileEventOutcome(
          id: 'skirmish',
          text: 'A brief skirmish drains your resources.',
          isDefault: true,
          stateDelta: TileEventStateDelta(hp: -1, credits: 1),
        ),
      ],
      stateDelta: TileEventStateDelta(hp: -1),
    ),
  ];

  static final List<TileEvent> _highInstability = [
    TileEvent(
      id: 'trap_phase_mine',
      type: TileEventType.trap,
      title: 'Phase Mine',
      flavor: 'A hidden mine flickers between dimensions.',
      choices: [
        TileEventChoice(id: 'disarm', label: 'Attempt disarm'),
        TileEventChoice(id: 'retreat', label: 'Retreat and detour'),
      ],
      outcomes: [
        TileEventOutcome(
          id: 'detonate',
          text: 'The mine detonates before you can react.',
          isDefault: true,
          stateDelta: TileEventStateDelta(hp: -2, instability: 1),
        ),
        TileEventOutcome(
          id: 'clean_disarm',
          text: 'You disarm it and salvage rare components.',
          stateDelta: TileEventStateDelta(credits: 3, instability: -1),
        ),
      ],
      stateDelta: TileEventStateDelta(hp: -2),
    ),
    TileEvent(
      id: 'portal_void_tear',
      type: TileEventType.portal,
      title: 'Void Tear',
      flavor: 'Reality bends around a widening portal tear.',
      choices: [TileEventChoice(id: 'seal', label: 'Seal the tear')],
      outcomes: [
        TileEventOutcome(
          id: 'containment',
          text: 'Containment is partial; pressure remains high.',
          isDefault: true,
          stateDelta: TileEventStateDelta(instability: 1, energy: -1),
        ),
      ],
      stateDelta: TileEventStateDelta(instability: 1),
    ),
  ];
}
