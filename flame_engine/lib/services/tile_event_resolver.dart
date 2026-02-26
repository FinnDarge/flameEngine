import 'dart:math';

import '../data/events_seed.dart';
import '../models/tile_event.dart';

/// Toggle with `--dart-define=MOCK_EVENT_RANDOMNESS=true`.
const bool kMockEventRandomness = bool.fromEnvironment('MOCK_EVENT_RANDOMNESS');

class ResolvedTileEvent {
  final TileEvent event;
  final TileEventOutcome selectedOutcome;

  const ResolvedTileEvent({required this.event, required this.selectedOutcome});
}

class TileEventResolver {
  final Random _random;

  TileEventResolver({Random? random}) : _random = random ?? Random();

  ResolvedTileEvent? resolve({
    required int instability,
    TileEventType? eventType,
    bool? useMockRandomness,
  }) {
    final candidates = _eventsForInstability(instability)
        .where((event) => eventType == null || event.type == eventType)
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    final event = _pickEvent(candidates, useMockRandomness: useMockRandomness);
    final outcome = _pickOutcome(event, useMockRandomness: useMockRandomness);

    return ResolvedTileEvent(event: event, selectedOutcome: outcome);
  }

  List<TileEvent> _eventsForInstability(int instability) {
    if (instability <= 3) {
      return EventsSeed.byInstabilityTier['0-3'] ?? const [];
    }
    if (instability <= 6) {
      return EventsSeed.byInstabilityTier['4-6'] ?? const [];
    }
    return EventsSeed.byInstabilityTier['7-9'] ?? const [];
  }

  TileEvent _pickEvent(
    List<TileEvent> candidates, {
    bool? useMockRandomness,
  }) {
    if (_shouldUseRandomness(useMockRandomness)) {
      return candidates[_random.nextInt(candidates.length)];
    }
    return candidates.first;
  }

  TileEventOutcome _pickOutcome(
    TileEvent event, {
    bool? useMockRandomness,
  }) {
    final outcomes = event.outcomes;
    if (outcomes.isEmpty) {
      return TileEventOutcome(
        id: '${event.id}_default_outcome',
        text: event.flavor,
        isDefault: true,
        stateDelta: event.stateDelta,
      );
    }

    if (_shouldUseRandomness(useMockRandomness)) {
      return outcomes[_random.nextInt(outcomes.length)];
    }

    return outcomes.firstWhere(
      (outcome) => outcome.isDefault,
      orElse: () => outcomes.first,
    );
  }

  bool _shouldUseRandomness(bool? override) {
    if (override != null) {
      return override;
    }
    return kMockEventRandomness;
  }
}
