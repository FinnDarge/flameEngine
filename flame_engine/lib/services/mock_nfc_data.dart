import 'management_api_service.dart';

/// Mock NFC character data for development and testing.
/// Only active when the app is built with --dart-define=MOCK_NFC=true.
///
/// The values below serve as compile-time defaults; at runtime they are
/// replaced with live data from [ManagementApiService] (see [applyApiData]).

// ── Wizard (default fallback) ─────────────────────────────────────────────────

/// NFC hardware tag ID for the Wizard figure (hex-colon format).
String kWizardNfcTagId = '53:F2:8C:F5:62:00:01';

/// UUID uniquely identifying this Wizard character entity.
String kWizardUuid = 'a3f8b2c1-550e-4f92-b1de-7e3a9d8c2f14';

/// Display name of the Wizard character.
String kWizardCharacterName = 'Wizard';

// ── Warrior (default fallback) ────────────────────────────────────────────────

String kWarriorNfcTagId = '53:9F:92:F5:62:00:01';
String kWarriorUuid = 'b1e2c3d4-1234-4abc-8000-aabbccddeeff';
String kWarriorCharacterName = 'Warrior';

// ── Runtime maps (populated by applyApiData or from defaults) ─────────────────

/// All mock NFC characters available during mock mode.
/// Keyed by NFC tag ID in hex-colon format.
Map<String, Map<String, dynamic>> kMockNfcCharacters = {
  kWizardNfcTagId: {
    'tagId': kWizardNfcTagId,
    'uuid': kWizardUuid,
    'characterName': kWizardCharacterName,
    'characterClass': 'wizard',
  },
  kWarriorNfcTagId: {
    'tagId': kWarriorNfcTagId,
    'uuid': kWarriorUuid,
    'characterName': kWarriorCharacterName,
    'characterClass': 'warrior',
  },
};

/// Ordered list of all mock characters for display in the UI.
List<Map<String, dynamic>> kMockNfcCharacterList = [
  kMockNfcCharacters[kWizardNfcTagId]!,
  kMockNfcCharacters[kWarriorNfcTagId]!,
];

// ── API integration ───────────────────────────────────────────────────────────

/// Overwrite the mock character data with pieces loaded from the management API.
/// Call this once after [ManagementApiService.load] completes.
void applyApiData(ManagementApiService api) {
  if (api.pieces.isEmpty) return;

  // Update per-piece constants for the two canonical character classes
  for (final piece in api.pieces) {
    if (piece.characterClass == 'wizard') {
      kWizardNfcTagId = piece.nfcTagId;
      kWizardUuid = piece.uuid;
      kWizardCharacterName = piece.name;
    } else if (piece.characterClass == 'warrior') {
      kWarriorNfcTagId = piece.nfcTagId;
      kWarriorUuid = piece.uuid;
      kWarriorCharacterName = piece.name;
    }
  }

  // Rebuild the lookup map from all API pieces
  kMockNfcCharacters = {
    for (final piece in api.pieces) piece.nfcTagId: piece.toMockPayload(),
  };

  // Rebuild the ordered list
  kMockNfcCharacterList = api.pieces.map((p) => p.toMockPayload()).toList();

  print(
    '✓ Mock NFC data updated from API: '
    '${kMockNfcCharacters.length} pieces',
  );
}
