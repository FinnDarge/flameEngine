import 'package:nfc_manager/nfc_manager.dart';

/// Service for handling NFC tag reading
class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  bool _isAvailable = false;
  bool _isScanning = false;

  /// Check if NFC is available on the device
  Future<bool> checkAvailability() async {
    _isAvailable = await NfcManager.instance.isAvailable();
    return _isAvailable;
  }

  /// Start listening for NFC tags
  Future<void> startScanning(Function(String tagId, Map<String, dynamic>? data) onTagDiscovered) async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    if (_isScanning) {
      return;
    }

    _isScanning = true;

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // Extract tag ID and data
        final tagId = _extractTagId(tag);
        final tagData = _extractTagData(tag);

        // Call the callback
        onTagDiscovered(tagId, tagData);
      },
    );
  }

  /// Stop scanning for NFC tags
  Future<void> stopScanning() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
      _isScanning = false;
    }
  }

  /// Extract tag ID from NFC tag
  String _extractTagId(NfcTag tag) {
    // Try different tag technologies to get ID
    var ndef = Ndef.from(tag);
    if (ndef != null) {
      // For NDEF tags, we can use the identifier
      final identifier = tag.data['nfca']?['identifier'] ??
          tag.data['nfcb']?['identifier'] ??
          tag.data['nfcf']?['identifier'] ??
          tag.data['nfcv']?['identifier'];

      if (identifier != null) {
        return _bytesToHex(identifier);
      }
    }

    // Fallback: use raw tag data
    return tag.data.toString();
  }

  /// Extract additional data from NFC tag
  Map<String, dynamic>? _extractTagData(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef == null) return null;

    final cachedMessage = ndef.cachedMessage;
    if (cachedMessage == null) return null;

    final data = <String, dynamic>{};

    for (var record in cachedMessage.records) {
      // Parse NDEF records
      final payload = String.fromCharCodes(record.payload);
      data['payload'] = payload;
      data['type'] = String.fromCharCodes(record.type);
    }

    return data;
  }

  /// Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  /// Write data to an NFC tag (for programming your physical tiles)
  Future<bool> writeToTag(String message) async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    bool writeSuccess = false;

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          writeSuccess = false;
          await NfcManager.instance.stopSession(errorMessage: 'Tag is not writable');
          return;
        }

        NdefMessage ndefMessage = NdefMessage([
          NdefRecord.createText(message),
        ]);

        try {
          await ndef.write(ndefMessage);
          writeSuccess = true;
          await NfcManager.instance.stopSession();
        } catch (e) {
          writeSuccess = false;
          await NfcManager.instance.stopSession(errorMessage: 'Write failed: $e');
        }
      },
    );

    return writeSuccess;
  }

  bool get isScanning => _isScanning;
  bool get isAvailable => _isAvailable;
}
