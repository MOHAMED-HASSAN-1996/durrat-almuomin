import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'quran_radio.dart';

class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;

  RadioAudioHandler(this._player) {
    _player.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (isPlaying) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: switch (state) {
            PlayerState.playing => AudioProcessingState.ready,
            PlayerState.paused => AudioProcessingState.ready,
            PlayerState.stopped => AudioProcessingState.idle,
            PlayerState.completed => AudioProcessingState.completed,
            _ => AudioProcessingState.idle,
          },
          playing: isPlaying,
        ),
      );
    });
  }

  void updateStationMetadata({
    required String url,
    required String title,
    String? category,
  }) {
    mediaItem.add(
      MediaItem(
        id: url,
        album: category ?? 'إذاعة القرآن الكريم',
        title: title,
        artist: 'دُرَّةُ الْمُؤْمِن',
        artUri: Uri.parse('resource://mipmap/ic_launcher'),
      ),
    );
  }

  void updateStationQueue(List<MediaItem> stations, int index) {
    queue.add(stations);
  }

  @override
  Future<void> play() async {
    await QuranRadioService.instance.resume();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await QuranRadioService.instance.nextStation();
  }

  @override
  Future<void> skipToPrevious() async {
    await QuranRadioService.instance.previousStation();
  }
}
