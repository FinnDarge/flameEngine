import 'package:flutter/material.dart';

import '../models/game_state.dart';

class EndgameSummaryScreen extends StatelessWidget {
  final EndgameSummary summary;
  final VoidCallback onContinue;

  const EndgameSummaryScreen({
    super.key,
    required this.summary,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = summary.isVictory ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: const Color(0xFF232b36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    summary.isVictory ? Icons.emoji_events : Icons.warning_amber,
                    size: 56,
                    color: accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summary.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary.reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _SummaryRow(label: 'Turn reached', value: '${summary.turnNumber}'),
                  _SummaryRow(
                    label: 'Objective progress',
                    value: '${summary.objectiveValue}/${summary.objectiveTarget}',
                  ),
                  _SummaryRow(label: 'Instability', value: '${summary.instability}/10'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Return to Scenario Selection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: const Color(0xFF1a1a1a),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
