import 'package:flutter/material.dart';

import '../models/tile_event.dart';

/// Unified view model for resolving both combat and non-combat events.
class EventResolutionViewModel {
  final String eventId;
  final String title;
  final String flavor;
  final List<EventResolutionChoiceViewModel> choices;
  final List<EventResolutionDeltaItem> stateChanges;
  final bool isCombatEvent;

  const EventResolutionViewModel({
    required this.eventId,
    required this.title,
    required this.flavor,
    required this.choices,
    required this.stateChanges,
    this.isCombatEvent = false,
  });

  factory EventResolutionViewModel.fromTileEvent(
    TileEvent event, {
    bool isCombatEvent = false,
    TileEventOutcome? selectedOutcome,
  }) {
    final resolvedDelta = selectedOutcome?.stateDelta ?? event.stateDelta;

    return EventResolutionViewModel(
      eventId: event.id,
      title: event.title,
      flavor: event.flavor,
      choices: (event.choices.isNotEmpty
              ? event.choices
              : [
                  const TileEventChoice(
                    id: 'continue',
                    label: 'Continue',
                  ),
                ])
          .map(
            (choice) => EventResolutionChoiceViewModel(
              id: choice.id,
              label: choice.label,
            ),
          )
          .toList(),
      stateChanges: EventResolutionDeltaItem.fromStateDelta(resolvedDelta),
      isCombatEvent: isCombatEvent || event.type == TileEventType.encounter,
    );
  }
}

class EventResolutionChoiceViewModel {
  final String id;
  final String label;

  const EventResolutionChoiceViewModel({required this.id, required this.label});
}

class EventResolutionDeltaItem {
  final String label;
  final int delta;

  const EventResolutionDeltaItem({required this.label, required this.delta});

  String get formatted => delta > 0 ? '+$delta' : '$delta';

  Color colorFor(BuildContext context) {
    if (delta == 0) return Theme.of(context).colorScheme.onSurfaceVariant;
    return delta > 0 ? Colors.green.shade400 : Colors.red.shade400;
  }

  static List<EventResolutionDeltaItem> fromStateDelta(TileEventStateDelta d) {
    return [
      EventResolutionDeltaItem(label: 'HP', delta: d.hp),
      EventResolutionDeltaItem(label: 'Energy', delta: d.energy),
      EventResolutionDeltaItem(label: 'Objective', delta: d.credits),
      EventResolutionDeltaItem(label: 'Instability', delta: d.instability),
    ];
  }
}

class EventResolutionBottomSheet extends StatefulWidget {
  final EventResolutionViewModel viewModel;
  final Future<void> Function(String choiceId) onChoiceSelected;

  const EventResolutionBottomSheet({
    super.key,
    required this.viewModel,
    required this.onChoiceSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required EventResolutionViewModel viewModel,
    required Future<void> Function(String choiceId) onChoiceSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1f1f1f),
      builder: (_) => EventResolutionBottomSheet(
        viewModel: viewModel,
        onChoiceSelected: onChoiceSelected,
      ),
    );
  }

  @override
  State<EventResolutionBottomSheet> createState() =>
      _EventResolutionBottomSheetState();
}

class _EventResolutionBottomSheetState extends State<EventResolutionBottomSheet> {
  bool _submitting = false;

  Future<void> _selectChoice(String choiceId) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });

    await widget.onChoiceSelected(choiceId);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  vm.isCombatEvent ? Icons.gps_fixed : Icons.auto_awesome,
                  color: vm.isCombatEvent ? Colors.redAccent : Colors.cyanAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '[${vm.eventId}] ${vm.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              vm.flavor,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose action',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...vm.choices.map(
              (choice) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _selectChoice(choice.id),
                    child: Text(choice.label),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Result preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: vm.stateChanges
                        .map(
                          (change) => Text(
                            '${change.label}: ${change.formatted}',
                            style: TextStyle(
                              color: change.colorFor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
