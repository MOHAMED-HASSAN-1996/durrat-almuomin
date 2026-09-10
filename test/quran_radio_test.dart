import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar/services/quran_radio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.client.root'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.manager'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '.',
    );
  });

  group('QuranRadioService', () {
    test('liveStations contains only Cairo and Makkah primary stations', () {
      final radio = QuranRadioService.instance;
      final live = radio.liveStations;

      expect(live.length, 2);
      expect(live[0].name, contains('القاهرة'));
      expect(live[0].url, contains('radiojar'));
      expect(live[1].name, contains('مكة'));
      expect(live[1].url, contains('kwikmotion'));
    });

    test('cairoStation and makkahStation getters are correct', () {
      final radio = QuranRadioService.instance;
      expect(radio.cairoStation.name, contains('القاهرة'));
      expect(radio.makkahStation.name, contains('مكة'));
    });

    test(
      'recognises Cairo and Makkah as the live sources behind the controls',
      () {
        final radio = QuranRadioService.instance;

        expect(radio.isLiveStation(radio.cairoStation), isTrue);
        expect(radio.isLiveStation(radio.makkahStation), isTrue);
      },
    );

    test('stop sets isPlaying to false', () async {
      final radio = QuranRadioService.instance;
      await radio.stop();
      expect(radio.isPlaying, isFalse);
    });
  });
}
