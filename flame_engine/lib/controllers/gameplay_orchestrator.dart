import 'package:flame/components.dart';

import '../models/character.dart';
import '../models/game_state.dart';
import '../models/grid_tile.dart';
import '../models/tile_event.dart';
import '../services/session_api_service.dart';
import '../services/tile_event_resolver.dart';
import '../services/tile_input_provider.dart';

/// Coordinates a single field activation flow during gameplay.
class GameplayOrchestrator {
  final GameState gameState;
  final void Function(Character character) refreshBoardAfterMovement;
  final void Function(int row, int col) completeEvent;
  final void Function(int row, int col, TileEvent event)? promptEventResolution;
  final List<String> _timeline = [];
  final TileEventResolver _tileEventResolver = TileEventResolver();

  GameplayOrchestrator({
    required this.gameState,
    required this.refreshBoardAfterMovement,
    required this.completeEvent,
    this.promptEventResolution,
  });

  Future<void> onFieldActivated(String fieldId, TileInputSource source) async {
    _timeline.clear();
    _log('Activation received from ${source.name}: $fieldId');

    final context = await _validate(fieldId);
    if (context == null) {
      _flushTimeline();
      return;
    }

    final moved = _applyReducers(context);

    if (moved) {
      await _resolveEventOrCombat(context);
      if (context.tile.event != null && !context.tile.event!.isCompleted) {
        promptEventResolution?.call(context.row, context.col, context.tile.event!);
        _log('Queued event resolution UI for tile (${context.row}, ${context.col}).');
      }
      refreshBoardAfterMovement(context.character);
      _advanceTurnAndRound();
      _checkEndgame();
    }

    _flushTimeline();
  }

  Future<_FieldActivationContext?> _validate(String fieldId) async {
    if (gameState.phase != GamePhase.playing) {
      _log('Validation failed: game is not in playing phase.');
      return null;
    }

    final character = gameState.localPlayer.character;
    if (character == null) {
      _log('Validation failed: no character assigned to local player.');
      return null;
    }

    if (!gameState.isLocalPlayerTurn) {
      _log(
        'Validation failed: not your turn (current: ${gameState.currentTurnCharacter?.name ?? "unknown"}).',
      );
      return null;
    }

    final parts = fieldId.split('_');
    if (parts.length != 3 || parts[0] != 'cell') {
      _log('Validation failed: invalid field id format.');
      return null;
    }

    final row = int.tryParse(parts[1]);
    final col = int.tryParse(parts[2]);
    if (row == null || col == null) {
      _log('Validation failed: row/col could not be parsed.');
      return null;
    }

    final destination = Vector2((col - 1).toDouble(), (row - 1).toDouble());
    final tile = gameState.grid.getTile(row - 1, col - 1);
    if (tile == null) {
      _log('Validation failed: destination tile does not exist.');
      return null;
    }

    final remoteValidated = await _validateAgainstBackendIfNeeded(gameState, tile);
    if (!remoteValidated) {
      _log('Validation failed: backend rejected movement.');
      return null;
    }

    _log('Validation passed for ${character.name} -> ($row, $col).');
    return _FieldActivationContext(
      character: character,
      destination: destination,
      tile: tile,
      row: row - 1,
      col: col - 1,
    );
  }

  Future<bool> _validateAgainstBackendIfNeeded(
    GameState gameState,
    GridTile tile,
  ) async {
    if (gameState.sessionId == null ||
        gameState.playerAccessToken == null ||
        tile.fieldUuid == null) {
      _log('Validation source: local-only.');
      return true;
    }

    _log('Validation source: backend walkToField call.');
    final sessionApi = SessionApiService();
    try {
      final result = await sessionApi.walkToField(
        sessionUuid: gameState.sessionId!,
        targetFieldUuid: tile.fieldUuid!,
        userKey: gameState.playerAccessToken!,
      );
      _log('Backend accepted move: ${result.message}');
      return true;
    } catch (e) {
      _log('Backend rejected move: $e');
      return false;
    }
  }

  Future<void> _resolveEventOrCombat(_FieldActivationContext context) async {
    final tile = context.tile;
    if (tile.enemy != null) {
      _log('Combat detected on destination tile (enemy present).');
    }

    if (tile.event == null) {
      final resolved = _tileEventResolver.resolve(
        instability: gameState.eventInstability,
        eventType: tile.enemy != null ? TileEventType.encounter : null,
      );
      if (resolved != null) {
        tile.event = resolved.event.copyWith(isRevealed: true);
        _log('Generated fallback tile event: ${tile.event!.description}');
      }
    }

    if (tile.event != null && !tile.event!.isCompleted) {
      _log('Tile event detected: ${tile.event!.description}');
    } else {
      _log('No unresolved tile event on destination.');
    }
  }

  bool _applyReducers(_FieldActivationContext context) {
    final moved = gameState.moveCharacter(
      context.character,
      context.destination,
    );
    if (!moved) {
      _log('Reducer rejected movement.');
      return false;
    }

    _log('Reducer applied movement state changes.');
    return true;
  }

  void _advanceTurnAndRound() {
    gameState.nextTurn();
    _log('Turn advanced to ${gameState.turnNumber}.');
  }

  void _checkEndgame() {
    if (!gameState.checkVictory()) {
      _log('Endgame check: game continues.');
      return;
    }

    gameState.phase = GamePhase.victory;
    _log('Endgame check: victory reached.');
  }

  void _log(String entry) {
    _timeline.add(entry);
  }

  void _flushTimeline() {
    for (final entry in _timeline) {
      print('🧭 GameplayOrchestrator: $entry');
    }
  }

  TileEventOutcome? resolveEventChoice({
    required Character character,
    required GridTile tile,
    required String choiceId,
  }) {
    final event = tile.event;
    if (event == null || event.isCompleted) {
      _log('Event reducer skipped: no unresolved event on tile.');
      _flushTimeline();
      return null;
    }

    final selectedOutcome = _resolveOutcome(event, choiceId);
    final delta = selectedOutcome.stateDelta;
    if (delta.hp != 0) {
      if (delta.hp > 0) {
        character.heal(delta.hp);
      } else {
        character.takeDamage(delta.hp.abs());
      }
    }

    gameState.eventEnergy += delta.energy;
    gameState.eventObjective += delta.credits;
    gameState.eventInstability += delta.instability;

    tile.event = event.copyWith(isCompleted: true);
    _log('Event reducer applied choice "$choiceId" for event ${event.id}.');
    _flushTimeline();
    return selectedOutcome;
  }

  TileEventOutcome _resolveOutcome(TileEvent event, String choiceId) {
    String? linkedOutcomeId;
    for (final choice in event.choices) {
      if (choice.id == choiceId) {
        linkedOutcomeId = choice.linkedOutcomeId;
        break;
      }
    }

    if (linkedOutcomeId != null) {
      for (final outcome in event.outcomes) {
        if (outcome.id == linkedOutcomeId) {
          return outcome;
        }
      }
    }

    for (final outcome in event.outcomes) {
      if (outcome.isDefault) {
        return outcome;
      }
    }

    if (event.outcomes.isNotEmpty) {
      return event.outcomes.first;
    }

    return TileEventOutcome(
      id: '${event.id}_default',
      text: event.flavor,
      isDefault: true,
      stateDelta: event.stateDelta,
    );
  }
}

class _FieldActivationContext {
  final Character character;
  final Vector2 destination;
  final GridTile tile;
  final int row;
  final int col;

  const _FieldActivationContext({
    required this.character,
    required this.destination,
    required this.tile,
    required this.row,
    required this.col,
  });
}
