import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../types/adhkar.dart';
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

  static Future<bool> openBatteryOptimizationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>(
        'openBatteryOptimizationSettings',
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

  /// Whether Android permits this app to launch an alarm full-screen intent.
  /// This is intentionally separate from the overlay permission.
  static Future<bool> canUseFullScreenIntent() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// نبضة اهتزاز قوية لنقرة العدّ (السبحة الإلكترونية وأذكار الصباح والمساء
  /// وبعد الصلاة والرقية الشرعية).
  ///
  /// تعتمد على الطبقة الأصلية لأن قوة `HapticFeedback` من فلاتر ثابتة من
  /// النظام وما تنفع تزوّدها. على غير أندرويد ترجع `false` والمستدعي يكمل
  /// بالاهتزاز العادي من فلاتر.
  ///
  /// [intensity] 1 = نقرة عدّ عادية، 2 = إتمام العدّ (نبضة أطول).
  static Future<bool> tapVibration({int intensity = 1}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>(
        'tapVibration',
        {'intensity': intensity},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> startAdhanVibration() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startAdhanVibration');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopAdhanVibration() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopAdhanVibration');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> closeAdhanScreen() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('closeAdhanScreen');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Background tap handler — runs without bringing the app to foreground.
/// Lets the «إيقاف الأذان» action clear the adhan notification silently
/// instead of cold-starting the whole app.
@pragma('vm:entry-point')
void _adhanBackgroundResponse(NotificationResponse response) async {
  if (response.actionId == 'stop_azan' && response.id != null) {
    await FlutterLocalNotificationsPlugin().cancel(id: response.id!);
  }
}

/// Manages Prayer Time Azan alerts, system notifications on Android & iOS,
///
/// and in-app popup dialogs.
class PrayerAlertService {
  PrayerAlertService._();
  static final PrayerAlertService instance = PrayerAlertService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  StreamSubscription<void>? _playerCompleteSub;
  bool _initialized = false;
  final _azanFinishedController = StreamController<void>.broadcast();
  Future<void>? _prayerScheduleOperation;
  Future<void>? _upcomingScheduleOperation;

  /// Notification id of the adhan that is currently firing, so stopping the
  /// adhan cancels exactly one notification and never the whole schedule.
  int? _lastFiredAdhanId;

  /// The slot each scheduled adhan notification belongs to, mapped to the
  /// exact prayer time it was scheduled for.
  ///
  /// This is the *ownership registry* of the adhan: a notification may only be
  /// cancelled without the user asking when its recorded time no longer matches
  /// the time it was scheduled with (i.e. it is stale, not the one sounding).
  final Map<int, DateTime> _adhanSlots = <int, DateTime>{};

  /// Notification id used by the accelerated «معاينة الأذان» preview.
  static const int _adhanPreviewId = 991;

  /// Emits when the Azan audio completes or is stopped.
  Stream<void> get onAzanFinished => _azanFinishedController.stream;

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return (await android?.areNotificationsEnabled()) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> canUseFullScreenIntent() async {
    return PlatformPermissions.canUseFullScreenIntent();
  }

  /// Requests the runtime notification permission instead of merely opening
  /// settings. The caller must re-read the result after the system dialog.
  Future<bool> requestNotificationPermission() async {
    await init();
    if (kIsWeb) return true;
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notifications permission request error: $e');
    }
    return areNotificationsEnabled();
  }

  /// Opens Android's full-screen intent consent flow when it is required.
  Future<bool> requestFullScreenIntentPermission() async {
    await init();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestFullScreenIntentPermission();
    } catch (e) {
      debugPrint('Full-screen intent permission request error: $e');
    }
    return canUseFullScreenIntent();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final id = response.id;

    // إشعار «اقتربت الصلاة»: ما بيوقف شي، بيكمّل حياته العادية وبيتلغي لحاله.
    if (AdhanAlert.fromPayload(response.payload) == null) return;

    if (id != null) _lastFiredAdhanId = id;

    // زرار «إيقاف الأذان» — الإلغاء الوحيد المسموح: المستخدم بنفسه طلبه.
    // الإشعار بيُحذف يدوياً حتى لو النظام قيّد الأزرار الخلفية على الجهاز.
    unawaited(stopAzan());
    if (id != null) {
      unawaited(_notificationsPlugin.cancel(id: id));
    }
  }

  /// يُستدعى عند ضغط زر تعلية/خفض الصوت أثناء تشغيل الأذان (لإيقافه).
  static VoidCallback? onVolumeButtonPressed;

  /// The single, always-audible adhan channel.
  ///
  /// The id carries a `v9` generation marker on purpose: Android persists the
  /// sound / vibration / importance of an existing channel and silently ignores
  /// later code changes, so a new generation is required for the adhan to
  /// actually become audible with vibration. The adhan is delivered as one
  /// permanent alarm notification on this channel in every Android version, so
  /// it can never break because a permission (full-screen intent, overlay,
  /// battery) was refused.
  static const String _channelId = 'adhkar_prayer_azan_v9_fullscreen_audio_channel';
  static const String _channelName =
      'درة المؤمن — تنبيهات مواقيت الصلاة والأذان';
  static const String _channelDescription =
      'شاشة الأذان الكاملة عند حلول موعد كل فريضة، مع صوت الأذان والاهتزاز كاحتياطي مضمون';

  /// A strong alarm pulse sequence that accompanies the system adhan.
  static const List<int> adhanVibrationPattern = [
    0,
    1200,
    400,
    1200,
    400,
    1200,
    400,
    1200,
  ];
  static final Int64List _adhanVibrationPattern = Int64List.fromList(
    adhanVibrationPattern,
  );

  // Channel 2: Dhikr / general reminders
  static const String _dhikrChannelId = 'adhkar_dhikr_reminders_channel';
  static const String _dhikrChannelName =
      'درة المؤمن — تذكيرات الأذكار والورد اليومي';
  static const String _dhikrChannelDescription =
      'تذكيرات ذكر الله والأذكار اليومية وأذكار الصباح والمساء من تطبيق درة المؤمن';

  // Channel 3: Pre-Prayer (10 minutes before) audio reminder «اقتربت الصلاة أقم صلاتك»
  // Bump the channel id when changing sound: Android persists channel
  // sound/importance and ignores later code changes for an existing id.
  static const String _prePrayerChannelId =
      'adhkar_pre_prayer_v5_reminder_channel';
  static const String _prePrayerChannelName =
      'درة المؤمن — تنبيه اقتراب الصلاة (قبل ١٠ دقائق)';
  static const String _prePrayerChannelDescription =
      'تنبيه صوتي «اقتربت الصلاة، أقم صلاتك» قبل موعد الأذان بـ 10 دقائق لتطبيق درة المؤمن';

  /// A short, urgent pulse for the pre-prayer reminder — deliberately milder
  /// than [adhanVibrationPattern] so the two alerts are told apart instantly.
  static const List<int> prePrayerVibrationPattern = [0, 600, 250, 600];
  static final Int64List _prePrayerVibrationPattern = Int64List.fromList(
    prePrayerVibrationPattern,
  );

  /// Duration of the bundled adhan clip, used to stop the channel sound
  /// automatically while keeping the notification itself on screen.
  static const int adhanSoundMs = 5 * 60 * 1000;

  /// How long an adhan alert stays «alive», in minutes after its prayer time.
  ///
  /// The adhan clip runs ~3.5 minutes, so a firing adhan keeps owning its
  /// notification id far longer than the audio lasts: this window is what makes
  /// «the adhan is unaffected until the user stops it» true, and it is the only
  /// thing standing between a mid-adhan app restart and a silently killed azan.
  static const int _adhanGraceMinutes = 20;

  /// The five adhan notification ids used for *today*
  /// (101 = fajr … 105 = isha). These are the ids the user actually hears, so
  /// they are the only ones whose slot may hold a live, protected adhan.
  static const List<int> todayAdhanIds = [101, 102, 103, 104, 105];

  /// Id of the «اقتربت الصلاة» reminder for [dayOffset] days from today
  /// (0 = today) and prayer index [prayerIndex] (1 = fajr … 5 = isha).
  ///
  /// Lives in its own 5000+ block, deliberately disjoint from the adhan ids
  /// (101..405), the beneficiary reminders (500/501) and the preview (990/991):
  /// a notification id is a unique key, so reusing one silently *replaces* the
  /// pending notification. The old `200 + day*10 + index` scheme collided with
  /// the adhan window (the day-10 adhan sat on today's pre ids, days 11–30 sat
  /// on pre days 1–20) and with Eid's 501, wiping the reminder out before it
  /// ever fired.
  static int _prePrayerId(int dayOffset, int prayerIndex) =>
      5000 + (dayOffset * 10) + prayerIndex;

  /// Notification details for the adhan fired at the exact prayer time.
  ///
  /// إشعار الأذان: يشتغل الصوت مرة واحدة بطول الملف، ثم **يفضل ثابتاً على
  /// الشاشة** لحد ما المستخدم يلغيه بنفسه من زر «إيقاف الأذان». لا يوجد أي
  /// مسار تاني في التطبيق يقدر يحذفه (`ongoing` + `autoCancel: false`).
  NotificationDetails _adhanNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        // `false` means «use the channel sound» (adhan.mp3), not silence.
        playSound: false,
        enableVibration: true,
        vibrationPattern: _adhanVibrationPattern,
        ticker: 'الله أكبر • حان الآن موعد الأذان',
        icon: '@mipmap/ic_launcher',
        // الأذان يبقى على الشاشة لحد إلغاء المستخدم فقط، ولا يُعيد التنبيه
        // ولا يُلغى تلقائياً — بينما يتوقف الصوت وحده بعد مدة الملف.
        autoCancel: false,
        ongoing: true,
        onlyAlertOnce: true,
        timeoutAfter: adhanSoundMs,
        actions: const [
          AndroidNotificationAction(
            'stop_azan',
            'إيقاف الأذان',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Details of the «اقتربت الصلاة — أقم صلاتك» reminder fired 10 minutes
  /// before the adhan. Its only job is the pre-prayer nudge: it self-cancels on
  /// tap and never lingers.
  NotificationDetails _prePrayerNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _prePrayerChannelId,
        _prePrayerChannelName,
        channelDescription: _prePrayerChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('iqtarabat'),
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _prePrayerVibrationPattern,
        ticker: 'اقتربت الصلاة • أقم صلاتك',
        autoCancel: true,
        onlyAlertOnce: true,
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
  }

  /// Prepares the adhan slot `id` for the prayer time [time] before it is
  /// (re)scheduled.
  ///
  /// Cancels the slot's *stale* pending notification, except when the adhan that
  /// currently owns it is still sounding — that one is never touched, so the
  /// azan the user is hearing survives every app restart, re-seed and refresh.
  Future<void> _setAdhanSlot(int id, DateTime time) async {
    final previous = _adhanSlots[id];
    _adhanSlots[id] = time;
    if (previous != null && isAdhanActive(id)) {
      debugPrint('Keeping live adhan #$id (scheduled $previous) untouched');
      unawaited(_persistAdhanSlots());
      return;
    }
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
    unawaited(_persistAdhanSlots());
  }

  /// Cancels the scheduled adhan [id] and releases its slot — used when a
  /// prayer is switched off. Never touches the adhan that is currently
  /// sounding (same ownership rule as every other re-schedule path).
  Future<void> _releaseAdhanSlot(int id) async {
    await _loadAdhanSlots();
    if (isAdhanActive(id)) return;
    _adhanSlots.remove(id);
    unawaited(_persistAdhanSlots());
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  /// هل هذا الإشعار هو الأذان الشغّال حالياً؟ (ما زال صوته قابلاً للتشغيل).
  ///
  /// «شغّال» تعني أن **وقت الأذان قد حلّ فعلاً** وما زال داخل نافذة السماح،
  /// لا أن الإشعار مجدول فقط. الوقت المستقبلي يعطي فرقاً سالباً، ولو اكتفينا
  /// بمقارنة `< _adhanGraceMinutes` لاعتُبر كل أذان قادم «شغّالاً» — وهذا
  /// يخلي إيقاف أذان واحد يلغي بقية أذانات اليوم، بل ويوقف إعادة الجدولة لكل
  /// الأيام القادمة.
  bool isAdhanActive(int id) {
    final scheduled = _adhanSlots[id];
    if (scheduled == null) return false;
    final elapsed = DateTime.now().difference(scheduled);
    // أذان ما جاء وقته بعد = مجدول، مو شغّال: يُحتسب فقط عند حلول موعده.
    if (elapsed.isNegative) return false;
    return elapsed.inMinutes < _adhanGraceMinutes;
  }

  /// Registers an adhan slot without touching the system notifications — used by
  /// tests to verify the «never cancel a live azan» rule.
  @visibleForTesting
  void debugRegisterAdhanSlot(int id, DateTime time) {
    _adhanSlots[id] = time;
  }

  @visibleForTesting
  void debugClearAdhanSlots() {
    _adhanSlots.clear();
  }

  static const String _prefAdhanSlotsKey = 'adhkar.adhan_slots';
  bool _slotsLoaded = false;

  /// يحفظ سجل ملكية الأذان على القرص.
  ///
  /// بدونه، تشغيل التطبيق من جديد وأنت تسمع الأذان يخلي السجل فاضياً، فيصير
  /// الأذان الشغّال عرضة للاإلغاء من أي إعادة جدولة — وهذا بالضبط العطل الذي
  /// منعتُه. الحفظ رخيص: خريطة صغيرة عدد إشعارات فقط.
  Future<void> _persistAdhanSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, int>{
        for (final entry in _adhanSlots.entries)
          '${entry.key}': entry.value.millisecondsSinceEpoch,
      };
      await prefs.setString(_prefAdhanSlotsKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Could not persist adhan slots: $e');
    }
  }

  Future<void> _loadAdhanSlots() async {
    if (_slotsLoaded) return;
    _slotsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefAdhanSlotsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final id = int.tryParse(key);
        final ms = value as int?;
        if (id != null && ms != null) {
          _adhanSlots[id] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      });
    } catch (e) {
      debugPrint('Could not load adhan slots: $e');
    }
  }

  /// Removes adhan notifications that belong to past days.
  ///
  /// A stale adhan (its prayer time is more than [_adhanGraceMinutes] behind) is
  /// cleaned up on app resume so the notification shade does not accumulate
  /// yesterday's azans, while the current adhan stays exactly where it is.
  Future<void> cleanupStaleAdhanNotifications() async {
    if (kIsWeb) return;
    await _loadAdhanSlots();
    final now = DateTime.now();
    final ids = _adhanSlots.keys.toList();
    for (final id in ids) {
      final scheduled = _adhanSlots[id];
      if (scheduled == null) continue;
      if (now.difference(scheduled).inMinutes < _adhanGraceMinutes) continue;
      // Keep the notification of a past prayer that never finished today.
      if (scheduled.year == now.year &&
          scheduled.month == now.month &&
          scheduled.day == now.day) {
        continue;
      }
      _adhanSlots.remove(id);
      try {
        await _notificationsPlugin.cancel(id: id);
      } catch (_) {}
    }
    unawaited(_persistAdhanSlots());
  }

  /// Initialize system notification service for Android & iOS
  Future<void> init() async {
    // An adhan from a previous day may still be on screen if it was never
    // stopped; clear it on the next launch so only today's adhans remain.
    unawaited(cleanupStaleAdhanNotifications());
    // استقبال ضغطات أزرار الصوت من الطبقة الأصلية لإيقاف صوت الأذان فوراً.
    // ملاحظة مقصودة: ضغط زر الصوت يوقف الصوت والاهتزاز فقط ويترك الإشعار
    // ثابتاً على الشاشة — الإلغاء النهائي للمستخدم حصراً.
    try {
      PlatformPermissions.channel.setMethodCallHandler((call) async {
        if (call.method == 'volumeButtonPressed') {
          stopAzanSound();
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
        onDidReceiveBackgroundNotificationResponse: _adhanBackgroundResponse,
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
          // Audible alarm (adhan sound + vibration). Notification-only mode:
          // the notification is the whole alert — «إيقاف الأذان» stops it via a
          // silent background handler without launching the app.
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

          // ── Channel 3: Pre-prayer reminder (10 min before) ──────────────────
          try {
            await androidPlugin.createNotificationChannel(
              AndroidNotificationChannel(
                _prePrayerChannelId,
                _prePrayerChannelName,
                description: _prePrayerChannelDescription,
                importance: Importance.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('iqtarabat'),
                enableVibration: true,
                vibrationPattern: _prePrayerVibrationPattern,
                enableLights: true,
                audioAttributesUsage: AudioAttributesUsage.alarm,
              ),
            );
          } catch (e) {
            debugPrint('Pre-prayer channel creation error: $e');
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
    String sound = 'adhan',
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
  }) {
    final active = _prayerScheduleOperation;
    if (active != null) return active;

    final operation = _schedulePrayerNotifications(
      prayerTimes: prayerTimes,
      isArabic: isArabic,
      lat: lat,
      lng: lng,
    );
    _prayerScheduleOperation = operation;
    return operation.whenComplete(() {
      if (identical(_prayerScheduleOperation, operation)) {
        _prayerScheduleOperation = null;
      }
    });
  }

  Future<void> _schedulePrayerNotifications({
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
      await cancelAllScheduledAdhans();
      debugPrint('Alerts disabled — cancelled all scheduled notifications');
      return;
    }

    final now = DateTime.now();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();
    final canFullScreen = await PlatformPermissions.canUseFullScreenIntent();

    int scheduledCount = 0;
    debugPrint(
      'schedulePrayerNotifications: canFullScreen=$canFullScreen, canExact=$canExact',
    );
    for (final entry in prayerLabels.entries) {
      final key = entry.key;
      final time = prayerTimes[key];
      final notifId = entry.value.$3;

      if (time == null) continue;

      // Cancel the stale pre-prayer reminders for this slot first — both the
      // current ids (5001..5005) and the legacy `notifId + 100` ones, which
      // used to collide with the day-10 adhan and never fired. The adhan slot
      // is released inside the guard below, which refuses to touch an adhan
      // that is currently sounding.
      final preNotifId = _prePrayerId(0, notifId - 100);
      try {
        await _notificationsPlugin.cancel(id: notifId + 100);
      } catch (_) {}
      try {
        await _notificationsPlugin.cancel(id: preNotifId);
      } catch (_) {}

      // Check if this specific prayer is enabled by user
      if (userPrefs[key] != true) {
        // A prayer switched off must also drop whatever was scheduled for it
        // earlier — its adhan would otherwise keep firing.
        await _releaseAdhanSlot(notifId);
        continue;
      }
      final labelAr = entry.value.$1;
      final labelEn = entry.value.$2;

      // 1. Schedule the adhan itself for the exact prayer time: one audible
      // alarm notification that stays until the user stops it. The pre-prayer
      // reminder is a separate notification and is not counted as a second adhan.
      if (time.isAfter(now)) {
        // The adhan slot owns `notifId` from here on; a live azan is never
        // cancelled by a re-schedule (an app restart mid-azan must not silence
        // the azan the user is already hearing).
        await _setAdhanSlot(notifId, time);

        final title = isArabic
            ? 'الله أكبر • حان الآن موعد أذان $labelAr'
            : 'Adhan $labelEn • Prayer Time';
        final body = isArabic
            ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»'
            : 'Come to prayer, come to success.';

        final tzTime = tz.TZDateTime.from(time, tz.local);

        // Adhan delivery: one audible alarm notification (adhan.mp3 +
        // vibration) that stays on screen until the user stops it.
        final details = _adhanNotificationDetails();

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
          debugPrint(
            'Scheduled $key at $time (exact=$canExact, fullScreen=$canFullScreen)',
          );
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
            debugPrint(
              'Scheduled $key at $time (inexact, fullScreen=$canFullScreen)',
            );
          } catch (err) {
            debugPrint(
              'Error scheduling adhan notification for $key: $err (fullScreen=$canFullScreen)',
            );
          }
        }
      } else {
        debugPrint('Skipped $key at $time (already past)');
      }

      // 2. «اقتربت الصلاة — أقم صلاتك»: تنبيه مستقل قبل الأذان بعشر دقائق.
      // لا علاقة له بإشعار الأذان ولا يتأثر به، ويزول لحاله بعد ما ينبّه.
      final preTime = time.subtract(const Duration(minutes: 10));
      if (preTime.isAfter(now)) {
        final preTitle = isArabic
            ? 'اقتربت صلاة $labelAr ⏳'
            : 'Prayer Time Approaching • $labelEn';
        final preBody = isArabic
            ? 'متبقي ١٠ دقائق على موعد أذان $labelAr — «أقم صلاتك واستعد للوضوء»'
            : '10 minutes remaining until $labelEn — prepare for prayer.';
        final preTzTime = tz.TZDateTime.from(preTime, tz.local);

        try {
          await _notificationsPlugin.zonedSchedule(
            id: preNotifId,
            title: preTitle,
            body: preBody,
            scheduledDate: preTzTime,
            notificationDetails: _prePrayerNotificationDetails(),
            payload: 'pre_prayer:$key',
            androidScheduleMode: canExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
          debugPrint('Scheduled pre-prayer for $key at $preTime');
        } catch (e) {
          debugPrint('Error scheduling pre-prayer for $key: $e');
        }
      }
    }

    debugPrint('Scheduled $scheduledCount notifications for today');

    // Auto-schedule the rolling window so alerts keep firing after midnight.
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
      daysToSchedule: scheduleWindowDays,
    );

    // جدولة إشعارات مستحقي الزكاة والأضحية
    await scheduleBeneficiaryNotifications(isArabic: isArabic);
  }

/// How far ahead the adhan schedule is seeded, in days. Android too lets only
  /// a bounded number of alarms exist anyway, so the schedule is a rolling
  /// window: every time the app opens (or an adhan fires while it is alive)
  /// [ensureScheduleToppedUp] pushes the window forward, so alerts never run
  /// out while the app is used even occasionally.
  static const int scheduleWindowDays = 30;

  /// Last time the full schedule was (re)seeded, as milliseconds since epoch.
  /// Kept in memory only — it is a throttle, not app state.
  int _lastScheduleSeedMs = 0;

  /// Re-seeds + tops up the schedule, but at most once every 12 hours so
  /// repeated app opens do not hammer the alarm APIs with ~700 writes.
  Future<void> ensureScheduleToppedUp({bool force = false}) async {
    if (kIsWeb) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && nowMs - _lastScheduleSeedMs < const Duration(hours: 12).inMilliseconds) {
      return;
    }
    _lastScheduleSeedMs = nowMs;

    final prefs = await getAlertPreferences();
    if (prefs['enabled'] != true) return;

    final storage = DhikrStorage();
    final saved = storage.getSavedLocation();
    final lat = (saved?['lat'] as num?)?.toDouble() ?? 33.3152;
    final lng = (saved?['lng'] as num?)?.toDouble() ?? 44.3661;
    final isArabic = storage.getSettings().language == AppLanguage.arabic;

    await scheduleUpcomingPrayers(
      lat: lat,
      lng: lng,
      isArabic: isArabic,
      daysToSchedule: scheduleWindowDays,
    );
  }
  Future<void> scheduleUpcomingPrayers({
    required double lat,
    required double lng,
    required bool isArabic,
    int daysToSchedule = scheduleWindowDays,
  }) {
    final active = _upcomingScheduleOperation;
    if (active != null) return active;

    final operation = _scheduleUpcomingPrayers(
      lat: lat,
      lng: lng,
      isArabic: isArabic,
      daysToSchedule: daysToSchedule,
    );
    _upcomingScheduleOperation = operation;
    return operation.whenComplete(() {
      if (identical(_upcomingScheduleOperation, operation)) {
        _upcomingScheduleOperation = null;
      }
    });
  }

  Future<void> _scheduleUpcomingPrayers({
    required double lat,
    required double lng,
    required bool isArabic,
    int daysToSchedule = scheduleWindowDays,
  }) async {
    if (kIsWeb) return;
    await init();

    final userPrefs = await getAlertPreferences();
    if (userPrefs['enabled'] != true) {
      // Alerts are off — wipe the whole adhan + pre-prayer schedule.
      await cancelAllScheduledAdhans();
      return;
    }

    final now = DateTime.now();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();
    final canFullScreen = await PlatformPermissions.canUseFullScreenIntent();

    final prayers = [
      ('fajr', 'الفجر', 'Fajr', 1),
      ('dhuhr', 'الظهر', 'Dhuhr', 2),
      ('asr', 'العصر', 'Asr', 3),
      ('maghrib', 'المغرب', 'Maghrib', 4),
      ('isha', 'العشاء', 'Isha', 5),
    ];

    // Schedule for day 1 onwards (day 0 is already handled by schedulePrayerNotifications).
    // Adhan ids are `100 + dayOffset * 10 + prayerIndex` (111..405); the
    // «اقتربت الصلاة» ids live in their own block via [_prePrayerId]
    // (5011..5305), so the two schedules can never overwrite each other.
    for (int dayOffset = 1; dayOffset <= daysToSchedule; dayOffset++) {
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
        final preNotifId = _prePrayerId(dayOffset, prayerIndex);
        // The old scheme (`200 + day*10 + index`) collided with the adhan ids
        // of days 11–30 and with Eid's 501 — clear those leftovers as well.
        final legacyPreNotifId = 200 + (dayOffset * 10) + prayerIndex;

        // Cancel the stale pre-prayer reminders for this slot — current and
        // legacy ids — before anything else. The adhan slot is released inside
        // the guard below, which refuses to touch an adhan that is sounding.
        try {
          await _notificationsPlugin.cancel(id: preNotifId);
        } catch (_) {}
        try {
          await _notificationsPlugin.cancel(id: legacyPreNotifId);
        } catch (_) {}

        if (userPrefs[key] != true) {
          // A prayer switched off must also drop its scheduled adhans, or the
          // ones queued by an earlier run keep firing.
          await _releaseAdhanSlot(notifId);
          continue;
        }

        final time = times[key];
        if (time == null || !time.isAfter(now)) continue;

        // Same ownership rule as today's adhans: never cancel an azan that is
        // currently sounding just because the rolling window is re-seeded.
        await _setAdhanSlot(notifId, time);

        final title = isArabic
            ? 'الله أكبر • حان الآن موعد أذان $labelAr'
            : 'Adhan $labelEn • Prayer Time';
        final body = isArabic
            ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»'
            : 'Come to prayer, come to success.';

        final tzTime = tz.TZDateTime.from(time, tz.local);

        // Adhan delivery: one audible alarm notification (adhan.mp3 +
        // vibration) that stays on screen until the user stops it.
        final details = _adhanNotificationDetails();

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
          debugPrint(
            'Scheduled $key +$dayOffset days at $time (exact=$canExact, fullScreen=$canFullScreen)',
          );
        } catch (e) {
          debugPrint(
            'Schedule failed for $key +$dayOffset: $e — trying inexact (fullScreen=$canFullScreen)',
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
              androidScheduleMode:
                  await PlatformPermissions.canScheduleExactAlarms()
                  ? AndroidScheduleMode.exactAllowWhileIdle
                  : AndroidScheduleMode.inexactAllowWhileIdle,
            );
            debugPrint(
              'Scheduled $key +$dayOffset (inexact, fullScreen=$canFullScreen)',
            );
          } catch (err) {
            debugPrint(
              'Error scheduling upcoming prayer notification $notifId: $err',
            );
          }
        }

        final preTime = time.subtract(const Duration(minutes: 10));
        if (preTime.isAfter(now)) {
          final preTitle = isArabic
              ? 'اقتربت صلاة $labelAr ⏳'
              : 'Prayer Time Approaching • $labelEn';
          final preBody = isArabic
              ? 'متبقي ١٠ دقائق على موعد أذان $labelAr — «أقم صلاتك واستعد للوضوء»'
              : '10 minutes remaining until $labelEn — prepare for prayer.';
          final preTzTime = tz.TZDateTime.from(preTime, tz.local);

          try {
            await _notificationsPlugin.zonedSchedule(
              id: preNotifId,
              title: preTitle,
              body: preBody,
              scheduledDate: preTzTime,
              notificationDetails: _prePrayerNotificationDetails(),
              payload: 'pre_prayer:$key',
              androidScheduleMode: canExact
                  ? AndroidScheduleMode.exactAllowWhileIdle
                  : AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } catch (_) {}
        }
      }
    }
  }

  /// يوقف صوت الأذان والاهتزاز فقط ولا يمسّ الإشعار — يُستدعى من كل حالة
  /// إسكات غير نهائية (زر الصوت، انتهاء الملف، الدخول للتطبيق).
  Future<void> stopAzanSound() async {
    _isPlaying = false;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await PlatformPermissions.stopAdhanVibration();
    } catch (_) {}
  }

  /// إيقاف نهائي يطلبه المستخدم بنفسه (زر «إيقاف الأذان» أو الدوسة على الإشعار):
  /// يطفي الصوت ويحذف إشعار الأذان الشغّال، ولا يلمس باقي الأذانات المجدولة.
  Future<void> stopAzan() async {
    await stopAzanSound();
    try {
      await cancelAdhanNotifications();
    } catch (_) {}
    _azanFinishedController.add(null);
  }

  /// Stops the *currently firing* adhan only.
  ///
  /// Only ids whose slot time is still inside the adhan grace window are
  /// cancelled, so this never touches the adhan notifications scheduled for
  /// later prayers or for the coming days.
  Future<void> cancelAdhanNotifications() async {
    try {
      await _notificationsPlugin.cancel(id: _adhanPreviewId);
      for (final id in todayAdhanIds) {
        if (!isAdhanActive(id)) continue;
        _adhanSlots.remove(id);
        await _notificationsPlugin.cancel(id: id);
      }
      final firedId = _lastFiredAdhanId;
      if (firedId != null) {
        _adhanSlots.remove(firedId);
        await _notificationsPlugin.cancel(id: firedId);
        _lastFiredAdhanId = null;
      }
    } catch (e) {
      debugPrint('Error cancelling the active adhan notification: $e');
    }
    unawaited(_persistAdhanSlots());
  }

  /// Cancels every adhan scheduled in the rolling window (and all
  /// pre-prayer reminders). Used when the user turns prayer alerts off, so the
  /// schedule can be re-seeded cleanly from scratch.
  Future<void> cancelAllScheduledAdhans({int? days}) async {
    final window = days ?? scheduleWindowDays;
    try {
      for (int dayOffset = 0; dayOffset <= window; dayOffset++) {
        for (int prayer = 1; prayer <= 5; prayer++) {
          await _notificationsPlugin.cancel(
            id: 100 + (dayOffset * 10) + prayer,
          );
          await _notificationsPlugin.cancel(
            id: _prePrayerId(dayOffset, prayer),
          );
          // Legacy pre-prayer ids (old installs) — kept in the wipe so a
          // schedule left over from the old scheme is fully cleared.
          await _notificationsPlugin.cancel(
            id: 200 + (dayOffset * 10) + prayer,
          );
        }
      }
      // The whole schedule is gone, so no slot keeps owning a live adhan.
      _adhanSlots.clear();
      _lastFiredAdhanId = null;
      unawaited(_persistAdhanSlots());
    } catch (e) {
      debugPrint('Error cancelling all scheduled adhans: $e');
    }
  }

  Future<void> playAzan() async {
    try {
      // In-app playback only: the system adhan notification stays exactly where
      // it is (its own azan is heard once and remains until the user stops it).
      await stopAzanSound();
      _player ??= AudioPlayer();
      await _player?.stop();
      await _player?.setReleaseMode(ReleaseMode.stop);
      _playerCompleteSub?.cancel();
      _playerCompleteSub = _player?.onPlayerComplete.listen((_) {
        _isPlaying = false;
        Future.microtask(stopAzan);
      });
      _isPlaying = true;
      await _player?.play(AssetSource('audio/adhan.mp3'));
    } catch (e) {
      _isPlaying = false;
      debugPrint('Error playing adhan: $e');
    }
  }

  /// Plays the pre-prayer audio clip «اقتربت الصلاة أقم صلاتك»
  Future<void> playPrePrayerPreview() async {
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      await _player?.play(AssetSource('audio/iqtarabat.mp3'));
    } catch (e) {
      debugPrint('Error playing pre-prayer preview: $e');
    }
  }

  /// Schedules an accelerated end-to-end preview:
  /// pre-prayer reminder after 2 seconds, then the full adhan 15 seconds later.
  Future<void> scheduleAlertPreview({bool isArabic = true}) async {
    if (kIsWeb) return;
    await init();

    final now = DateTime.now();
    final preTime = tz.TZDateTime.from(
      now.add(const Duration(seconds: 2)),
      tz.local,
    );
    final adhanTime = tz.TZDateTime.from(
      now.add(const Duration(seconds: 17)),
      tz.local,
    );
    const prayerAr = 'الظهر';
    const prayerEn = 'Dhuhr';

    await cancelAlertPreview();

    await _notificationsPlugin.zonedSchedule(
      id: 990,
      title: isArabic
          ? 'اقتربت صلاة $prayerAr ⏳'
          : 'Prayer Time Approaching • $prayerEn',
      body: isArabic
          ? 'معاينة: اقتربت الصلاة — أقم صلاتك واستعد للوضوء'
          : 'Preview: prayer time approaching — prepare for prayer.',
      scheduledDate: preTime,
      notificationDetails: _prePrayerNotificationDetails(),
      payload: 'pre_prayer:preview',
      androidScheduleMode: await PlatformPermissions.canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    // تُسجَّل المعاينة كصاحب أذان كذلك، حتى يسري عليها نفس منطق الإلغاء:
    // زر «إيقاف الأذان» يلغي المعاينة الشغّالة ولا يلمس الأذانات الحقيقية.
    await _setAdhanSlot(_adhanPreviewId, adhanTime);

    await _notificationsPlugin.zonedSchedule(
      id: _adhanPreviewId,
      title: isArabic
          ? 'الله أكبر • حان الآن موعد أذان $prayerAr'
          : 'Adhan $prayerEn • Prayer Time',
      body: isArabic
          ? '«حَيَّ عَلَى الصَّلَاةِ • حَيَّ عَلَى الْفَلَاحِ»'
          : 'Come to prayer, come to success.',
      scheduledDate: adhanTime,
      notificationDetails: _adhanNotificationDetails(),
      payload: const AdhanAlert(
        prayerNameAr: prayerAr,
        prayerNameEn: prayerEn,
      ).payload,
      androidScheduleMode: await PlatformPermissions.canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAlertPreview() async {
    if (kIsWeb) return;
    _adhanSlots.remove(_adhanPreviewId);
    unawaited(_persistAdhanSlots());
    await _notificationsPlugin.cancel(id: 990);
    await _notificationsPlugin.cancel(id: _adhanPreviewId);
  }

  /// جدولة إشعارات مستحقي الزكاة والأضحية في الإشعارات العامة
  Future<void> scheduleBeneficiaryNotifications({
    required bool isArabic,
  }) async {
    if (kIsWeb) return;
    await init();

    final now = DateTime.now();

    // إشعار مستحقي الزكاة — كل يوم 1 من كل شهر (أو أي ميعاد مناسب)
    final zakatDay = DateTime(now.year, now.month, 1);
    final zakatTime = zakatDay.isAfter(now)
        ? zakatDay
        : DateTime(now.year, now.month + 1, 1);
    final zakatTz = tz.TZDateTime.from(zakatTime, tz.local);

    final zakatTitle = isArabic ? 'تذكير بالزكاة' : 'Zakat Reminder';
    final zakatBody = isArabic
        ? 'حان موعد إخراج الزكاة — تحقق من مستحقي الزكاة في التطبيق'
        : 'Time to pay your Zakat — check beneficiaries in the app';

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 500,
        title: zakatTitle,
        body: zakatBody,
        scheduledDate: zakatTz,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _dhikrChannelId,
            _dhikrChannelName,
            channelDescription: _dhikrChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Scheduled zakat beneficiary notification at $zakatTime');
    } catch (e) {
      debugPrint('Error scheduling zakat notification: $e');
    }

    // إشعار مستحقي الأضحية — يوم 10 ذي الحجة (عيد الأضحى)
    final eidDate = _hijriToGregorian(_currentHijriYear(), 12, 10);
    final eidTime = eidDate.isAfter(now)
        ? eidDate
        : _hijriToGregorian(_currentHijriYear() + 1, 12, 10);
    final eidTz = tz.TZDateTime.from(eidTime, tz.local);

    final eidTitle = isArabic ? 'عيد الأضحى المبارك' : 'Eid al-Adha';
    final eidBody = isArabic
        ? 'كل عام وأنتم بخير — تحقق من مستحقي الأضحية في التطبيق'
        : 'Happy Eid — check Udhiyah beneficiaries in the app';

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 501,
        title: eidTitle,
        body: eidBody,
        scheduledDate: eidTz,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _dhikrChannelId,
            _dhikrChannelName,
            channelDescription: _dhikrChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Scheduled Eid al-Adha beneficiary notification at $eidTime');
    } catch (e) {
      debugPrint('Error scheduling Eid notification: $e');
    }
  }

  /// تحويل التاريخ الهجري إلى ميلادي (خوارزمية Um al-Qura المبسطة)
  DateTime _hijriToGregorian(int hYear, int hMonth, int hDay) {
    final jd = _hijriToJulianDay(hYear, hMonth, hDay);
    return _julianDayToGregorian(jd);
  }

  int _hijriToJulianDay(int year, int month, int day) {
    return ((11 * year + 3) ~/ 30) +
        354 * year +
        30 * month -
        ((month < 3) ? 1 : 0) +
        day +
        1948440 -
        385;
  }

  DateTime _julianDayToGregorian(int jd) {
    final l = jd + 68569;
    final n = ((4 * l) ~/ 146097);
    final l2 = l - ((146097 * n + 3) ~/ 4);
    final i = ((4000 * (l2 + 1)) ~/ 1461001);
    final l3 = l2 - ((1461 * i) ~/ 4) + 31;
    final j = ((80 * l3) ~/ 2447);
    final day = l3 - ((2447 * j) ~/ 80);
    final l4 = (j ~/ 11);
    final month = j + 2 - 12 * l4;
    final year = 100 * (n - 49) + i + l4;
    return DateTime(year, month, day);
  }

  /// حساب السنة الهجرية الحالية من التاريخ الميلادي
  int _currentHijriYear() {
    final now = DateTime.now();
    final jd = _gregorianToJulianDay(now.year, now.month, now.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631) * 1;
    final l2 = l - 10631 * n + 354;
    final j2 =
        ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
        (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
    return (n * 30 + j2 - 30).toInt();
  }

  int _gregorianToJulianDay(int year, int month, int day) {
    final a = ((14 - month) ~/ 12).toInt();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }
}
