import 'package:audioplayers/audioplayers.dart';

/// Singleton service that manages background music for the entire app.
/// The soundtrack loops continuously regardless of the current screen.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _started = false;

  /// Prepares the player without starting playback.
  /// Safe to call before any user interaction.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
  }

  /// Starts playback. Must be called from a user-interaction context
  /// (required by browser autoplay policy on web).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _player.play(AssetSource('audio/token-board-soundtrack.mp3'));
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> dispose() async {
    await _player.dispose();
    _initialized = false;
  }
}
