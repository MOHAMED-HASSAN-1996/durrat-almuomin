import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../theme/app_theme.dart';
import '../screens/prayer_times_screen.dart';
import 'prayer_times.dart';
import 'storage.dart';
import 'adhan_alert.dart';

/// Native platform permission helper for Android & iOS (Battery optimization, exact alarms, system notification settings)
class PlatformPermissions {
  PlatformPermissions._();
  static const MethodChannel _channel = MethodChannel(
    'com.dhikr.adhkar/permissions',
  );
  static MethodChannel get channel => _channel;

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> openExactAlarmSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openNotificationSettings() async {
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('openNotificationSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canDrawOverlays() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canDrawOverlays');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Manages Prayer Time Azan alerts, system notifications on Android & iOS,
/// and in-app popup dialogs.
class PrayerAlertService {
  PrayerAlertService._();
  static final PrayerAlertService instance = PrayerAlertService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  bool _initialized = false;
  final _alertController = StreamController<AdhanAlert>.broadcast();
  final _azanFinishedController = StreamController<void>.broadcast();
  AdhanAlert? _pendingAlert;

  /// Emits when the user opens a prayer notification, including a full-screen one.
  Stream<AdhanAlert> get alertStream => _alertController.stream;

  /// Emits when the Azan audio completes or is stopped.
  Stream<void> get onAzanFinished => _azanFinishedController.stream;

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    try {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return (await android?.areNotificationsEnabled()) ?? true;
    } catch (_) {
      return true;
    }
  }

  AdhanAlert? takePendingAlert() {
    final alert = _pendingAlert;
    _pendingAlert = null;
    return alert;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final alert = AdhanAlert.fromPayload(response.payload);
    if (alert == null) return;
    _pendingAlert = alert;
    _alertController.add(alert);
  }

  /// يُستدعى عند ضغط زر تعلية/خفض الصوت أثناء تشغيل الأذان (لإيقافه).
  static VoidCallback? onVolumeButtonPressed;

  static const String _channelId = 'adhkar_prayer_azan_v4_alarm_channel';
  static const String _channelName =
      'درّة المؤمن — تنبيهات مواقيت الصلاة والأذان';
  static const String _channelDescription =
      'إشعارات النظام الرسمية والأذان عند حلول مواعيد الصلاة على شاشة جهازك لتطبيق درّة المؤمن';

  /// A short, unmistakable pulse sequence that accompanies the system adhan.
  static const List<int> adhanVibrationPattern = [0, 700, 450, 700, 450, 700];
  static final Int64List _adhanVibrationPattern = Int64List.fromList(
    adhanVibrationPattern,
  );

  // Second channel — high-importance dhikr/general reminders
  static const String _dhikrChannelId = 'adhkar_dhikr_reminders_channel';
  static const String _dhikrChannelName =
      'درّة المؤمن — تذكيرات الأذكار والورد اليومي';
  static const String _dhikrChannelDescription =
      'تذكيرات ذكر الله والأذكار اليومية وأذكار الصباح والمساء من تطبيق درّة المؤمن';

  /// Initialize system notification service for Android & iOS
  Future<void> init() async {
    // استقبال ضغطات أزرار الصوت من الطبقة الأصلية لإيقاف الأذان فوراً.
    try {
      PlatformPermissions.channel.setMethodCallHandler((call) async {
        if (call.method == 'volumeButtonPressed') {
          stopAzan();
          onVolumeButtonPressed?.call();
        }
      });
    } catch (_) {}
    if (_initialized) return;
    if (kIsWeb) return;

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneName = DateTime.now().timeZoneName;
        if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } else {
          final nowOffset = DateTime.now().timeZoneOffset;
          for (final loc in tz.timeZoneDatabase.locations.values) {
            if (loc.currentTimeZone.offset == nowOffset ||
                loc.currentTimeZone.offset.inMilliseconds ==
                    nowOffset.inMilliseconds) {
              tz.setLocalLocation(loc);
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('Timezone config error: $e');
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _handleNotificationResponse(launchDetails!.notificationResponse!);
      }

      // Create Android Notification Channel
      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          // ── Channel 1: Azan / Prayer alarm channel ──────────────────────────
          try {
            await androidPlugin.createNotificationChannel(
              const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: _channelDescription,
                importance: Importance.max,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('adhan'),
                enableVibration: true,
                enableLights: true,
                audioAttributesUsage: AudioAttributesUsage.alarm,
              ),
            );
          } catch (e) {
            debugPrint('Azan channel creation error: $e');
          }

          // ── Channel 2: Dhikr / general reminders ──────────────────────────
          try {
            await androidPlugin.createNotificationChannel(
              const AndroidNotificationChannel(
                _dhikrChannelId,
                _dhikrChannelName,
                description: _dhikrChannelDescription,
                importance: Importance.high,
                playSound: true,
                enableVibration: true,
                enableLights: true,
                showBadge: true,
                audioAttributesUsage: AudioAttributesUsage.notification,
              ),
            );
          } catch (e) {
            debugPrint('Dhikr channel creation error: $e');
          }

          // Request permissions for Android 13+
          try {
            await androidPlugin.requestNotificationsPermission();
          } catch (e) {
            debugPrint('Notifications permission error: $e');
          }
          try {
            await androidPlugin.requestExactAlarmsPermission();
          } catch (e) {
            debugPrint('Exact alarms permission error: $e');
          }
          try {
            await androidPlugin.requestFullScreenIntentPermission();
          } catch (e) {
            debugPrint('Full-screen intent permission error: $e');
          }
        }
      }

