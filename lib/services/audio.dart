import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Manages audio playback for the DHIKR app.
///
/// Guarantees:
///  - Only ONE track plays at any time. Starting a new track stops the old one.
///  - Audio only starts after explicit user interaction (never autoplay).
///  - [play] verifies the asset before playing; [playStream] plays an ordered
///    list of remote URLs back to back. If playback cannot start (missing
///    asset, network failure) the call returns false and no exception
///    propagates, so the caller can show the "audio unavailable" state.
class DhikrAudio {
  DhikrAudio() : _player = AudioPlayer() {
    _player.onPlayerComplete.listen((_) => _onComplete());
  }

  final AudioPlayer _player;

  String? _currentSource;
  bool _isPlaying = false;
  List<String>? _queue;
  int _queueIndex = 0;

  String? get currentSource => _currentSource;
  bool get isPlaying => _isPlaying;

  /// Plays a bundled asset (e.g. 'assets/audio/morning/01.mp3').
  /// Returns true when playback started, false when the asset is missing or
  /// unreadable so the UI can show the "audio unavailable" message.
  /// [sourceKey] is the identifier used for button state; defaults to the path.
  Future<bool> play(String assetPath, {String? sourceKey}) async {
    if (_isPlaying) {
      await stop();
    }
    // Verify the asset actually ships in the bundle before playing.
    try {
      await rootBundle.load(assetPath);
    } catch (_) {
      _reset();
      return false;
    }
    try {
      await _player.play(
        AssetSource(assetPath.replaceFirst('assets/', '')),
      );
      await _player.setReleaseMode(ReleaseMode.stop);
      _currentSource = sourceKey ?? assetPath;
      _isPlaying = true;
      return true;
    } catch (_) {
      _reset();
      return false;
    }
  }

  /// Plays an ordered list of remote audio URLs (real recorded recitation),
  /// advancing to the next URL whenever one completes.
  /// Returns true when the first clip started, false when it could not.
  Future<bool> playStream(List<String> urls, {String? sourceKey}) async {
    if (urls.isEmpty) return false;
    if (_isPlaying) {
      await stop();
    }
    _queue = List.of(urls);
    _queueIndex = 0;
    try {
      await _player.play(UrlSource(_queue![0]));
      await _player.setReleaseMode(ReleaseMode.stop);
      _currentSource = sourceKey ?? 'stream';
      _isPlaying = true;
      return true;
    } catch (_) {
      _reset();
      return false;
    }
  }

  Future<void> _onComplete() async {
    final queue = _queue;
    if (queue != null) {
      _queueIndex++;
      if (_queueIndex < queue.length) {
        try {
          await _player.play(UrlSource(queue[_queueIndex]));
          await _player.setReleaseMode(ReleaseMode.stop);
          return;
        } catch (_) {}
      }
    }
    _reset();
  }

  void _reset() {
    _currentSource = null;
    _isPlaying = false;
    _queue = null;
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _reset();
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (_) {}
  }

  /// Releases the underlying platform player.
  Future<void> dispose() async {
    await _player.dispose();
  }
}