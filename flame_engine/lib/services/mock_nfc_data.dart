import 'management_api_service.dart';

/// Mock NFC character data for development and testing.
/// Only active when the app is built with --dart-define=MOCK_NFC=true.
///
/// The values below serve as compile-time defaults; at runtime they are
/// replaced with live data from [ManagementApiService] (see [applyApiData]).

// ── Controller (default fallback) ──────────────────────────────────────────────

String kControllerNfcTagId = '04:CF:EB:6C:C8:2A:81';
String kControllerUuid = 'c1e2f3d4-abcd-4321-9000-112233445566';
String kControllerCharacterName = 'Controller';

// ── Engineer (default fallback) ────────────────────────────────────────────────

String kEngineerNfcTagId = '04:FB:98:6D:C8:2A:81';
String kEngineerUuid = 'e1f2a3b4-cdef-4567-a000-667788990011';
String kEngineerCharacterName = 'Engineer';

// ── Striker (default fallback) ─────────────────────────────────────────────────

String kStrikerNfcTagId = '04:F7:15:60:C9:2A:81';
String kStrikerUuid = 's1t2r3i4-5678-4abc-b000-aabbccddee11';
String kStrikerCharacterName = 'Striker';

// ── Vanguard (default fallback) ────────────────────────────────────────────────

/// TEMPORARY: Set to your physical NFC tag for testing with real API
/// 04:BA:42:6F:C8:2A:81 Echter NFC Tag beim RED Vanguard
String kVanguardNfcTagId = '04:62:67:56:CB:2A:81'; // Your physical tag
String kVanguardUuid = 'v1a2n3g4-90ab-4def-c000-ffeeddccbbaa';
String kVanguardCharacterName = 'Vanguard';

// ── Runtime maps (populated by applyApiData or from defaults) ─────────────────

/// All mock NFC characters available during mock mode.
/// Keyed by NFC tag ID in hex-colon format.
Map<String, Map<String, dynamic>> kMockNfcCharacters = {
  kControllerNfcTagId: {
    'tagId': kControllerNfcTagId,
    'uuid': kControllerUuid,
    'characterName': kControllerCharacterName,
    'characterClass': 'controller',
  },
  kEngineerNfcTagId: {
    'tagId': kEngineerNfcTagId,
    'uuid': kEngineerUuid,
    'characterName': kEngineerCharacterName,
    'characterClass': 'engineer',
  },
  kStrikerNfcTagId: {
    'tagId': kStrikerNfcTagId,
    'uuid': kStrikerUuid,
    'characterName': kStrikerCharacterName,
    'characterClass': 'striker',
  },
  kVanguardNfcTagId: {
    'tagId': kVanguardNfcTagId,
    'uuid': kVanguardUuid,
    'characterName': kVanguardCharacterName,
    'characterClass': 'vanguard',
  },
};

/// Ordered list of all mock characters for display in the UI.
List<Map<String, dynamic>> kMockNfcCharacterList = [
  kMockNfcCharacters[kControllerNfcTagId]!,
  kMockNfcCharacters[kEngineerNfcTagId]!,
  kMockNfcCharacters[kStrikerNfcTagId]!,
  kMockNfcCharacters[kVanguardNfcTagId]!,
];

// ── API integration ───────────────────────────────────────────────────────────

/// Your physical NFC tag to use for testing (will be mapped to Vanguard)
const String kPhysicalTestTag = '04:62:67:56:CB:2A:81';

/// Overwrite the mock character data with pieces loaded from the management API.
/// Call this once after [ManagementApiService.load] completes.
void applyApiData(ManagementApiService api) {
  print('═══════════════════════════════════════════════════════════');
  print('🔄 Applying API data to mock NFC characters...');
  print('   API pieces available: ${api.pieces.length}');

  if (api.pieces.isEmpty) {
    print('   ⚠ No API pieces loaded, using mock data');
    // No API data, but add physical tag mapping to Vanguard anyway
    _addPhysicalTagMapping();
    print('═══════════════════════════════════════════════════════════\n');
    return;
  }

  print('   Processing API pieces:');
  // Update per-piece constants for the canonical character classes
  for (final piece in api.pieces) {
    print('   • ${piece.name} (${piece.characterClass}) -> ${piece.nfcTagId}');
    if (piece.characterClass == 'controller') {
      kControllerNfcTagId = piece.nfcTagId;
      kControllerUuid = piece.uuid;
      kControllerCharacterName = piece.name;
    } else if (piece.characterClass == 'engineer') {
      kEngineerNfcTagId = piece.nfcTagId;
      kEngineerUuid = piece.uuid;
      kEngineerCharacterName = piece.name;
    } else if (piece.characterClass == 'striker') {
      kStrikerNfcTagId = piece.nfcTagId;
      kStrikerUuid = piece.uuid;
      kStrikerCharacterName = piece.name;
    } else if (piece.characterClass == 'vanguard') {
      // Don't overwrite - keep the physical test tag
      // kVanguardNfcTagId = piece.nfcTagId;
      kVanguardUuid = piece.uuid;
      kVanguardCharacterName = piece.name;
    }
  }

  // Rebuild the lookup map from all API pieces
  kMockNfcCharacters = {
    for (final piece in api.pieces) piece.nfcTagId: piece.toMockPayload(),
  };

  // Rebuild the ordered list
  kMockNfcCharacterList = api.pieces.map((p) => p.toMockPayload()).toList();

  print(
    '\n   ✓ Mock character map rebuilt with ${kMockNfcCharacters.length} entries',
  );
  print(
    '   ✓ Character list rebuilt with ${kMockNfcCharacterList.length} items',
  );

  // Add physical tag mapping
  _addPhysicalTagMapping();

  print('\n✅ Mock NFC data updated from API successfully!');
  print('═══════════════════════════════════════════════════════════\n');
}

/// Add your physical NFC tag as an alias for Vanguard
void _addPhysicalTagMapping() {
  print('\n   🏷️  Adding physical test tag mapping:');
  print('      Tag ID: $kPhysicalTestTag');
  print('      Character: $kVanguardCharacterName (Vanguard)');
  print('      UUID: $kVanguardUuid');

  // Add physical tag to the lookup map
  kMockNfcCharacters[kPhysicalTestTag] = {
    'tagId': kPhysicalTestTag,
    'uuid': kVanguardUuid,
    'characterName': kVanguardCharacterName,
    'characterClass': 'vanguard',
  };

  print('      ✓ Physical tag successfully mapped!');
}
