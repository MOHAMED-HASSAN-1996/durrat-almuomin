import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/aladhan_service.dart';
import '../services/home_widget_service.dart';
import '../services/location_label.dart';
import '../services/prayer_alert_service.dart';
import '../services/prayer_times.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/nawafil_tracker_sheet.dart';
import '../widgets/app_toast.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  // Coordinates & City — Default: Baghdad, Iraq
  double _lat = 33.3152;
  double _lng = 44.3661;
  String _city = 'بغداد';
  String _cityEn = 'Baghdad';
  String _province = '';
  String _provinceEn = '';
  String _country = 'العراق';
  String _countryEn = 'Iraq';
  String _resolvedCountryCode = '';

  /// بصمة الموقع اللي الشاشة متطبّقة عليها دلوقتي.
  ///
  /// أي تغيير في [AppState.locationSignature] جاي من شاشة تانية (الصلاحيات،
  /// الرئيسية، البوصلة) بيخلّي الشاشة دي تعيد الحساب بدل ما تفضل على
  /// المكان القديم لحد ما المستخدم يقفلها ويفتحها تاني.
  String _appliedLocationSignature = '';

  /// true جوه [_applyAndSaveLocation]: الكتابة بتاعتنا هي اللي غيّرت المكان،
  /// فمش نعيد تطبيقها على الشاشة مرتين.
  bool _writingLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLocationFromAppState();
  }

  /// يسحب الموقع الموحّد من [AppState] ويطبّقه على الشاشة لو اتغيّر.
  void _syncLocationFromAppState() {
    if (_writingLocation) return;
    final appState = context.read<AppState>();
    final signature = appState.locationSignature;
    if (signature.isEmpty || signature == _appliedLocationSignature) return;
    _appliedLocationSignature = signature;

    final loc = appState.location;
    if (loc == null) return;
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    // نفس الإحداثيات: الأسماء بس اللي اتغيّرت (مثل إعادة جلب الاسم بعد
    // فشل الشبكة)، فحدّث الأسماء من غير إعادة طلب مواقيت الصلاة.
    if ((lat - _lat).abs() < 1e-7 && (lng - _lng).abs() < 1e-7) {
      if (!mounted) return;
      setState(() {
        _city = (loc['cityAr'] as String?) ?? _city;
        _cityEn = (loc['cityEn'] as String?) ?? _cityEn;
        _province = (loc['provinceAr'] as String?) ?? _province;
        _provinceEn = (loc['provinceEn'] as String?) ?? _provinceEn;
        _country = (loc['countryAr'] as String?) ?? _country;
        _countryEn = (loc['countryEn'] as String?) ?? _countryEn;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
      _city = (loc['cityAr'] as String?) ?? _city;
      _cityEn = (loc['cityEn'] as String?) ?? _cityEn;
      _province = (loc['provinceAr'] as String?) ?? _province;
      _provinceEn = (loc['provinceEn'] as String?) ?? _provinceEn;
      _country = (loc['countryAr'] as String?) ?? _country;
      _countryEn = (loc['countryEn'] as String?) ?? _countryEn;
      _locateFailed = false;
    });

    // المكان اتغيّر من برّه: المواقيت كلّها بتتغيّر، فجيبها من جديد.
    _apiTimes = null;
    _fetchApiPrayerTimes();
  }

  bool _locating = false;
  bool _locateFailed = false;
  Timer? _timer;

  // Aladhan API prayer times (null = not yet loaded / loading)
  Map<String, DateTime>? _apiTimes;
  bool _loadingApiTimes = false;

  // Audio player for Adhan / Prayer reminders
  AudioPlayer? _adhanPlayer;
  bool _isPlayingAdhan = false;
  int _selectedAdhanIndex = 0;
  String? _lastTriggeredPrayerKey;
  String? _activePrayerNameAr;
  String? _activePrayerNameEn;

  static const List<Map<String, String>> _adhanOptions = [
    {
      'id': 'alafasy',
      'nameAr': 'أذان الشيخ مشاري راشد العفاسي',
      'nameEn': 'Sheikh Mishary Rashid Alafasy Adhan',
      'url':
          'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    },
  ];

  // Preset famous cities around the world — includes all Egyptian Governorates & Key Islamic Cities
  static const List<Map<String, dynamic>> _famousCities = [
    // --- Egyptian Governorates & Cities ---
    {
      'ar': 'الإسكندرية',
      'en': 'Alexandria',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.2001,
      'lng': 29.9187,
    },
    {
      'ar': 'القاهرة',
      'en': 'Cairo',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.0444,
      'lng': 31.2357,
    },
    {
      'ar': 'الجيزة',
      'en': 'Giza',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.0131,
      'lng': 31.2089,
    },
    {
      'ar': 'المنصورة',
      'en': 'Mansoura',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.0409,
      'lng': 31.3785,
    },
    {
      'ar': 'طنطا',
      'en': 'Tanta',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.7865,
      'lng': 31.0004,
    },
    {
      'ar': 'بورسعيد',
      'en': 'Port Said',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.2653,
      'lng': 32.3019,
    },
    {
      'ar': 'السويس',
      'en': 'Suez',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 29.9668,
      'lng': 32.5498,
    },
    {
      'ar': 'الإسماعيلية',
      'en': 'Ismailia',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.5965,
      'lng': 32.2715,
    },
    {
      'ar': 'الزقازيق',
      'en': 'Zagazig',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.5877,
      'lng': 31.5020,
    },
    {
      'ar': 'أسيوط',
      'en': 'Asyut',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 27.1783,
      'lng': 31.1859,
    },
    {
      'ar': 'سوهاج',
      'en': 'Sohag',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 26.5569,
      'lng': 31.6948,
    },
    {
      'ar': 'قنا',
      'en': 'Qena',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 26.1551,
      'lng': 32.7160,
    },
    {
      'ar': 'الأقصر',
      'en': 'Luxor',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 25.6872,
      'lng': 32.6396,
    },
    {
      'ar': 'أسوان',
      'en': 'Aswan',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 24.0889,
      'lng': 32.8998,
    },
    {
      'ar': 'دمياط',
      'en': 'Damietta',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.4175,
      'lng': 31.8144,
    },
    {
      'ar': 'الغردقة',
      'en': 'Hurghada',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 27.2579,
      'lng': 33.8116,
    },
    {
      'ar': 'شرم الشيخ',
      'en': 'Sharm El-Sheikh',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 27.9158,
      'lng': 34.3299,
    },
    {
      'ar': 'مطروح',
      'en': 'Marsa Matruh',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.3543,
      'lng': 27.2373,
    },
    {
      'ar': 'دمنهور',
      'en': 'Damanhour',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.0425,
      'lng': 30.4703,
    },
    {
      'ar': 'كفر الشيخ',
      'en': 'Kafr El Sheikh',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 31.1107,
      'lng': 30.9388,
    },
    {
      'ar': 'شبين الكوم',
      'en': 'Shibin El Kom',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.5526,
      'lng': 31.0090,
    },
    {
      'ar': 'بنها',
      'en': 'Banha',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 30.4660,
      'lng': 31.1853,
    },
    {
      'ar': 'الفيوم',
      'en': 'Fayoum',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 29.3084,
      'lng': 30.8428,
    },
    {
      'ar': 'بني سويف',
      'en': 'Beni Suef',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 29.0661,
      'lng': 31.0994,
    },
    {
      'ar': 'المنيا',
      'en': 'Minya',
      'countryAr': 'مصر',
      'countryEn': 'Egypt',
      'lat': 28.0871,
      'lng': 30.7618,
    },

    // --- Key Islamic & World Cities ---
    {
      'ar': 'مكة المكرمة',
      'en': 'Makkah',
      'countryAr': 'السعودية',
      'countryEn': 'Saudi Arabia',
      'lat': 21.4225,
      'lng': 39.8262,
    },
    {
      'ar': 'المدينة المنورة',
      'en': 'Madinah',
      'countryAr': 'السعودية',
      'countryEn': 'Saudi Arabia',
      'lat': 24.4672,
      'lng': 39.6111,
    },
    {
      'ar': 'القدس الشريف',
      'en': 'Jerusalem',
      'countryAr': 'فلسطين',
      'countryEn': 'Palestine',
      'lat': 31.7683,
      'lng': 35.2137,
    },
    {
      'ar': 'الرياض',
      'en': 'Riyadh',
      'countryAr': 'السعودية',
      'countryEn': 'Saudi Arabia',
      'lat': 24.7136,
      'lng': 46.6753,
    },
    {
      'ar': 'جدة',
      'en': 'Jeddah',
      'countryAr': 'السعودية',
      'countryEn': 'Saudi Arabia',
      'lat': 21.4858,
      'lng': 39.1925,
    },
    {
      'ar': 'دبي',
      'en': 'Dubai',
      'countryAr': 'الإمارات',
      'countryEn': 'UAE',
      'lat': 25.2048,
      'lng': 55.2708,
    },
    {
      'ar': 'أبوظبي',
      'en': 'Abu Dhabi',
      'countryAr': 'الإمارات',
      'countryEn': 'UAE',
      'lat': 24.4539,
      'lng': 54.3773,
    },
    {
      'ar': 'الدوحة',
      'en': 'Doha',
      'countryAr': 'قطر',
      'countryEn': 'Qatar',
      'lat': 25.2854,
      'lng': 51.5310,
    },
    {
      'ar': 'الكويت',
      'en': 'Kuwait City',
      'countryAr': 'الكويت',
      'countryEn': 'Kuwait',
      'lat': 29.3759,
      'lng': 47.9774,
    },
    {
      'ar': 'مسقط',
      'en': 'Muscat',
      'countryAr': 'عُمان',
      'countryEn': 'Oman',
      'lat': 23.5880,
      'lng': 58.3829,
    },
    {
      'ar': 'عَمّان',
      'en': 'Amman',
      'countryAr': 'الأردن',
      'countryEn': 'Jordan',
      'lat': 31.9454,
      'lng': 35.9284,
    },
    // --- مدن ومحافظات العراق ---
    {
      'ar': 'بغداد',
      'en': 'Baghdad',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 33.3152,
      'lng': 44.3661,
    },
    {
      'ar': 'النجف الأشرف',
      'en': 'Najaf',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 32.0259,
      'lng': 44.3462,
    },
    {
      'ar': 'كربلاء المقدسة',
      'en': 'Karbala',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 32.6160,
      'lng': 44.0249,
    },
    {
      'ar': 'البصرة',
      'en': 'Basra',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 30.5081,
      'lng': 47.7835,
    },
    {
      'ar': 'الموصل',
      'en': 'Mosul',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 36.3400,
      'lng': 43.1300,
    },
    {
      'ar': 'أربيل',
      'en': 'Erbil',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 36.1911,
      'lng': 44.0092,
    },
    {
      'ar': 'السليمانية',
      'en': 'Sulaymaniyah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 35.5574,
      'lng': 45.4347,
    },
    {
      'ar': 'كركوك',
      'en': 'Kirkuk',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 35.4681,
      'lng': 44.3922,
    },
    {
      'ar': 'الحلة (بابل)',
      'en': 'Hillah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 32.4833,
      'lng': 44.4333,
    },
    {
      'ar': 'الناصرية (ذي قار)',
      'en': 'Nasiriyah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 31.0439,
      'lng': 46.2578,
    },
    {
      'ar': 'العمارة (ميسان)',
      'en': 'Amarah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 31.8439,
      'lng': 47.1444,
    },
    {
      'ar': 'الديوانية (القادسية)',
      'en': 'Diwaniyah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 31.9889,
      'lng': 44.9250,
    },
    {
      'ar': 'الكوت (واسط)',
      'en': 'Kut',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 32.5128,
      'lng': 45.8178,
    },
    {
      'ar': 'الرمادي (الأنبار)',
      'en': 'Ramadi',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 33.4244,
      'lng': 43.2994,
    },
    {
      'ar': 'سامراء',
      'en': 'Samarra',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 34.1983,
      'lng': 43.8742,
    },
    {
      'ar': 'بعقوبة (ديالى)',
      'en': 'Baqubah',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 33.7436,
      'lng': 44.6442,
    },
    {
      'ar': 'دهوك',
      'en': 'Duhok',
      'countryAr': 'العراق',
      'countryEn': 'Iraq',
      'lat': 36.8679,
      'lng': 42.9886,
    },
    {
      'ar': 'بيروت',
      'en': 'Beirut',
      'countryAr': 'لبنان',
      'countryEn': 'Lebanon',
      'lat': 33.8938,
      'lng': 35.5018,
    },
    {
      'ar': 'دمشق',
      'en': 'Damascus',
      'countryAr': 'سوريا',
      'countryEn': 'Syria',
      'lat': 33.5138,
      'lng': 36.2765,
    },
    {
      'ar': 'طرابلس',
      'en': 'Tripoli',
      'countryAr': 'ليبيا',
      'countryEn': 'Libya',
      'lat': 32.8872,
      'lng': 13.1913,
    },
    {
      'ar': 'تونس',
      'en': 'Tunis',
      'countryAr': 'تونس',
      'countryEn': 'Tunisia',
      'lat': 36.8065,
      'lng': 10.1815,
    },
    {
      'ar': 'الجزائر',
      'en': 'Algiers',
      'countryAr': 'الجزائر',
      'countryEn': 'Algeria',
      'lat': 36.7538,
      'lng': 3.0588,
    },
    {
      'ar': 'الرباط',
      'en': 'Rabat',
      'countryAr': 'المغرب',
      'countryEn': 'Morocco',
      'lat': 34.0209,
      'lng': -6.8416,
    },
    {
      'ar': 'الخرطوم',
      'en': 'Khartoum',
      'countryAr': 'السودان',
      'countryEn': 'Sudan',
      'lat': 15.5007,
      'lng': 32.5599,
    },
    {
      'ar': 'صنعاء',
      'en': 'Sanaa',
      'countryAr': 'اليمن',
      'countryEn': 'Yemen',
      'lat': 15.3694,
      'lng': 44.1910,
    },
    {
      'ar': 'إسطنبول',
      'en': 'Istanbul',
      'countryAr': 'تركيا',
      'countryEn': 'Turkey',
      'lat': 41.0082,
      'lng': 28.9784,
    },
    {
      'ar': 'لندن',
      'en': 'London',
      'countryAr': 'بريطانيا',
      'countryEn': 'UK',
      'lat': 51.5074,
      'lng': -0.1278,
    },
    {
      'ar': 'باريس',
      'en': 'Paris',
      'countryAr': 'فرنسا',
      'countryEn': 'France',
      'lat': 48.8566,
      'lng': 2.3522,
    },
    {
      'ar': 'نيويورك',
      'en': 'New York',
      'countryAr': 'أمريكا',
      'countryEn': 'USA',
      'lat': 40.7128,
      'lng': -74.0060,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _checkPrayerArrival(DateTime.now());
      } else {
        timer.cancel();
      }
    });

    // Initialize Adhan Audio Player
    _adhanPlayer = AudioPlayer();
    _adhanPlayer?.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAdhan = state == PlayerState.playing;
        });
      }
    });

    // إيقاف الأذان عند ضغط زر الصوت (تعلية/خفض) — عبر القناة الأصلية.
    PrayerAlertService.onVolumeButtonPressed = () {
      _stopAdhan();
    };
    PrayerAlertService.instance.init();

    // 1. First restore saved location & adhan preference from persistent storage
    final appState = context.read<AppState>();
    final storage = appState.storage;
    final saved = storage.getSavedLocation();
    if (saved != null) {
      _lat = (saved['lat'] as num?)?.toDouble() ?? _lat;
      _lng = (saved['lng'] as num?)?.toDouble() ?? _lng;
      _city = (saved['cityAr'] as String?) ?? _city;
      _cityEn = (saved['cityEn'] as String?) ?? _cityEn;
      _province = (saved['provinceAr'] as String?) ?? _province;
      _provinceEn = (saved['provinceEn'] as String?) ?? _provinceEn;
      _country = (saved['countryAr'] as String?) ?? _country;
      _countryEn = (saved['countryEn'] as String?) ?? _countryEn;
    }
    // الموقع اللي قريناه فوق هو نفسه الموحّد، فسجّل بصمته عشان أول
    // استدعاء لـ didChangeDependencies ما يعتبرهوش تغيير جديد.
    _appliedLocationSignature = appState.locationSignature;
    _selectedAdhanIndex = storage.getSavedAdhanIndex().clamp(
      0,
      _adhanOptions.length - 1,
    );

    // 2. Automatically locate user (GPS -> IP fallback) + fetch API prayer times
    Future.microtask(() async {
      if (mounted) {
        _fetchApiPrayerTimes(); // fetch with default/saved location immediately
        await _tryAutoLocate(silent: saved != null);
      }
    });
  }

  void _checkPrayerArrival(DateTime now) {
    // Only update prayer arrival UI state.
    // Audio alerts and full-screen intents are cleanly and reliably handled
    // by PrayerAlertService to prevent multiple overlapping adhans!
    if (_isPlayingAdhan) return;
    final today = DateTime(now.year, now.month, now.day);
    final localTimes = PrayerCalculator.calculate(
      date: today,
      lat: _lat,
      lng: _lng,
    );
    final fajr = _apiTimes?['fajr'] ?? localTimes.fajr;
    final dhuhr = _apiTimes?['dhuhr'] ?? localTimes.dhuhr;
    final asr = _apiTimes?['asr'] ?? localTimes.asr;
    final maghrib = _apiTimes?['maghrib'] ?? localTimes.maghrib;
    final isha = _apiTimes?['isha'] ?? localTimes.isha;

    final prayers = [
      ('fajr', 'صلاة الفجر', 'Fajr Prayer', fajr),
      ('dhuhr', 'صلاة الظهر', 'Dhuhr Prayer', dhuhr),
      ('asr', 'صلاة العصر', 'Asr Prayer', asr),
      ('maghrib', 'صلاة المغرب', 'Maghrib Prayer', maghrib),
      ('isha', 'صلاة العشاء', 'Isha Prayer', isha),
    ];

    for (final p in prayers) {
      final pTime = p.$4;
      if (now.hour == pTime.hour && now.minute == pTime.minute) {
        final key = '${now.year}_${now.month}_${now.day}_${p.$1}';
        if (_lastTriggeredPrayerKey != key) {
          _lastTriggeredPrayerKey = key;
          if (mounted) {
            setState(() {
              _activePrayerNameAr = p.$2;
              _activePrayerNameEn = p.$3;
            });
          }
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (PrayerAlertService.onVolumeButtonPressed != null) {
      PrayerAlertService.onVolumeButtonPressed = null;
    }
    _adhanPlayer?.stop();
    _adhanPlayer?.dispose();
    super.dispose();
  }

  String _toArabicNum(int n) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i != null ? arabicDigits[i] : d;
    }).join();
  }

  // ignore: unused_element
  Future<void> _playAdhan([String? directUrl]) async {
    try {
      final index = _selectedAdhanIndex.clamp(0, _adhanOptions.length - 1);
      final url = directUrl ?? _adhanOptions[index]['url']!;
      await _adhanPlayer?.stop();
      await _adhanPlayer?.setReleaseMode(ReleaseMode.stop);
      await _adhanPlayer?.setVolume(1.0);
      await _adhanPlayer?.play(UrlSource(url));
      if (mounted) {
        setState(() => _isPlayingAdhan = true);
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      if (mounted) {
        _toast(
          arabic: 'تعذر تشغيل الأذان — يرجى التأكد من اتصال الإنترنت',
          english: 'Could not play Adhan — please check internet connection',
        );
      }
    }
  }

  Future<void> _stopAdhan() async {
    try {
      await _adhanPlayer?.stop();
      await PrayerAlertService.instance.stopAzan();
      await PlatformPermissions.stopAdhanVibration();
      if (mounted) {
        setState(() {
          _isPlayingAdhan = false;
          _activePrayerNameAr = null;
          _activePrayerNameEn = null;
        });
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Multi-tier Auto Locate:
  /// Tier 1: Device GPS (accurate within meters)
  /// Tier 2: IP-based Geolocation (works anywhere in the world without GPS/permissions)
  /// Tier 3: Cached/Saved location
  Future<void> _tryAutoLocate({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _locating = true;
        _locateFailed = false;
      });
      HapticFeedback.selectionClick();
    }

    bool success = false;

    // --- Tier 1: Try GPS first ---
    try {
      final gpsSuccess = await _tryGpsLocate();
      if (gpsSuccess) {
        success = true;
      }
    } catch (_) {
      // GPS not available or denied, gracefully fall through to IP
    }

    // --- Tier 2: If GPS was unavailable or denied, try IP geolocation ---
    if (!success) {
      try {
        final ipSuccess = await _tryIpLocate();
        if (ipSuccess) {
          success = true;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _locating = false;
      _locateFailed = !success && !silent;
    });

    if (success && !silent) {
      HapticFeedback.mediumImpact();
      _toast(
        arabic: 'تم تحديد موقعك بدقة: $_city ($_country) ✓',
        english: 'Location updated: $_cityEn ($_countryEn) ✓',
      );
    } else if (!success && !silent) {
      HapticFeedback.heavyImpact();
      _toast(
        arabic:
            'تعذر تحديد الموقع تلقائياً. تأكد من تفعيل GPS والإنترنت أو اختر مدينتك يدوياً.',
        english:
            'Could not detect location. Please enable GPS or select your city manually.',
      );
    }
  }

  Future<bool> _tryGpsLocate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    // Tier 1a: Fast path - check cached last known position first (immediate)
    Position? pos = await Geolocator.getLastKnownPosition();

    // Tier 1b: If unavailable or stale, request high-accuracy position
    pos ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );

    await _applyAndSaveLocation(
      lat: pos.latitude,
      lng: pos.longitude,
      resolveCity: true,
    );
    return true;
  }

  Future<bool> _tryIpLocate() async {
    // Provider 1: ip-api.com (Fastest global IP geolocator, ~150ms response, high reliability)
    try {
      final res = await http
          .get(
            Uri.parse(
              'http://ip-api.com/json/?fields=status,country,countryCode,region,regionName,city,lat,lon',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num?)?.toDouble();
          final lon = (data['lon'] as num?)?.toDouble();
          final rawCity = (data['city'] as String?) ?? '';
          final rawCountry = (data['country'] as String?) ?? '';
          if (lat != null && lon != null) {
            final names = await _reverseGeocode(lat, lon);
            await _applyAndSaveLocation(
              lat: lat,
              lng: lon,
              cityAr: names.$1.isNotEmpty ? names.$1 : rawCity,
              cityEn: names.$2.isNotEmpty ? names.$2 : rawCity,
              provinceAr: names.$3,
              provinceEn: names.$4,
              countryAr: names.$5.isNotEmpty ? names.$5 : rawCountry,
              countryEn: names.$6.isNotEmpty ? names.$6 : rawCountry,
            );
            return true;
          }
        }
      }
    } catch (_) {}

    // Provider 2: BigDataCloud native client IP geolocation (returns Arabic & English directly)
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=ar',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          final cityAr = (data['city'] as String?)?.isNotEmpty == true
              ? data['city'] as String
              : ((data['locality'] as String?)?.isNotEmpty == true
                    ? data['locality'] as String
                    : ((data['principalSubdivision'] as String?) ?? ''));
          final countryAr = (data['countryName'] as String?) ?? '';

          // Fetch English counterpart
          String cityEn = cityAr;
          String countryEn = countryAr;
          try {
            final resEn = await http
                .get(
                  Uri.parse(
                    'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
                  ),
                  headers: const {'Accept': 'application/json'},
                )
                .timeout(const Duration(seconds: 4));
            if (resEn.statusCode == 200) {
              final dataEn = jsonDecode(resEn.body) as Map<String, dynamic>;
              cityEn = (dataEn['city'] as String?)?.isNotEmpty == true
                  ? dataEn['city'] as String
                  : ((dataEn['locality'] as String?)?.isNotEmpty == true
                        ? dataEn['locality'] as String
                        : ((dataEn['principalSubdivision'] as String?) ??
                              cityAr));
              countryEn = (dataEn['countryName'] as String?) ?? countryAr;
            }
          } catch (_) {}

          await _applyAndSaveLocation(
            lat: lat,
            lng: lon,
            cityAr: cityAr.isNotEmpty ? cityAr : _city,
            cityEn: cityEn.isNotEmpty ? cityEn : _cityEn,
            countryAr: countryAr.isNotEmpty ? countryAr : _country,
            countryEn: countryEn.isNotEmpty ? countryEn : _countryEn,
          );
          return true;
        }
      }
    } catch (_) {}

    // Provider 2: ipwho.is — fast HTTPS
    try {
      final res = await http
          .get(
            Uri.parse('https://ipwho.is/'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lon = (data['longitude'] as num?)?.toDouble();
          final rawCity = (data['city'] as String?) ?? '';
          final rawCountry = (data['country'] as String?) ?? '';
          if (lat != null && lon != null) {
            final names = await _reverseGeocode(lat, lon);
            await _applyAndSaveLocation(
              lat: lat,
              lng: lon,
              cityAr: names.$1.isNotEmpty ? names.$1 : rawCity,
              cityEn: names.$2.isNotEmpty ? names.$2 : rawCity,
              provinceAr: names.$3,
              provinceEn: names.$4,
              countryAr: names.$5.isNotEmpty ? names.$5 : rawCountry,
              countryEn: names.$6.isNotEmpty ? names.$6 : rawCountry,
            );
            return true;
          }
        }
      }
    } catch (_) {}

    // Provider 3: freeipapi.com (SSL, reliable)
    try {
      final res = await http
          .get(
            Uri.parse('https://freeipapi.com/api/json'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        final rawCity = (data['cityName'] as String?) ?? '';
        final rawCountry = (data['countryName'] as String?) ?? '';
        if (lat != null && lon != null) {
          final names = await _reverseGeocode(lat, lon);
          await _applyAndSaveLocation(
            lat: lat,
            lng: lon,
            cityAr: names.$1.isNotEmpty ? names.$1 : rawCity,
            cityEn: names.$2.isNotEmpty ? names.$2 : rawCity,
            provinceAr: names.$3,
            provinceEn: names.$4,
            countryAr: names.$5.isNotEmpty ? names.$5 : rawCountry,
            countryEn: names.$6.isNotEmpty ? names.$6 : rawCountry,
          );
          return true;
        }
      }
    } catch (_) {}

    // Provider 4: ipapi.co
    try {
      final res = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: const {
              'User-Agent': 'adhkar/1.0 (adhkar.app@example.com)',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        final rawCity = (data['city'] as String?) ?? '';
        final rawCountry = (data['country_name'] as String?) ?? '';
        if (lat != null && lon != null) {
          final names = await _reverseGeocode(lat, lon);
          await _applyAndSaveLocation(
            lat: lat,
            lng: lon,
            cityAr: names.$1.isNotEmpty ? names.$1 : rawCity,
            cityEn: names.$2.isNotEmpty ? names.$2 : rawCity,
            provinceAr: names.$3,
            provinceEn: names.$4,
            countryAr: names.$5.isNotEmpty ? names.$5 : rawCountry,
            countryEn: names.$6.isNotEmpty ? names.$6 : rawCountry,
          );
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  Future<void> _applyAndSaveLocation({
    required double lat,
    required double lng,
    String? cityAr,
    String? cityEn,
    String? provinceAr,
    String? provinceEn,
    String? countryAr,
    String? countryEn,
    bool resolveCity = false,
  }) async {
    String resolvedCityAr = cityAr ?? _city;
    String resolvedCityEn = cityEn ?? _cityEn;
    String resolvedProvinceAr = provinceAr ?? _province;
    String resolvedProvinceEn = provinceEn ?? _provinceEn;
    String resolvedCountryAr = countryAr ?? _country;
    String resolvedCountryEn = countryEn ?? _countryEn;

    if (resolveCity) {
      final names = await _reverseGeocode(lat, lng);
      resolvedCityAr = names.$1;
      resolvedCityEn = names.$2;
      resolvedProvinceAr = names.$3;
      resolvedProvinceEn = names.$4;
      resolvedCountryAr = names.$5;
      resolvedCountryEn = names.$6;
      _resolvedCountryCode = names.$7;
    }

    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
      _city = resolvedCityAr;
      _cityEn = resolvedCityEn;
      _province = resolvedProvinceAr;
      _provinceEn = resolvedProvinceEn;
      _country = resolvedCountryAr;
      _countryEn = resolvedCountryEn;
      _locateFailed = false;
    });

    // نكتب عبر AppState (مو storage مباشرة) عشان كل الشاشات التانية — الرئيسية
    // والبوصلة وسجل الالتزام — تعرف إن المكان اتغيّر وتحدّث نفسها فورًا.
    _writingLocation = true;
    try {
      final appState = context.read<AppState>();
      await appState.saveLocation(
        lat: lat,
        lng: lng,
        cityAr: resolvedCityAr,
        cityEn: resolvedCityEn,
        provinceAr: resolvedProvinceAr,
        provinceEn: resolvedProvinceEn,
        countryAr: resolvedCountryAr,
        countryEn: resolvedCountryEn,
        countryCode: _resolvedCountryCode,
      );
      // سجّل البصمة اللي طبّقناها عشان الـ sync ما يشفش تغيير برّه.
      _appliedLocationSignature = appState.locationSignature;
    } finally {
      _writingLocation = false;
    }

    // Refresh API prayer times whenever location changes
    _apiTimes = null;
    _fetchApiPrayerTimes();
  }

  Future<(String cityAr, String cityEn, String provinceAr, String provinceEn, String countryAr, String countryEn, String countryCode)>
  _reverseGeocode(double lat, double lng) async {
    // Tier 1: Photon by Komoot (blazing fast, open-source OSM geocoder, no API key, native Arabic)
    try {
      final res = await http
          .get(
            Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lng'),
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'adhkar/1.0 (adhkar.app@example.com)',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];
        if (features.isNotEmpty) {
          final props =
              (features.first['properties'] as Map<String, dynamic>?) ?? {};
          // ⚠️ مهم: متاخدش اسم الشارع (name) — خد المدينة الأول عشان ميحصلش overflow
          final city =
              (props['city'] as String?) ??
              (props['locality'] as String?) ??
              (props['district'] as String?) ??
              '';
          final state = (props['state'] as String?) ?? '';
          final country = (props['country'] as String?) ?? '';

          final cityCandidate = city.isNotEmpty ? city : state;
          if (cityCandidate.isNotEmpty || country.isNotEmpty) {
            return (
              cityCandidate.isNotEmpty ? cityCandidate : _city,
              cityCandidate.isNotEmpty ? cityCandidate : _cityEn,
              state.isNotEmpty ? state : _province,
              state.isNotEmpty ? state : _provinceEn,
              country.isNotEmpty ? country : _country,
              country.isNotEmpty ? country : _countryEn,
              ((props['countrycode'] as String?) ?? '').toString().trim().toUpperCase(),
            );
          }
        }
      }
    } catch (_) {}

    // Tier 2: BigDataCloud Reverse Geocode Client API (client-side, unrestricted, full Arabic & English)
    try {
      final resAr = await http
          .get(
            Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=ar',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (resAr.statusCode == 200) {
        final dataAr = jsonDecode(resAr.body) as Map<String, dynamic>;
        final cityAr = (dataAr['city'] as String?)?.isNotEmpty == true
            ? dataAr['city'] as String
            : ((dataAr['locality'] as String?)?.isNotEmpty == true
                  ? dataAr['locality'] as String
                  : ((dataAr['principalSubdivision'] as String?) ?? ''));
        final provinceAr = (dataAr['principalSubdivision'] as String?) ?? '';
        final countryAr = (dataAr['countryName'] as String?) ?? '';

        String cityEn = cityAr;
        String provinceEn = provinceAr;
        String countryEn = countryAr;

        try {
          final resEn = await http
              .get(
                Uri.parse(
                  'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en',
                ),
                headers: const {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 4));
          if (resEn.statusCode == 200) {
            final dataEn = jsonDecode(resEn.body) as Map<String, dynamic>;
            cityEn = (dataEn['city'] as String?)?.isNotEmpty == true
                ? dataEn['city'] as String
                : ((dataEn['locality'] as String?)?.isNotEmpty == true
                      ? dataEn['locality'] as String
                      : ((dataEn['principalSubdivision'] as String?) ??
                            cityAr));
            provinceEn = (dataEn['principalSubdivision'] as String?) ?? provinceAr;
            countryEn = (dataEn['countryName'] as String?) ?? countryAr;
          }
        } catch (_) {}

        if (cityAr.isNotEmpty || countryAr.isNotEmpty) {
          return (
            cityAr.isNotEmpty ? cityAr : _city,
            cityEn.isNotEmpty ? cityEn : _cityEn,
            provinceAr.isNotEmpty ? provinceAr : _province,
            provinceEn.isNotEmpty ? provinceEn : _provinceEn,
            countryAr.isNotEmpty ? countryAr : _country,
            countryEn.isNotEmpty ? countryEn : _countryEn,
            ((dataAr['countryCode'] as String?) ?? '').toString().trim().toUpperCase(),
          );
        }
      }
    } catch (_) {}

    // Fallback: OpenStreetMap Nominatim
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=ar',
            ),
            headers: const {
              'User-Agent': 'adhkar/1.0 (adhkar.app@example.com)',
              'Accept-Language': 'ar',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final cityAr =
            (addr['city'] ??
                    addr['town'] ??
                    addr['village'] ??
                    addr['municipality'] ??
                    addr['county'] ??
                    addr['state'] ??
                    addr['region'] ??
                    data['name'] ??
                    '')
                as String;
        final countryAr = (addr['country'] ?? '') as String;
        final provinceAr = (addr['state'] ?? '') as String;
        final cc = ((addr['country_code'] as String?) ?? '')
            .toString()
            .trim()
            .toUpperCase();

        String cityEn = cityAr;
        String provinceEn = provinceAr;
        String countryEn = countryAr;
        try {
          final resEn = await http
              .get(
                Uri.parse(
                  'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=en',
                ),
                headers: const {
                  'User-Agent': 'adhkar/1.0 (adhkar.app@example.com)',
                  'Accept-Language': 'en',
                },
              )
              .timeout(const Duration(seconds: 5));

          if (resEn.statusCode == 200) {
            final dataEn = jsonDecode(resEn.body);
            final addrEn = dataEn['address'] as Map<String, dynamic>? ?? {};
            cityEn =
                (addrEn['city'] ??
                        addrEn['town'] ??
                        addrEn['village'] ??
                        addrEn['municipality'] ??
                        addrEn['county'] ??
                        addrEn['state'] ??
                        addrEn['region'] ??
                        dataEn['name'] ??
                        cityAr)
                    as String;
            provinceEn = (addrEn['state'] ?? provinceAr) as String;
            countryEn = (addrEn['country'] ?? countryAr) as String;
          }
        } catch (_) {}

        return (
          cityAr.isNotEmpty ? cityAr : _city,
          cityEn.isNotEmpty ? cityEn : _cityEn,
          provinceAr.isNotEmpty ? provinceAr : _province,
          provinceEn.isNotEmpty ? provinceEn : _provinceEn,
          countryAr.isNotEmpty ? countryAr : _country,
          countryEn.isNotEmpty ? countryEn : _countryEn,
          cc,
        );
      }
    } catch (_) {}

    return (_city, _cityEn, _province, _provinceEn, _country, _countryEn, '');
  }

  void _showCitySearchSheet(BuildContext context) {
    final isAr = language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _CitySearchModal(
          isArabic: isAr,
          dark: dark,
          currentCityAr: _city,
          currentCityEn: _cityEn,
          currentCountryAr: _country,
          currentCountryEn: _countryEn,
          famousCities: _famousCities,
          onCitySelected: (c) async {
            Navigator.pop(ctx);
            await _applyAndSaveLocation(
              lat: c['lat'] as double,
              lng: c['lng'] as double,
              cityAr: c['ar'] as String,
              cityEn: c['en'] as String,
              countryAr: c['countryAr'] as String?,
              countryEn: c['countryEn'] as String?,
            );
            _toast(
              arabic: 'تم اختيار مدينة ${c['ar']}',
              english: 'Selected ${c['en']}',
            );
          },
          onAutoLocate: () {
            Navigator.pop(ctx);
            _tryAutoLocate(silent: false);
          },
        );
      },
    );
  }

  void _toast({required String arabic, required String english}) {
    if (!mounted) return;
    AppToast.show(context, 
      SnackBar(
        content: Text(
          language == AppLanguage.arabic ? arabic : english,
          style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  AppLanguage get language => context.read<AppState>().language;

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final am = t.hour < 12;
    final lang = context.read<AppState>().language;
    if (lang == AppLanguage.arabic) {
      return '$h:$m ${am ? 'ص' : 'م'}';
    }
    return '$h:$m ${am ? 'AM' : 'PM'}';
  }

  int _detectCalculationMethod(String countryEn, String cityEn) {
    final c = countryEn.toLowerCase();
    final city = cityEn.toLowerCase();

    // ──── Egypt ────
    if (c.contains('egypt') || c.contains('مصر')) return 5; // Egyptian General Authority of Survey

    // ──── Arabian Gulf ────
    if (c.contains('saudi') || c.contains('سعودي') ||
        city.contains('makkah') || city.contains('madina') || city.contains('riyadh')) {
      return 4; // Umm Al-Qura
    }
    if (c.contains('uae') || c.contains('emirates') || c.contains('إمارات') || city.contains('dubai') || city.contains('abu dhabi')) return 16; // Dubai
    if (c.contains('qatar') || c.contains('قطر')) return 10; // Qatar
    if (c.contains('kuwait') || c.contains('كويت')) return 9; // Kuwait
    if (c.contains('bahrain') || c.contains('بحرين')) return 9; // Bahrain (Kuwait method)
    if (c.contains('oman') || c.contains('عُمان') || c.contains('عمان')) return 4; // Umm Al-Qura

    // ──── Levant & Iraq ────
    if (c.contains('jordan') || c.contains('أردن')) return 23; // Jordan
    if (c.contains('syria') || c.contains('سوريا')) return 8; // Damascus
    if (c.contains('lebanon') || c.contains('لبنان')) return 5; // Lebanese (Egyptian method)
    if (c.contains('iraq') || c.contains('عراق')) return 9; // Iraq (Kuwait)

    // ──── North Africa ────
    if (c.contains('libya') || c.contains('ليبيا')) return 5; // Libyan (Egyptian)
    if (c.contains('tunisia') || c.contains('تونس')) return 18; // Tunisia
    if (c.contains('algeria') || c.contains('جزائر') || c.contains('algerie')) return 19; // Algeria
    if (c.contains('morocco') || c.contains('مغرب') || c.contains('maroc')) return 21; // Morocco
    if (c.contains('sudan') || c.contains('سودان')) return 5; // Sudan (Egyptian)

    // ──── East Africa & Horn ────
    if (c.contains('somalia') || c.contains('صومال')) return 1; // Karachi
    if (c.contains('djibouti') || c.contains('جيبوتي')) return 1;
    if (c.contains('eritrea') || c.contains('إريتريا')) return 1;
    if (c.contains('ethiopia') || c.contains('إثيوبيا')) return 1;

    // ──── West Africa ────
    if (c.contains('nigeria') || c.contains('نيجيريا')) return 1; // Karachi
    if (c.contains('senegal') || c.contains('سنغال')) return 1;
    if (c.contains('mali') || c.contains('مالي')) return 1;
    if (c.contains('niger') || c.contains('النيجر')) return 1;
    if (c.contains('chad') || c.contains('تشاد')) return 1;
    if (c.contains('mauritania') || c.contains('موريتانيا')) return 1;

    // ──── East & Central Asia ────
    if (c.contains('iran') || c.contains('إيران') || c.contains('ايران')) return 7; // Institute of Geophysics, Tehran
    if (c.contains('afghanistan') || c.contains('أفغانستان') || c.contains('افغانستان')) return 1; // Karachi
    if (c.contains('pakistan') || c.contains('باكستان')) return 1; // Karachi
    if (c.contains('india') || c.contains('هند')) return 1; // Karachi
    if (c.contains('bangladesh') || c.contains('بنغلاديش')) return 1; // Karachi
    if (c.contains('sri lanka') || c.contains('سريلانكا')) return 1;
    if (c.contains('nepal') || c.contains('نيبال')) return 1;
    if (c.contains('myanmar') || c.contains('ميانمار')) return 1;

    // ──── Southeast Asia ────
    if (c.contains('malaysia') || c.contains('ماليزيا')) return 17; // JAKIM
    if (c.contains('indonesia') || c.contains('إندونيسيا') || c.contains('اندونيسيا')) return 20; // KEMENAG
    if (c.contains('singapore') || c.contains('سنغافورة')) return 11; // Singapore
    if (c.contains('brunei') || c.contains('بروناي')) return 17; // JAKIM
    if (c.contains('philippines') || c.contains('الفلبين')) return 1;

    // ──── Turkey ────
    if (c.contains('turkey') || c.contains('turkiye') || c.contains('تركيا')) return 13; // Diyanet

    // ──── Central Asia (former USSR) ────
    if (c.contains('uzbekistan') || c.contains('أوزبكستان')) return 1;
    if (c.contains('kazakhstan') || c.contains('كازاخستان')) return 1;
    if (c.contains('turkmenistan') || c.contains('تركمانستان')) return 1;
    if (c.contains('tajikistan') || c.contains('طاجيكستان')) return 1;
    if (c.contains('kyrgyzstan') || c.contains('قيرغيزستان')) return 1;
    if (c.contains('azerbaijan') || c.contains('أذربيجان')) return 13; // Diyanet

    // ──── East Asia ────
    if (c.contains('china') || c.contains('الصين')) return 1; // Karachi
    if (c.contains('japan') || c.contains('اليابان')) return 1;
    if (c.contains('south korea') || c.contains('كوريا')) return 1;
    if (c.contains('taiwan') || c.contains('تايوان')) return 1;
    if (c.contains('mongolia') || c.contains('منغوليا')) return 1;

    // ──── Russia & Eastern Europe ────
    if (c.contains('russia') || c.contains('روسيا')) return 14; // Russia
    if (c.contains('ukraine') || c.contains('أوكرانيا') || c.contains('اوكرانيا')) return 14;
    if (c.contains('belarus') || c.contains('بيلاروسيا')) return 14;
    if (c.contains('kazakhstan')) return 1;

    // ──── Western Europe ────
    if (c.contains('france') || c.contains('فرنسا')) return 12; // UOIF
    if (c.contains('germany') || c.contains('ألمانيا') || c.contains('المانيا')) return 3; // MWL
    if (c.contains('united kingdom') || c.contains('uk') || c.contains('britain')) return 3; // MWL
    if (c.contains('netherlands') || c.contains('هولندا')) return 3;
    if (c.contains('belgium') || c.contains('بلجيكا')) return 3;
    if (c.contains('spain') || c.contains('إسبانيا') || c.contains('اسبانيا')) return 3;
    if (c.contains('italy') || c.contains('إيطاليا') || c.contains('ايطاليا')) return 3;
    if (c.contains('portugal') || c.contains('برتغال')) return 3;
    if (c.contains('austria') || c.contains('النمسا')) return 3;
    if (c.contains('switzerland') || c.contains('سويسرا')) return 3;
    if (c.contains('sweden') || c.contains('السويد')) return 3;
    if (c.contains('norway') || c.contains('النرويج')) return 3;
    if (c.contains('denmark') || c.contains('الدنمارك')) return 3;
    if (c.contains('finland') || c.contains('فنلندا')) return 3;
    if (c.contains('ireland') || c.contains('أيرلندا')) return 3;
    if (c.contains('poland') || c.contains('بولندا')) return 3;
    if (c.contains('czech') || c.contains('التشيك')) return 3;
    if (c.contains('hungary') || c.contains('المجر')) return 3;
    if (c.contains('romania') || c.contains('رومانيا')) return 3;
    if (c.contains('greece') || c.contains('اليونان')) return 3;

    // ──── Americas ────
    if (c.contains('united states') || c.contains('usa') || c.contains('america') || c.contains('الولايات المتحدة')) return 2; // ISNA
    if (c.contains('canada') || c.contains('كندا')) return 2; // ISNA
    if (c.contains('mexico') || c.contains('المكسيك')) return 2; // ISNA
    if (c.contains('brazil') || c.contains('البرازيل')) return 2;
    if (c.contains('argentina') || c.contains('الأرجنتين')) return 2;
    if (c.contains('colombia') || c.contains('كولومبيا')) return 2;

    // ──── Oceania ────
    if (c.contains('australia') || c.contains('أستراليا') || c.contains('استراليا')) return 2; // ISNA
    if (c.contains('new zealand') || c.contains('نيوزيلندا')) return 2;

    // ──── Sub-Saharan Africa ────
    if (c.contains('south africa') || c.contains('جنوب أفريقيا')) return 2; // ISNA
    if (c.contains('kenya') || c.contains('كينيا')) return 1;
    if (c.contains('uganda') || c.contains('أوغندا')) return 1;
    if (c.contains('tanzania') || c.contains('تنزانيا')) return 1;

    // ──── Israel/Palestine ────
    if (c.contains('israel') || c.contains('فلسطين') || c.contains('israel/palestine')) return 5; // Palestinian (Egyptian)

    // ──── Default: Muslim World League (MWL) ────
    return 3;
  }

  /// جلب مواقيت الصلاة من Aladhan API (‏api.aladhan.com) عبر [AladhanService]
  /// — طريقة الحساب تلقائية حسب الدولة، والتوقيت مربوط بمنطقة المدينة نفسها
  /// (meta.timezone) لتصح المواقيت في كل أنحاء العالم، مع كاش أوفلاين و
  /// احتياطي محلي عند تعذّر الشبكة.
  Future<void> _fetchApiPrayerTimes() async {
    if (_loadingApiTimes) return;
    setState(() => _loadingApiTimes = true);
    try {
      final timesMap = await AladhanService.instance.timingsFor(
        date: DateTime.now(),
        lat: _lat,
        lng: _lng,
        countryEn: _countryEn,
        cityEn: _cityEn,
        method: _detectCalculationMethod(_countryEn, _cityEn),
      );

      if (timesMap != null && mounted) {
        setState(() {
          _apiTimes = timesMap;
          _loadingApiTimes = false;
        });

        // Schedule system notifications on Android / iOS
        final isAr = context.read<AppState>().language == AppLanguage.arabic;
        PrayerAlertService.instance.schedulePrayerNotifications(
          prayerTimes: timesMap,
          isArabic: isAr,
          lat: _lat,
          lng: _lng,
        );
        return;
      }
      // Fallback: API failed — schedule using local calculator so alerts still fire
      if (mounted) setState(() => _loadingApiTimes = false);
      await _scheduleLocalFallback();
    } catch (_) {
      if (mounted) setState(() => _loadingApiTimes = false);
      await _scheduleLocalFallback();
    }
  }

  Future<void> _scheduleLocalFallback() async {
    try {
      if (!mounted) return;
      final today = DateTime.now();
      final local = PrayerCalculator.calculate(date: today, lat: _lat, lng: _lng);
      final timesMap = {
        'fajr': local.fajr,
        'sunrise': local.sunrise,
        'dhuhr': local.dhuhr,
        'asr': local.asr,
        'maghrib': local.maghrib,
        'isha': local.isha,
      };
      final isAr = context.read<AppState>().language == AppLanguage.arabic;
      await PrayerAlertService.instance.schedulePrayerNotifications(
        prayerTimes: timesMap,
        isArabic: isAr,
        lat: _lat,
        lng: _lng,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();

    // Use Aladhan API times if available, otherwise fall back to local calculator
    final localTimes = PrayerCalculator.calculate(
      date: today,
      lat: _lat,
      lng: _lng,
    );
    final fajr = _apiTimes?['fajr'] ?? localTimes.fajr;
    final sunrise = _apiTimes?['sunrise'] ?? localTimes.sunrise;
    final dhuhr = _apiTimes?['dhuhr'] ?? localTimes.dhuhr;
    final asr = _apiTimes?['asr'] ?? localTimes.asr;
    final maghrib = _apiTimes?['maghrib'] ?? localTimes.maghrib;
    final isha = _apiTimes?['isha'] ?? localTimes.isha;

    final entries = [
      ('الفجر', 'Fajr', Icons.nights_stay_rounded, fajr),
      ('الشروق', 'Sunrise', Icons.wb_sunny_outlined, sunrise),
      ('الظهر', 'Dhuhr', Icons.light_mode_rounded, dhuhr),
      ('العصر', 'Asr', Icons.wb_twilight_rounded, asr),
      ('المغرب', 'Maghrib', Icons.bedtime_rounded, maghrib),
      ('العشاء', 'Isha', Icons.dark_mode_rounded, isha),
    ];
    // highlight next prayer
    final now = DateTime.now();
    DateTime? nextTime;
    for (final e in entries) {
      if (e.$4.isAfter(now)) {
        nextTime = e.$4;
        break;
      }
    }
    nextTime ??= entries.first.$4.add(const Duration(days: 1));

    final displayCity = lang == AppLanguage.arabic ? _city : _cityEn;
    final displayProvince = lang == AppLanguage.arabic ? _province : _provinceEn;
    final displayCountry = lang == AppLanguage.arabic ? _country : _countryEn;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppBar(
              title: Text(AppStrings.t(lang, 'prayer_times')),
              centerTitle: true,
              actions: [
                // Auto Locate Button
                IconButton(
                  tooltip: AppStrings.t(lang, 'auto_location'),
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  onPressed: _locating
                      ? null
                      : () => _tryAutoLocate(silent: false),
                ),
                // Prayer Alerts Settings Control Button
                IconButton(
                  tooltip: lang == AppLanguage.arabic
                      ? 'إعدادات تنبيهات الأذان والصلوات'
                      : 'Prayer Alerts & Adhan Settings',
                  icon: const Icon(Icons.notifications_active_rounded),
                  onPressed: () => _showPrayerNotificationSettings(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                // Current time & City Card (Interactive: tap to change city)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showCitySearchSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (dark ? DhikrColors.sage : DhikrColors.forest)
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          _LiveClockWidget(
                            isArabic: lang == AppLanguage.arabic,
                            dark: dark,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                  ),
                                  child: Text(
                                    locationLabel(
                                      city: displayCity,
                                      province: displayProvince,
                                      country: displayCountry,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: dark
                                          ? DhikrColors.darkText
                                          : DhikrColors.charcoal,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 22,
                                color: dark
                                    ? DhikrColors.darkMuted
                                    : DhikrColors.charcoalSoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.t(lang, 'prayer_gps_hint'),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark
                                  ? DhikrColors.darkMuted
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Active Adhan Alert Banner (when Adhan sounds at prayer time or is previewed)
                if (_isPlayingAdhan) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xFF1E3A2F), const Color(0xFF142620)]
                            : [
                                const Color(0xFFE8F5E9),
                                const Color(0xFFC8E6C9),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (dark ? DhikrColors.sage : DhikrColors.forest)
                              .withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: dark ? DhikrColors.sage : DhikrColors.forest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activePrayerNameAr != null
                                    ? (lang == AppLanguage.arabic
                                          ? 'حان الآن موعد $_activePrayerNameAr 🕌'
                                          : 'Time for $_activePrayerNameEn 🕌')
                                    : (lang == AppLanguage.arabic
                                          ? 'الأذان يعمل الآن 🕌'
                                          : 'Adhan is playing 🕌'),
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: dark
                                      ? Colors.white
                                      : DhikrColors.forest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang == AppLanguage.arabic
                                    ? _adhanOptions[_selectedAdhanIndex]['nameAr']!
                                    : _adhanOptions[_selectedAdhanIndex]['nameEn']!,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11.5,
                                  color: dark
                                      ? DhikrColors.darkMuted
                                      : DhikrColors.charcoalSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _stopAdhan,
                          icon: const Icon(Icons.stop_rounded, size: 18),
                          label: Text(
                            lang == AppLanguage.arabic
                                ? 'إيقاف الأذان'
                                : 'Stop',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Daily Streak & 5 Prayer Checklist Tasks (DGA Minimalist Style)
                _buildPrayerTasksCard(context, lang, dark),
                const SizedBox(height: 14),

                if (_locateFailed) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE53935).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          size: 16,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang == AppLanguage.arabic
                                ? 'تعذر تحديد الموقع — فعل GPS أو اختر مدينتك'
                                : 'Could not detect location — enable GPS or select city',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showCitySearchSheet(context),
                          child: Text(
                            AppStrings.t(lang, 'select_city'),
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...entries.map((e) {
                  final isNext = e.$4 == nextTime;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isNext
                          ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                .withValues(alpha: 0.12)
                          : (dark ? DhikrColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNext
                            ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                  .withValues(alpha: 0.35)
                            : (dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : DhikrColors.charcoal.withValues(
                                      alpha: 0.06,
                                    )),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isNext
                                ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                : (dark ? DhikrColors.sage : DhikrColors.forest)
                                      .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            e.$3,
                            size: 20,
                            color: isNext
                                ? Colors.white
                                : (dark
                                      ? DhikrColors.sage
                                      : DhikrColors.forest),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lang == AppLanguage.arabic ? e.$1 : e.$2,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: dark
                                  ? DhikrColors.darkText
                                  : DhikrColors.charcoal,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(e.$4),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isNext
                                ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                : (dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal),
                          ),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? DhikrColors.sage
                                  : DhikrColors.forest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppStrings.t(lang, 'next'),
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPrayerNotificationSettings(BuildContext context) async {
    final lang = context.read<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final currentPrefs = await PrayerAlertService.instance
        .getAlertPreferences();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool enabled = currentPrefs['enabled'] as bool? ?? true;
        bool fajr = currentPrefs['fajr'] as bool? ?? true;
        bool dhuhr = currentPrefs['dhuhr'] as bool? ?? true;
        bool asr = currentPrefs['asr'] as bool? ?? true;
        bool maghrib = currentPrefs['maghrib'] as bool? ?? true;
        bool isha = currentPrefs['isha'] as bool? ?? true;
        bool vibration = currentPrefs['vibration'] as bool? ?? true;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (dark ? DhikrColors.sage : DhikrColors.forest)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: dark
                                  ? DhikrColors.sage
                                  : DhikrColors.forest,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? 'إعدادات تنبيهات الأذان'
                                      : 'Prayer Alerts & Adhan',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: dark
                                        ? DhikrColors.darkText
                                        : DhikrColors.charcoal,
                                  ),
                                ),
                                Text(
                                  isAr
                                      ? 'تحكم في تنبيهات كل صلاة ونوع الصوت'
                                      : 'Configure alerts per prayer & sound',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 12,
                                    color: dark
                                        ? DhikrColors.darkMuted
                                        : DhikrColors.charcoalSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isAr
                              ? 'تفعيل تنبيهات الصلاة'
                              : 'Enable Prayer Alerts',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: dark
                                ? DhikrColors.darkText
                                : DhikrColors.charcoal,
                          ),
                        ),
                        subtitle: Text(
                          isAr
                              ? 'إشعار فوري عند دخول وقت الصلاة'
                              : 'Instant notification when prayer time arrives',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                        ),
                        value: enabled,
                        activeThumbColor: dark
                            ? DhikrColors.sage
                            : DhikrColors.forest,
                        onChanged: (val) {
                          setSheetState(() => enabled = val);
                        },
                      ),
                      const Divider(height: 24),
                      Opacity(
                        opacity: enabled ? 1.0 : 0.45,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'الصلوات المفعلة' : 'Active Prayers',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPrayerToggleTile(
                              title: isAr ? 'صلاة الفجر' : 'Fajr Prayer',
                              icon: Icons.nights_stay_rounded,
                              value: fajr,
                              dark: dark,
                              enabled: enabled,
                              onChanged: (v) => setSheetState(() => fajr = v),
                            ),
                            _buildPrayerToggleTile(
                              title: isAr ? 'صلاة الظهر' : 'Dhuhr Prayer',
                              icon: Icons.light_mode_rounded,
                              value: dhuhr,
                              dark: dark,
                              enabled: enabled,
                              onChanged: (v) => setSheetState(() => dhuhr = v),
                            ),
                            _buildPrayerToggleTile(
                              title: isAr ? 'صلاة العصر' : 'Asr Prayer',
                              icon: Icons.wb_twilight_rounded,
                              value: asr,
                              dark: dark,
                              enabled: enabled,
                              onChanged: (v) => setSheetState(() => asr = v),
                            ),
                            _buildPrayerToggleTile(
                              title: isAr ? 'صلاة المغرب' : 'Maghrib Prayer',
                              icon: Icons.bedtime_rounded,
                              value: maghrib,
                              dark: dark,
                              enabled: enabled,
                              onChanged: (v) =>
                                  setSheetState(() => maghrib = v),
                            ),
                            _buildPrayerToggleTile(
                              title: isAr ? 'صلاة العشاء' : 'Isha Prayer',
                              icon: Icons.dark_mode_rounded,
                              value: isha,
                              dark: dark,
                              enabled: enabled,
                              onChanged: (v) => setSheetState(() => isha = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: enabled ? 1.0 : 0.45,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                (dark ? DhikrColors.sage : DhikrColors.forest)
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'اهتزاز الجهاز' : 'Device Vibration',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'اهتزاز الجهاز عند وصول تنبيه الأذان'
                                    : 'Vibrate device when Adhan alert arrives',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  color: dark
                                      ? DhikrColors.darkMuted
                                      : DhikrColors.charcoalSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  isAr ? 'تفعيل الاهتزاز' : 'Enable Vibration',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: dark
                                        ? DhikrColors.darkText
                                        : DhikrColors.charcoal,
                                  ),
                                ),
                                value: vibration,
                                activeThumbColor: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                                onChanged: enabled
                                    ? (val) =>
                                        setSheetState(() => vibration = val)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: dark
                              ? DhikrColors.sage
                              : DhikrColors.forest,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          isAr
                              ? 'حفظ وتحديث التنبيهات'
                              : 'Save & Update Alerts',
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final today = DateTime.now();
                          final localTimes = PrayerCalculator.calculate(
                            date: today,
                            lat: _lat,
                            lng: _lng,
                          );
                          final timesMap =
                              _apiTimes ??
                              {
                                'fajr': localTimes.fajr,
                                'sunrise': localTimes.sunrise,
                                'dhuhr': localTimes.dhuhr,
                                'asr': localTimes.asr,
                                'maghrib': localTimes.maghrib,
                                'isha': localTimes.isha,
                              };

                          await PrayerAlertService.instance
                              .saveAlertPreferences(
                                enabled: enabled,
                                fajr: fajr,
                                dhuhr: dhuhr,
                                asr: asr,
                                maghrib: maghrib,
                                isha: isha,
                                vibration: vibration,
                                prayerTimes: timesMap,
                                isArabic: isAr,
                              );

                          if (context.mounted) {
                            AppToast.show(context, 
                              SnackBar(
                                content: Text(
                                  isAr
                                      ? 'تم حفظ إعدادات مواقيت الصلاة وجدولة التنبيهات بنجاح ✓'
                                      : 'Prayer notification settings updated ✓',
                                  style: const TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                  ),
                                ),
                                backgroundColor: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrayerToggleTile({
    required String title,
    required IconData icon,
    required bool value,
    required bool dark,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: dark ? DhikrColors.sage : DhikrColors.forest,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTasksCard(
    BuildContext context,
    AppLanguage language,
    bool dark,
  ) {
    final appState = context.watch<AppState>();
    final streak = appState.streakCount;
    final isAr = language == AppLanguage.arabic;
    final completedCount = appState.completedPrayerTasksCount;

    const prayers = [
      ('fajr', 'الفجر', 'Fajr', LucideIcons.sunrise),
      ('dhuhr', 'الظهر', 'Dhuhr', LucideIcons.sun),
      ('asr', 'العصر', 'Asr', LucideIcons.sunMedium),
      ('maghrib', 'المغرب', 'Maghrib', LucideIcons.sunset),
      ('isha', 'العشاء', 'Isha', LucideIcons.moon),
    ];

    final primaryAccent = dark ? DhikrColors.sage : DhikrColors.forest;
    const goldAccent = Color(0xFFD97706);
    final isAllCompleted = completedCount == 5;

    return Container(
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.08),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: DGA Streak badge + Prayer progress fraction
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: goldAccent.withValues(alpha: dark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: goldAccent.withValues(alpha: dark ? 0.35 : 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.flame, size: 15, color: goldAccent),
                    const SizedBox(width: 5),
                    Text(
                      isAr
                          ? '$streak ${streak == 1 ? "يوم التزام" : "أيام التزام"}'
                          : '$streak Day${streak > 1 ? "s" : ""} Streak',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAllCompleted
                      ? primaryAccent.withValues(alpha: dark ? 0.25 : 0.12)
                      : (dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1F5F2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAllCompleted
                      ? (isAr
                            ? 'أتممت صلوات اليوم كلها ✓'
                            : 'All 5 prayers completed ✓')
                      : (isAr
                            ? '${_toArabicNum(completedCount)} من ٥ صلوات'
                            : '$completedCount / 5 prayers'),
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: isAllCompleted
                        ? primaryAccent
                        : (dark
                              ? DhikrColors.darkMuted
                              : DhikrColors.charcoalSoft),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isAr
                      ? 'اضغط على الصلاة لتسجيل إقامتها'
                      : 'Tap a prayer to mark as performed',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color:
                        dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 5 Prayers Checklist
          Row(
            children: prayers.map((p) {
              final isDone = appState.isPrayerTaskCompleted(p.$1);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    appState.togglePrayerTask(p.$1);
                    HomeWidgetService.instance.syncTracker();
                  },
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDone
                              ? primaryAccent
                              : (dark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF8FAF9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDone
                                ? primaryAccent
                                : (dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : DhikrColors.charcoal.withValues(
                                          alpha: 0.08,
                                        )),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone ? LucideIcons.check : p.$4,
                              size: 16,
                              color: isDone
                                  ? Colors.white
                                  : (dark
                                        ? DhikrColors.darkMuted
                                        : DhikrColors.charcoalSoft),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? p.$2 : p.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: isDone
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 11,
                                color: isDone
                                    ? Colors.white
                                    : (dark
                                          ? DhikrColors.darkMuted
                                          : DhikrColors.charcoalSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Radio صغير 10px في الزاوية العليا
                      PositionedDirectional(
                        top: 6,
                        start: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? Colors.white : Colors.transparent,
                            border: Border.all(
                              color: isDone
                                  ? Colors.white
                                  : (dark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : DhikrColors.charcoal
                                            .withValues(alpha: 0.25)),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Nawafil Tracker Shortcut Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                NawafilTrackerSheet.show(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 16,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? 'متابعة صلوات النوافل والسنن' : 'Nawafil & Sunnah Tracker',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                            ),
                          ),
                          Text(
                            isAr
                                ? 'سُنن الفجر، الضحى، الرواتب، وقيام الليل والوتر'
                                : 'Duha, Rawatib & Qiyam Witr Tracker',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic City Search Modal:
/// Allows searching any city worldwide via Open-Meteo Geocoding API + Instant famous cities
class _CitySearchModal extends StatefulWidget {
  const _CitySearchModal({
    required this.isArabic,
    required this.dark,
    required this.currentCityAr,
    required this.currentCityEn,
    required this.currentCountryAr,
    required this.currentCountryEn,
    required this.famousCities,
    required this.onCitySelected,
    required this.onAutoLocate,
  });

  final bool isArabic;
  final bool dark;
  final String currentCityAr;
  final String currentCityEn;
  final String currentCountryAr;
  final String currentCountryEn;
  final List<Map<String, dynamic>> famousCities;
  final ValueChanged<Map<String, dynamic>> onCitySelected;
  final VoidCallback onAutoLocate;

  @override
  State<_CitySearchModal> createState() => _CitySearchModalState();
}

class _CitySearchModalState extends State<_CitySearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  /// Famous cities reordered so the user's own country governorates appear first.
  List<Map<String, dynamic>> get _famousCitiesInCountryFirst {
    final myCountry = widget.isArabic
        ? widget.currentCountryAr
        : widget.currentCountryEn;
    final same = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    for (final c in widget.famousCities) {
      final cc = widget.isArabic ? c['countryAr'] : c['countryEn'];
      if (myCountry.isNotEmpty && cc == myCountry) {
        same.add(c);
      } else {
        rest.add(c);
      }
    }
    return [...same, ...rest];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(q.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);

    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=${widget.isArabic ? "ar" : "en"}&format=json',
      );
      final res = await http
          .get(url, headers: const {'User-Agent': 'adhkar/1.0'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['results'] as List<dynamic>?) ?? [];
        final results = list.map((item) {
          final name = (item['name'] as String?) ?? '';
          final country = (item['country'] as String?) ?? '';
          final lat = (item['latitude'] as num).toDouble();
          final lng = (item['longitude'] as num).toDouble();
          return {
            'ar': name,
            'en': name,
            'countryAr': country,
            'countryEn': country,
            'lat': lat,
            'lng': lng,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
            _searching = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final isAr = widget.isArabic;
    final lang = isAr ? AppLanguage.arabic : AppLanguage.english;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header Row
            Row(
              children: [
                Text(
                  AppStrings.t(lang, 'select_city'),
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const Spacer(),
                // Auto Detect GPS/IP Button
                TextButton.icon(
                  onPressed: widget.onAutoLocate,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    AppStrings.t(lang, 'auto_location'),
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: dark
                        ? DhikrColors.sage
                        : DhikrColors.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search Input
            TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 15,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.t(lang, 'search_city'),
                hintStyle: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 14,
                  color: dark
                      ? DhikrColors.darkMuted
                      : DhikrColors.charcoalSoft,
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : DhikrColors.cream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_searching)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            const SizedBox(height: 8),

            // Content: Search Results or Famous Cities
            Expanded(
              child: _searchCtrl.text.trim().isNotEmpty
                  ? (_searchResults.isEmpty && !_searching
                        ? Center(
                            child: Text(
                              AppStrings.t(lang, 'no_cities_found'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                color: dark
                                    ? DhikrColors.darkMuted
                                    : DhikrColors.charcoalSoft,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = _searchResults[i];
                              final name = isAr ? item['ar'] : item['en'];
                              final country = isAr
                                  ? item['countryAr']
                                  : item['countryEn'];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        (dark
                                                ? DhikrColors.sage
                                                : DhikrColors.forest)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_city_rounded,
                                    size: 18,
                                    color: dark
                                        ? DhikrColors.sage
                                        : DhikrColors.forest,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: dark
                                        ? DhikrColors.darkText
                                        : DhikrColors.charcoal,
                                  ),
                                ),
                                subtitle: country != null && country.isNotEmpty
                                    ? Text(
                                        country,
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 12,
                                          color: dark
                                              ? DhikrColors.darkMuted
                                              : DhikrColors.charcoalSoft,
                                        ),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                ),
                                onTap: () => widget.onCitySelected(item),
                              );
                            },
                          ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(lang, 'popular_cities'),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _famousCitiesInCountryFirst.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = _famousCitiesInCountryFirst[i];
                              final name = isAr ? item['ar'] : item['en'];
                              final country = isAr
                                  ? item['countryAr']
                                  : item['countryEn'];
                              final isCurrent =
                                  item['ar'] == widget.currentCityAr ||
                                  item['en'] == widget.currentCityEn;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? (dark
                                              ? DhikrColors.sage
                                              : DhikrColors.forest)
                                        : (dark
                                                  ? DhikrColors.sage
                                                  : DhikrColors.forest)
                                              .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 18,
                                    color: isCurrent
                                        ? Colors.white
                                        : (dark
                                              ? DhikrColors.sage
                                              : DhikrColors.forest),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 15,
                                    color: isCurrent
                                        ? (dark
                                              ? DhikrColors.sage
                                              : DhikrColors.forest)
                                        : (dark
                                              ? DhikrColors.darkText
                                              : DhikrColors.charcoal),
                                  ),
                                ),
                                subtitle: Text(
                                  country,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 12,
                                    color: dark
                                        ? DhikrColors.darkMuted
                                        : DhikrColors.charcoalSoft,
                                  ),
                                ),
                                trailing: isCurrent
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: dark
                                            ? DhikrColors.sage
                                            : DhikrColors.forest,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                      ),
                                onTap: () => widget.onCitySelected(item),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stable, isolated live digital clock widget that updates only itself without rebuilding the entire screen,
/// featuring fixed sizing, FittedBox, and tabular figures to completely eliminate horizontal frame jittering.
class _LiveClockWidget extends StatefulWidget {
  const _LiveClockWidget({required this.isArabic, required this.dark});
  final bool isArabic;
  final bool dark;

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  late DateTime _now;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final ampm = _now.hour < 12
        ? (widget.isArabic ? 'ص' : 'AM')
        : (widget.isArabic ? 'م' : 'PM');
    final timeStr = '$h:$m:$s $ampm';

    return SizedBox(
      height: 46,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            timeStr,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: widget.dark
                  ? DhikrColors.darkText
                  : DhikrColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}
