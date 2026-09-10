import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar/services/audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // DhikrAudio() constructs an AudioPlayer whose constructor asynchronously
    // hits the audioplayers platform channels. Mock them so no
    // MissingPluginException escapes into the test run.
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
  });

  group('DhikrAudio', () {
    test('play returns false for a missing asset and stays quiet', () async {
      final audio = DhikrAudio();

      final result = await audio.play('assets/audio/do-not-exist.mp3');

      expect(result, isFalse);
      expect(audio.isPlaying, isFalse);
      expect(audio.currentSource, isNull);
    });

    test('stop clears playing state', () async {
      final audio = DhikrAudio();
      await audio.play('assets/audio/do-not-exist.mp3');

      await audio.stop();

      expect(audio.isPlaying, isFalse);
      expect(audio.currentSource, isNull);
    });
  });
}