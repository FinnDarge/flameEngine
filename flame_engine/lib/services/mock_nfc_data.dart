/// Mock NFC character data for development and testing.
/// Only active when the app is built with --dart-define=MOCK_NFC=true.

// ── Wizard ───────────────────────────────────────────────────────────────────

/// Stable NFC hardware tag ID for the Wizard figure (hex-colon format).
const String kWizardNfcTagId = '53:F2:8C:F5:62:00:01';

/// UUID uniquely identifying this Wizard character entity.
const String kWizardUuid = 'a3f8b2c1-550e-4f92-b1de-7e3a9d8c2f14';

/// Display name of the Wizard character.
const String kWizardCharacterName = 'Wizard';

/// Full mock NFC payload that would be read from the physical Wizard tag.
const Map<String, dynamic> kWizardMockNfcPayload = {
  'tagId': kWizardNfcTagId,
  'uuid': kWizardUuid,
  'characterName': kWizardCharacterName,
  'characterClass': 'wizard',
};

// ── Warrior ───────────────────────────────────────────────────────────────────

const String kWarriorNfcTagId = '53:9F:92:F5:62:00:01';
const String kWarriorUuid = 'b1e2c3d4-1234-4abc-8000-aabbccddeeff';
const String kWarriorCharacterName = 'Warrior';
const Map<String, dynamic> kWarriorMockNfcPayload = {
  'tagId': kWarriorNfcTagId,
  'uuid': kWarriorUuid,
  'characterName': kWarriorCharacterName,
  'characterClass': 'warrior',
};

// ── All mock characters ───────────────────────────────────────────────────────

/// All mock NFC characters available during mock mode.
/// Keyed by stable NFC tag ID.
const Map<String, Map<String, dynamic>> kMockNfcCharacters = {
  kWizardNfcTagId: kWizardMockNfcPayload,
  kWarriorNfcTagId: kWarriorMockNfcPayload,
};

/// Ordered list of all mock characters for display in the UI.
const List<Map<String, dynamic>> kMockNfcCharacterList = [
  kWizardMockNfcPayload,
  kWarriorMockNfcPayload,
];
