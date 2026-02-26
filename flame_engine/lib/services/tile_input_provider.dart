import 'dart:async';

import 'nfc_service.dart';

/// Source that produced a tile activation input.
enum TileInputSource { mockTap, nfc }

/// Unified input model for tile activations regardless of origin.
class TileActivationInput {
  final String tileId;
  final TileInputSource source;
  final Map<String, dynamic>? data;

  const TileActivationInput({
    required this.tileId,
    required this.source,
    this.data,
  });
}

/// Contract for any provider that emits tile activation inputs.
abstract class TileInputProvider {
  Stream<TileActivationInput> get inputs;

  Future<void> start();

  Future<void> stop();
}

/// Development/testing provider used by direct UI tile tap handlers.
class MockTileInputProvider implements TileInputProvider {
  final StreamController<TileActivationInput> _controller =
      StreamController<TileActivationInput>.broadcast();

  @override
  Stream<TileActivationInput> get inputs => _controller.stream;

  /// Method for tile tap handlers to inject a tile activation event.
  void onTileTapped(String tileId, {Map<String, dynamic>? data}) {
    _controller.add(
      TileActivationInput(
        tileId: tileId,
        source: TileInputSource.mockTap,
        data: data,
      ),
    );
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  void dispose() {
    _controller.close();
  }
}

/// Adapter that turns NFC scans into tile activation inputs.
class NfcTileInputProvider implements TileInputProvider {
  final NFCService _nfcService;
  final StreamController<TileActivationInput> _controller =
      StreamController<TileActivationInput>.broadcast();

  NfcTileInputProvider({required NFCService nfcService})
    : _nfcService = nfcService;

  @override
  Stream<TileActivationInput> get inputs => _controller.stream;

  @override
  Future<void> start() async {
    await _nfcService.startScanning((tagId, data) {
      // Placeholder adapter: forwards raw NFC tag IDs for now.
      // This can later parse richer NFCService payloads into tile semantics.
      _controller.add(
        TileActivationInput(
          tileId: tagId,
          source: TileInputSource.nfc,
          data: data,
        ),
      );
    });
  }

  @override
  Future<void> stop() {
    return _nfcService.stopScanning();
  }

  void dispose() {
    _controller.close();
  }
}
