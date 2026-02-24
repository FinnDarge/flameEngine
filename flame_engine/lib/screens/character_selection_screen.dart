import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart';
import '../services/mock_nfc_data.dart' show kMockNfcCharacterList;
import '../widgets/token_and_board_app_bar.dart';

/// Character selection screen for claiming a character
class CharacterSelectionScreen extends StatefulWidget {
  final GameState gameState;
  final NFCService nfcService;
  final VoidCallback onCharacterSelected;
  final VoidCallback onBack;

  const CharacterSelectionScreen({
    super.key,
    required this.gameState,
    required this.nfcService,
    required this.onCharacterSelected,
    required this.onBack,
  });

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  bool nfcAvailable = false;
  bool nfcScanning = false;
  String nfcStatus = 'NFC Not Started';
  String? _scannedTagId;
  String? _scannedCharacterName;

  /// Resolve a human-readable character name from a tag ID.
  /// Checks mock payload first, then falls back to CharacterClass enum.
  String? _resolveCharacterName(String tagId, Map<String, dynamic>? data) {
    // Use name from NFC payload data if present
    final payloadName = data?['characterName'] as String?;
    if (payloadName != null) return payloadName;
    // Fall back to CharacterClass enum match
    for (final cls in CharacterClass.values) {
      if (cls.nfcTagId == tagId) return cls.name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    final available = await widget.nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available
          ? 'NFC Available - Tap character figure to claim'
          : 'NFC Not Available';
    });
  }

  void _toggleNFCScanning() {
    if (!nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC not available on this device')),
      );
      return;
    }

    if (nfcScanning) {
      _stopNFCScanning();
    } else {
      _startNFCScanning();
    }
  }

  void _startNFCScanning() {
    widget.nfcService.startScanning((tagId, data) {
      final name = _resolveCharacterName(tagId, data);
      setState(() {
        _scannedTagId = tagId;
        _scannedCharacterName = name;
        nfcStatus = name != null ? 'Tag scanned: $name' : 'Tag scanned: $tagId';
      });
    });

    setState(() {
      nfcScanning = true;
    });
  }

  void _triggerMockScan(String tagId) {
    widget.nfcService.triggerMockScan(tagId);
  }

  void _stopNFCScanning() {
    widget.nfcService.stopScanning();
    setState(() {
      nfcScanning = false;
    });
  }

  @override
  void dispose() {
    widget.nfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.gameState.localPlayer.character;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(onBackPressed: widget.onBack),
      body: Column(
        children: [
          // Status Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                    size: 64,
                    color: nfcScanning
                        ? Colors.green
                        : (nfcAvailable ? Colors.orange : Colors.red),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Your Character',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nfcStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_scannedTagId != null &&
                      _scannedCharacterName != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepPurple.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _scannedCharacterName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (character != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(
                          character.characterClass.color,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(character.characterClass.color),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(character.characterClass.color),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You selected:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${character.name} (${character.characterClass.name})',
                                style: TextStyle(
                                  color: Color(character.characterClass.color),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: nfcAvailable ? _toggleNFCScanning : null,
                      icon: Icon(nfcScanning ? Icons.stop : Icons.nfc),
                      label: Text(nfcScanning ? 'Stop NFC' : 'Start NFC Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nfcScanning ? Colors.red : null,
                      ),
                    ),
                    if (kMockNfc && nfcScanning) ...[
                      ...kMockNfcCharacterList.map((char) {
                        final tagId = char['tagId'] as String;
                        final name = char['characterName'] as String;
                        return ElevatedButton.icon(
                          onPressed: () => _triggerMockScan(tagId),
                          icon: const Icon(Icons.person),
                          label: Text(name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade700,
                          ),
                        );
                      }),
                    ],
                    ElevatedButton.icon(
                      onPressed: _scannedTagId != null
                          ? widget.onCharacterSelected
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _scannedTagId != null
                            ? Colors.green
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Place your character figure on the NFC reader to select',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
