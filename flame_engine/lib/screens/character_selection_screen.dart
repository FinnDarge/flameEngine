import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart' show NFCService, kMockNfc;
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
  String nfcStatus = 'Initialising NFC...';
  String? _scannedTagId;

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
    _initNFC();
  }

  Future<void> _initNFC() async {
    final available = await widget.nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available
          ? 'Tap your character figure to the phone'
          : 'NFC Not Available';
    });
    if (available) {
      _startNFCScanning();
    }
  }

  void _startNFCScanning() {
    widget.nfcService.startScanning((tagId, data) {
      final name = _resolveCharacterName(tagId, data);
      // Release previous character so re-scanning updates the selection
      final prev = widget.gameState.localPlayer.character;
      if (prev != null) {
        widget.gameState.characters.remove(prev);
        widget.gameState.localPlayer.releaseCharacter();
      }
      // Claim the character in game state so downstream screens can use it
      widget.gameState.claimCharacter(tagId);
      setState(() {
        _scannedTagId = tagId;
        nfcStatus = name != null ? 'Tag scanned: $name' : 'Tag scanned: $tagId';
      });
    });
  }

  void _triggerMockScan(String tagId) {
    widget.nfcService.triggerMockScan(tagId);
  }

  /// Quick dev shortcut - select first character and continue immediately
  void _quickDevVanguard() {
    // Use first available API piece or fall back to mock data
    final pieces = widget.gameState.apiPieces;
    if (pieces.isNotEmpty) {
      _triggerMockScan(pieces.first.nfcTagId);
    } else if (kMockNfcCharacterList.isNotEmpty) {
      final firstMock = kMockNfcCharacterList.first;
      _triggerMockScan(firstMock['tagId'] as String);
    }
    // Give the mock scan a moment to process
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onCharacterSelected();
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
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                  size: 64,
                  color: nfcAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Your Character',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  nfcStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Character Info
          Expanded(
            child: Center(
              child: character != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(
                            character.characterClass.color,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'You scanned:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${character.name} (${character.characterClass.name})',
                                  style: TextStyle(
                                    color: Color(
                                      character.characterClass.color,
                                    ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                // Quick dev button for fast iteration
                if (kMockNfc) ...[
                  ElevatedButton.icon(
                    onPressed: _quickDevVanguard,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Quick Dev (Vanguard)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
                if (kMockNfc) ...[
                  ...kMockNfcCharacterList.map((char) {
                    final tagId = char['tagId'] as String;
                    final name = char['characterName'] as String;
                    return ElevatedButton.icon(
                      onPressed: () => _triggerMockScan(tagId),
                      icon: const Icon(Icons.person),
                      label: Text('Mock $name'),
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
                        : Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