      _initialized = true;
      debugPrint('PrayerAlertService initialized successfully');
    } catch (e) {
      debugPrint('PrayerAlertService init error: $e');
    }
  }

  static const _prefEnabledKey = 'adhkar.alert_enabled';
  static const _prefFajrKey = 'adhkar.alert_fajr';
  static const _prefDhuhrKey = 'adhkar.alert_dhuhr';
  static const _prefAsrKey = 'adhkar.alert_asr';
  static const _prefMaghribKey = 'adhkar.alert_maghrib';
  static const _prefIshaKey = 'adhkar.alert_isha';
  static const _prefSoundKey = 'adhkar.alert_sound';
  static const _prefVibrationKey = 'adhkar.alert_vibration';

  Future<Map<String, dynamic>> getAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_prefEnabledKey) ?? true,
      'fajr': prefs.getBool(_prefFajrKey) ?? true,
      'dhuhr': prefs.getBool(_prefDhuhrKey) ?? true,
      'asr': prefs.getBool(_prefAsrKey) ?? true,
      'maghrib': prefs.getBool(_prefMaghribKey) ?? true,
      'isha': prefs.getBool(_prefIshaKey) ?? true,
      'sound': prefs.getString(_prefSoundKey) ?? 'adhan',
      'vibration': prefs.getBool(_prefVibrationKey) ?? true,
    };
  }

  Future<void> saveAlertPreferences({
    required bool enabled,
    required bool fajr,
    required bool dhuhr,
    required bool asr,
    required bool maghrib,
    required bool isha,
    required String sound,
    required bool vibration,
    Map<String, DateTime>? prayerTimes,
    required bool isArabic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, enabled);
    await prefs.setBool(_prefFajrKey, fajr);
    await prefs.setBool(_prefDhuhrKey, dhuhr);
    await prefs.setBool(_prefAsrKey, asr);
    await prefs.setBool(_prefMaghribKey, maghrib);
    await prefs.setBool(_prefIshaKey, isha);
    await prefs.setString(_prefSoundKey, sound);
    await prefs.setBool(_prefVibrationKey, vibration);

    if (prayerTimes != null) {
      await schedulePrayerNotifications(
        prayerTimes: prayerTimes,
        isArabic: isArabic,
      );
    }
  }

  /// Schedule system-level notifications for today and the upcoming 7 days on Android & Apple devices.
  /// Fires even when the app is completely closed or screen is off!
  Future<void> schedulePrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required bool isArabic,
    double? lat,
    double? lng,
  }) async {
    if (kIsWeb) return;
    await init();

    final prayerLabels = {
      'fajr': ('الفجر', 'Fajr', 101),
      'dhuhr': ('الظهر', 'Dhuhr', 102),
      'asr': ('العصر', 'Asr', 103),
      'maghrib': ('المغرب', 'Maghrib', 104),
      'isha': ('العشاء', 'Isha', 105),
    };

    final userPrefs = await getAlertPreferences();
    if (userPrefs['enabled'] != true) {
      for (final entry in prayerLabels.entries) {
        await _notificationsPlugin.cancel(id: entry.value.$3);
      }
      debugPrint('Alerts disabled — cancelled all scheduled notifications');
      return;
    }

    final bool vibrationEnabled = userPrefs['vibration'] as bool? ?? true;
    final now = DateTime.now();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();

    int scheduledCount = 0;
    for (final entry in prayerLabels.entries) {
      final key = entry.key;
      final time = prayerTimes[key];
      final notifId = entry.value.$3;

      // Cancel previous scheduled notification for this prayer
      try {
        await _notificationsPlugin.cancel(id: notifId);
      } catch (_) {}

      if (time == null) continue;

      // Check if this specific prayer is enabled by user
      if (userPrefs[key] != true) {
        continue;
      }

      final labelAr = entry.value.$1;
      final labelEn = entry.value.$2;

      // Only schedule if the time is in the future
      if (time.isAfter(now)) {
        final title = isArabic
            ? 'الله أكبر • حان الآن موعد أذان $labelAr'
            : 'Adhan $labelEn • Prayer Time';
        final body = isArabic
            ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»'
            : 'Come to prayer, come to success.';

        final tzTime = tz.TZDateTime.from(time, tz.local);

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('adhan'),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled ? _adhanVibrationPattern : null,
            ticker: 'الله أكبر • حان الآن موعد الصلاة',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

        try {
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: title,
            body: body,
            scheduledDate: tzTime,
            notificationDetails: details,
            payload: AdhanAlert(
              prayerNameAr: labelAr,
              prayerNameEn: labelEn,
            ).payload,
            androidScheduleMode: canExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
          scheduledCount++;
          debugPrint('Scheduled $key at $time (exact=$canExact)');
        } catch (e) {
          debugPrint('Primary schedule failed for $key: $e — trying inexact');
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notifId,
              title: title,
              body: body,
              scheduledDate: tzTime,
              notificationDetails: details,
              payload: AdhanAlert(
                prayerNameAr: labelAr,
                prayerNameEn: labelEn,
              ).payload,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            scheduledCount++;
            debugPrint('Scheduled $key at $time (inexact fallback)');
          } catch (err) {
            debugPrint('Error scheduling notification for $key: $err');
          }
        }
      } else {
        debugPrint('Skipped $key at $time (already past)');
      }
    }

    debugPrint('Scheduled $scheduledCount notifications for today');

    // Auto-schedule subsequent days (7 days in advance) so alerts continue working after midnight!
    double? useLat = lat;
    double? useLng = lng;
    if (useLat == null || useLng == null) {
      final saved = DhikrStorage().getSavedLocation();
      if (saved != null) {
        useLat = (saved['lat'] as num?)?.toDouble();
        useLng = (saved['lng'] as num?)?.toDouble();
      }
    }
    useLat ??= 30.0444;
    useLng ??= 31.2357;

    await scheduleUpcomingPrayers(
      lat: useLat,
      lng: useLng,
      isArabic: isArabic,
      daysToSchedule: 7,
    );
  }

  /// Schedules prayer alerts for the next [daysToSchedule] days (default 7 days) in advance.
  /// This ensures that prayer notifications continue working every day seamlessly even if the app
  /// is never opened for a week!
  Future<void> scheduleUpcomingPrayers({
    required double lat,
    required double lng,
    required bool isArabic,
    int daysToSchedule = 7,
  }) async {
    if (kIsWeb) return;
    await init();

    final userPrefs = await getAlertPreferences();
    if (userPrefs['enabled'] != true) {
      for (int d = 0; d < 14; d++) {
        for (int p = 1; p <= 5; p++) {
          await _notificationsPlugin.cancel(id: 100 + (d * 10) + p);
        }
      }
      return;
    }

    final bool vibrationEnabled = userPrefs['vibration'] as bool? ?? true;
    final now = DateTime.now();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();

    final prayers = [
      ('fajr', 'الفجر', 'Fajr', 1),
      ('dhuhr', 'الظهر', 'Dhuhr', 2),
      ('asr', 'العصر', 'Asr', 3),
      ('maghrib', 'المغرب', 'Maghrib', 4),
      ('isha', 'العشاء', 'Isha', 5),
    ];

    // Schedule for day 1 onwards (day 0 is already handled by schedulePrayerNotifications, or we schedule it too)
    for (int dayOffset = 1; dayOffset < daysToSchedule; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final calculated = PrayerCalculator.calculate(
        date: targetDate,
        lat: lat,
        lng: lng,
      );
      final times = calculated.asMap();

      for (final p in prayers) {
        final key = p.$1;
        final labelAr = p.$2;
        final labelEn = p.$3;
        final prayerIndex = p.$4;
        final notifId = 100 + (dayOffset * 10) + prayerIndex;

        // Cancel previous scheduled notification for this slot
        try {
          await _notificationsPlugin.cancel(id: notifId);
        } catch (_) {}

        if (userPrefs[key] != true) continue;

        final time = times[key];
        if (time == null || !time.isAfter(now)) continue;

        final title = isArabic
            ? 'الله أكبر • حان الآن موعد أذان $labelAr'
            : 'Adhan $labelEn • Prayer Time';
        final body = isArabic
            ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»'
            : 'Come to prayer, come to success.';

        final tzTime = tz.TZDateTime.from(time, tz.local);

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('adhan'),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled ? _adhanVibrationPattern : null,
            ticker: 'الله أكبر • حان الآن موعد الصلاة',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

        try {
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: title,
            body: body,
            scheduledDate: tzTime,
            notificationDetails: details,
            payload: AdhanAlert(
              prayerNameAr: labelAr,
              prayerNameEn: labelEn,
            ).payload,
            androidScheduleMode: canExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
          debugPrint('Scheduled $key +$dayOffset days at $time');
        } catch (e) {
          debugPrint(
            'Schedule failed for $key +$dayOffset: $e — trying inexact',
          );
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notifId,
              title: title,
              body: body,
              scheduledDate: tzTime,
              notificationDetails: details,
              payload: AdhanAlert(
                prayerNameAr: labelAr,
                prayerNameEn: labelEn,
              ).payload,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            debugPrint('Scheduled $key +$dayOffset (inexact)');
          } catch (err) {
            debugPrint(
              'Error scheduling upcoming prayer notification $notifId: $err',
            );
          }
        }
      }
    }
  }

  /// Show an immediate test system notification on device (Heads-Up & Lockscreen outside app)
  Future<void> showTestNotification({
    required bool isArabic,
    String? prayerNameAr,
    String? prayerNameEn,
  }) async {
    if (kIsWeb) return;
    await init();
    final nameAr = prayerNameAr ?? 'المغرب';
    final nameEn = prayerNameEn ?? 'Maghrib';
    final userPrefs = await getAlertPreferences();
    final bool vibrationEnabled = userPrefs['vibration'] as bool? ?? true;
    try {
      await _notificationsPlugin.show(
        id: 999,
        title: isArabic
            ? 'الله أكبر • حان الآن موعد أذان $nameAr 🕌'
            : 'Allahu Akbar • Adhan $nameEn 🕌',
        body: isArabic
            ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ» — اضغط لفتح التطبيق'
            : 'Come to prayer, come to success — Tap to open',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adhan'),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled ? _adhanVibrationPattern : null,
            ticker: 'الله أكبر • حان الآن موعد الصلاة',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: AdhanAlert(prayerNameAr: nameAr, prayerNameEn: nameEn).payload,
      );
      debugPrint('Test notification fired');
    } catch (e) {
      debugPrint('Test notification error: $e');
    }
  }

  /// Previews the Adhan alert:
  /// - Sends a Heads-Up fullScreenIntent system notification (appears outside the app, on desktop/lockscreen)
  /// - Plays Adhan audio
  /// - If the app is in foreground and context is mounted, also displays the in-app popup dialog
  Future<void> previewAdhanAlert({
    BuildContext? context,
    required String prayerNameAr,
    required String prayerNameEn,
    required bool isArabic,
    int delaySeconds = 0,
  }) async {
    if (kIsWeb) return;
    if (delaySeconds > 0) {
      Timer(Duration(seconds: delaySeconds), () async {
        await _executeAdhanPreview(
          context: context,
          prayerNameAr: prayerNameAr,
          prayerNameEn: prayerNameEn,
          isArabic: isArabic,
        );
      });
    } else {
      await _executeAdhanPreview(
        context: context,
        prayerNameAr: prayerNameAr,
        prayerNameEn: prayerNameEn,
        isArabic: isArabic,
      );
    }
  }

  Future<void> _executeAdhanPreview({
    BuildContext? context,
    required String prayerNameAr,
    required String prayerNameEn,
    required bool isArabic,
  }) async {
    // 1. System notification (pops up on mobile screen outside app)
    await showTestNotification(
      isArabic: isArabic,
      prayerNameAr: prayerNameAr,
      prayerNameEn: prayerNameEn,
    );

    // 2. Start audio playback
    _startAzanSound();

    // 3. If in app and context is mounted, show the dialog
    if (context != null && context.mounted) {
      await showAzanPopup(
        context,
        prayerNameAr: prayerNameAr,
        prayerNameEn: prayerNameEn,
        playSound: false, // audio already started
      );
    }
  }

  /// Trigger the Azan Popup on device with sound and action buttons (when app is open)
  Future<void> showAzanPopup(
    BuildContext context, {
    required String prayerNameAr,
    required String prayerNameEn,
    bool playSound = true,
  }) async {
    HapticFeedback.heavyImpact();

    if (playSound) {
      _startAzanSound();
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              stopAzan();
              Navigator.of(ctx).pop();
            }
          },
          child: Dialog(
            backgroundColor: dark ? const Color(0xFF1E2822) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DhikrColors.forest.withValues(
                        alpha: dark ? 0.4 : 0.12,
                      ),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      size: 42,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'الله أكبر • حان الآن موعد الصلاة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? const Color(0xFFD4AF37)
                          : DhikrColors.forestLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أذان $prayerNameAr',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: dark ? DhikrColors.darkText : DhikrColors.forest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 16,
                      height: 1.5,
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            stopAzan();
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text(
                            'إلغاء / إيقاف',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE55353),
                            side: BorderSide(
                              color: const Color(
                                0xFFE55353,
                              ).withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            stopAzan();
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrayerTimesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'فتح التطبيق',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DhikrColors.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    stopAzan();
  }

  void _startAzanSound() async {
    try {
      _player ??= AudioPlayer();
      _isPlaying = true;
      _player?.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _azanFinishedController.add(null);
      });
      try {
        await _player?.play(AssetSource('audio/adhan.mp3'));
      } catch (_) {
        await _player?.play(
          UrlSource(
            'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
          ),
        );
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  void stopAzan() {
    if (_isPlaying) {
      try {
        _player?.stop();
      } catch (_) {}
      _isPlaying = false;
      _azanFinishedController.add(null);
    }
    try {
      _notificationsPlugin.cancel(id: 999);
    } catch (_) {}
  }
}

/// Bottom Sheet providing clear options to test the Adhan Alert
/// immediately or with a delay to test outside the app (on mobile desktop / lockscreen)
void showAdhanPreviewSheet(
  BuildContext context, {
  required String prayerNameAr,
  required String prayerNameEn,
  required bool isArabic,
  required bool dark,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF161E28) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: dark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'معاينة تنبيه الأذان' : 'Test Adhan Alert',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'ظهور التنبيه على شاشة الهاتف (سواء داخل التطبيق أو خارجه على الديسك توب)'
                            : 'Alert display on device screen (in-app or outside on launcher)',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          color: dark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Trigger Immediately
            InkWell(
              onTap: () {
                Navigator.of(ctx).pop();
                PrayerAlertService.instance.previewAdhanAlert(
                  context: context,
                  prayerNameAr: prayerNameAr,
                  prayerNameEn: prayerNameEn,
                  isArabic: isArabic,
                  delaySeconds: 0,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF1E2836)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 24,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'تشغيل التنبيه الآن فوراً ⚡'
                                : 'Trigger Alert Now ⚡',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'يطلق إشعار النظام العاجل بصوت الأذان مع النافذة التفاعلية'
                                : 'Fires heads-up notification with adhan audio & popup',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11.5,
                              color: dark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Delay 5 seconds for testing on mobile home screen / desktop
            InkWell(
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      isArabic
                          ? '📱 اخرج الآن لشاشة هاتفك (الديسك توب)... سيصلك التنبيه بعد 5 ثوانٍ!'
                          : '📱 Go to your home screen now... Alert will fire in 5s!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
                PrayerAlertService.instance.previewAdhanAlert(
                  prayerNameAr: prayerNameAr,
                  prayerNameEn: prayerNameEn,
                  isArabic: isArabic,
                  delaySeconds: 5,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF1E2836)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 24,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'تشغيل بعد 5 ثوانٍ (للخروج للديسك توب) ⏱️'
                                : 'Trigger in 5 Seconds (To exit to desktop) ⏱️',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'يعطيك مهلة 5 ثوانٍ للخروج لشاشة الهاتف لتشاهد ظهور التنبيه خارج التطبيق'
                                : 'Gives 5s to minimize app and test notification on device screen',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11.5,
                              color: dark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
