import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'mock_nfc_data.dart';

/// Whether mock NFC mode is enabled (pass --dart-define=MOCK_NFC=true to activate)
const bool kMockNfc = bool.fromEnvironment('MOCK_NFC');

/// Service for handling NFC tag reading
class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  bool _isAvailable = false;
  bool _isScanning = false;
  Function(String tagId, Map<String, dynamic>? data)? _mockCallback;

  /// Check if NFC is available on the device
  Future<bool> checkAvailability() async {
    if (kMockNfc) {
      _isAvailable = true;
      return true;
    }
    _isAvailable = await NfcManager.instance.isAvailable();
    return _isAvailable;
  }

  /// Start listening for NFC tags
  Future<void> startScanning(
    Function(String tagId, Map<String, dynamic>? data) onTagDiscovered,
  ) async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    if (_isScanning) {
      return;
    }

    _isScanning = true;

    if (kMockNfc) {
      // In mock mode, store the callback and wait for triggerMockScan()
      _mockCallback = onTagDiscovered;
      return;
    }

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

  /// Simulate an NFC scan with a given tag ID (only works when kMockNfc is true).
  /// Automatically attaches mock payload data if the tag ID is in kMockNfcCharacters.
  void triggerMockScan(String tagId) {
    if (kMockNfc && _isScanning && _mockCallback != null) {
      final payload = kMockNfcCharacters[tagId];
      _mockCallback!(tagId, payload);
    }
  }

  /// Stop scanning for NFC tags
  Future<void> stopScanning() async {
    if (_isScanning) {
      if (!kMockNfc) {
        await NfcManager.instance.stopSession();
      }
      _mockCallback = null;
      _isScanning = false;
    }
  }

  /// Extract tag ID from NFC tag
  String _extractTagId(NfcTag tag) {
    // Try to get UID from all NFC tag technologies (works for NDEF and non-NDEF)
    final identifier =
        tag.data['nfca']?['identifier'] ??
        tag.data['nfcb']?['identifier'] ??
        tag.data['nfcf']?['identifier'] ??
        tag.data['nfcv']?['identifier'] ??
        tag.data['isodep']?['identifier'];

    if (identifier != null) {
      return _bytesToHex((identifier as List).cast<int>());
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
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  /// Write data to an NFC tag (for programming your physical tiles)
  Future<bool> writeToTag(String message) async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    final completer = Completer<bool>();

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          await NfcManager.instance.stopSession(
            errorMessage: 'Tag is not writable',
          );
          completer.complete(false);
          return;
        }

        final ndefMessage = NdefMessage([NdefRecord.createText(message)]);

        try {
          await ndef.write(ndefMessage);
          await NfcManager.instance.stopSession();
          completer.complete(true);
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: 'Write failed: $e',
          );
          completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  bool get isScanning => _isScanning;
  bool get isAvailable => _isAvailable;
}
