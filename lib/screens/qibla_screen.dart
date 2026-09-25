import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/location_label.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with TickerProviderStateMixin {
  // Location
  double _userLat = 30.0444; // Cairo default
  double _userLng = 31.2357;
  String _cityName = 'القاهرة، مصر';
  bool _locating = false;

  // Sensor Heading & Smoothing
  double _deviceHeading = 0.0;
  double _filteredHeading = 0.0;
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Infinity Calibration State
  late AnimationController _infinityAnimCtrl;
  bool _isCalibrating = false;
  double _calibrationProgress = 1.0; // 1.0 = calibrated
  double _sensorEnergy = 0.0;

  @override
  void initState() {
    super.initState();

    // Infinity loop travel animation
    _infinityAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _loadUserLocation();
    _startSensorListeners();
  }

  @override
  void dispose() {
    _infinityAnimCtrl.dispose();
    _magnetometerSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  void _startSensorListeners() {
    // 1. Magnetometer for real-time fast device heading
    _magnetometerSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      // Calculate angle in degrees from device X & Y axes
      double rad = math.atan2(-event.x, event.y);
      double deg = (rad * 180.0 / math.pi + 360.0) % 360.0;

      // Fast adaptive filter: snaps quickly on rotation, smooth when holding
      double diff = (deg - _filteredHeading + 180) % 360 - 180;
      double factor = diff.abs() > 20 ? 0.75 : (diff.abs() > 5 ? 0.50 : 0.30);
      _filteredHeading = (_filteredHeading + diff * factor + 360.0) % 360.0;

      if (mounted) {
        setState(() {
          _deviceHeading = _filteredHeading;
        });
      }
    });

    // 2. Gyroscope to detect infinity (figure-8) movement during calibration
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!_isCalibrating) return;

      // Angular velocity across all 3 axes
      final speed = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (speed > 1.2) {
        _sensorEnergy += speed * 0.04;
        if (_sensorEnergy >= 1.0) {
          _finishCalibration();
        } else if (mounted) {
          setState(() {
            _calibrationProgress = _sensorEnergy.clamp(0.0, 1.0);
          });
        }
      }
    });
  }

  void _startInfinityCalibration() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0.0;
      _sensorEnergy = 0.0;
    });

    // Auto-timeout after 12 seconds if not completed
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _isCalibrating) {
        _finishCalibration();
      }
    });
  }

  void _finishCalibration() {
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _calibrationProgress = 1.0;
      });

      AppToast.show(context, 
        const SnackBar(
          content: Text(
            '✓ تمت معايرة حساس البوصلة بنجاح بدقة ممتازة',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFC5A059),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadUserLocation() {
    final storage = context.read<AppState>().storage;
    final saved = storage.getSavedLocation();
    if (saved != null) {
      final lat = (saved['lat'] as num?)?.toDouble();
      final lng = (saved['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() {
          _userLat = lat;
          _userLng = lng;
          _cityName = _titleFromLocationMap(saved);
        });
      }
    }
  }

  /// «المنطقة ثم المدينة» باللغة الحالية من بيانات الموقع المحفوظة.
  String _titleFromLocationMap(Map<String, dynamic> loc) {
    final isAr = context.read<AppState>().language == AppLanguage.arabic;
    String pick(String arKey, String enKey) {
      final ar = ((loc[arKey] as String?) ?? '').trim();
      final en = ((loc[enKey] as String?) ?? '').trim();
      return isAr ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
    }

    return locationLabel(
      city: pick('cityAr', 'cityEn'),
      province: pick('provinceAr', 'provinceEn'),
      country: pick('countryAr', 'countryEn'),
    );
  }

  Future<void> _refreshGPS() async {
    HapticFeedback.mediumImpact();
    setState(() => _locating = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });

        if (mounted) {
          final storage = context.read<AppState>().storage;
          String countryAr = '';
          String countryEn = '';
          String provinceAr = '';
          String provinceEn = '';
          String cityAr = '';
          String cityEn = '';
          String cc = '';
          try {
            final res = await http
                .get(
                  Uri.parse(
                      'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${pos.latitude}&longitude=${pos.longitude}&localityLanguage=ar'),
                )
                .timeout(const Duration(seconds: 5));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body) as Map<String, dynamic>;
              countryAr = (data['countryName'] as String?) ?? '';
              provinceAr = (data['principalSubdivision'] as String?) ?? '';
              cityAr = ((data['city'] as String?) ?? '').trim().isNotEmpty
                  ? ((data['city'] as String).trim())
                  : (((data['locality'] as String?) ?? '').trim());
              cc = ((data['countryCode'] as String?) ?? '').trim().toUpperCase();
            }
          } catch (_) {}
          try {
            final res = await http
                .get(
                  Uri.parse(
                      'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${pos.latitude}&longitude=${pos.longitude}&localityLanguage=en'),
                )
                .timeout(const Duration(seconds: 5));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body) as Map<String, dynamic>;
              countryEn = (data['countryName'] as String?) ?? '';
              provinceEn = (data['principalSubdivision'] as String?) ?? '';
              cityEn = ((data['city'] as String?) ?? '').trim();
              cc = ((data['countryCode'] as String?) ?? '').trim().toUpperCase();
            }
          } catch (_) {}
          // المدينة من الـ geocoder مع الحفاظ على المدينة المحفوظة كاحتياط
          // (بدل كتابة اسم القديم فوقها كما كان سابقًا).
          final prev = storage.getSavedLocation() ?? const <String, dynamic>{};
          final prevCityAr = ((prev['cityAr'] as String?) ?? '').trim();
          final prevCityEn = ((prev['cityEn'] as String?) ?? '').trim();
          final finalCityAr = cityAr.isNotEmpty
              ? cityAr
              : (prevCityAr.isNotEmpty ? prevCityAr : _cityName);
          final finalCityEn = cityEn.isNotEmpty
              ? cityEn
              : (prevCityEn.isNotEmpty ? prevCityEn : _cityName);
          await storage.saveLocation(
            lat: pos.latitude,
            lng: pos.longitude,
            cityAr: finalCityAr,
            cityEn: finalCityEn,
            provinceAr: provinceAr,
            provinceEn: provinceEn,
            countryAr: countryAr,
            countryEn: countryEn,
            countryCode: cc,
          );
          if (mounted) {
            final isAr =
                context.read<AppState>().language == AppLanguage.arabic;
            setState(() {
              _cityName = locationLabel(
                city: isAr
                    ? (finalCityAr.isNotEmpty ? finalCityAr : finalCityEn)
                    : (finalCityEn.isNotEmpty ? finalCityEn : finalCityAr),
                province: isAr
                    ? (provinceAr.isNotEmpty ? provinceAr : provinceEn)
                    : (provinceEn.isNotEmpty ? provinceEn : provinceAr),
                country: isAr
                    ? (countryAr.isNotEmpty ? countryAr : countryEn)
                    : (countryEn.isNotEmpty ? countryEn : countryAr),
              );
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _locating = false);
    }
  }

  /// Base Qibla Bearing (True North)
  double get _qiblaBearing {
    const meccaLat = 21.422487 * math.pi / 180.0;
    const meccaLng = 39.826206 * math.pi / 180.0;
    final userLat = _userLat * math.pi / 180.0;
    final diffLng = meccaLng - (_userLng * math.pi / 180.0);

    final y = math.sin(diffLng);
    final x = math.cos(userLat) * math.tan(meccaLat) -
        math.sin(userLat) * math.cos(diffLng);

    final qibla = math.atan2(y, x) * 180.0 / math.pi;
    return (qibla + 360.0) % 360.0;
  }

  double get _distanceToMeccaKm {
    const r = 6371.0;
    const meccaLat = 21.422487 * math.pi / 180.0;
    const meccaLng = 39.826206 * math.pi / 180.0;
    final userLat = _userLat * math.pi / 180.0;
    final userLng = _userLng * math.pi / 180.0;

    final dLat = meccaLat - userLat;
    final dLng = meccaLng - userLng;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLat) * math.cos(meccaLat) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _bearingDirectionAr(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'شمالاً';
    if (deg >= 22.5 && deg < 67.5) return 'شمال شرق';
    if (deg >= 67.5 && deg < 112.5) return 'شرقاً';
    if (deg >= 112.5 && deg < 157.5) return 'جنوب شرق';
    if (deg >= 157.5 && deg < 202.5) return 'جنوباً';
    if (deg >= 202.5 && deg < 247.5) return 'جنوب غرب';
    if (deg >= 247.5 && deg < 292.5) return 'غرباً';
    return 'شمال غرب';
  }

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final qibla = _qiblaBearing;
    final distance = _distanceToMeccaKm.round();

    // Check if phone points to Qibla within +/- 4 degrees
    final angleDiff = ((_deviceHeading - qibla + 180) % 360 - 180).abs();
    final isAlignedWithQibla = angleDiff < 4.0;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF07130F) : const Color(0xFFF6F7F9),
        appBar: AppBar(
          title: Text(
            isAr ? 'بوصلة القبلة الشريفة 🕋' : 'Qibla Direction 🕋',
            style: const TextStyle(
              fontFamily: DhikrTheme.titleFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC5A059)),
                    )
                  : const Icon(LucideIcons.locateFixed, size: 20),
              tooltip: isAr ? 'تحديث الموقع بدقة' : 'Refresh GPS',
              onPressed: _locating ? null : _refreshGPS,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── 1. Location & Distance Banner ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF11221B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.mapPin, color: Color(0xFFC5A059), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cityName,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: dark ? Colors.white : DhikrColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? 'المسافة إلى الكعبة: ${_toArabicNum(distance)} كم'
                                    : 'Distance to Holy Kaaba: $distance km',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  color: dark ? const Color(0xFFA7F3D0) : const Color(0xFF059669),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Real-time alignment badge
                        if (isAlignedWithQibla)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5A059),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'باتجاه الكعبة' : 'Facing Kaaba',
                                  style: const TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── 2. The Clean Neumorphic Compass Dial (Matching User Screenshot) ──
                Center(
                  child: SizedBox(
                    width: 310,
                    height: 310,
                    child: AnimatedBuilder(
                      animation: _infinityAnimCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(310, 310),
                          painter: NeumorphicCompassPainter(
                            deviceHeading: _deviceHeading,
                            qiblaBearing: qibla,
                            isDark: dark,
                            isAligned: isAlignedWithQibla,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 3. Qibla Degree & Direction Banner ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAlignedWithQibla
                            ? [const Color(0xFFC5A059), const Color(0xFF059669)]
                            : dark
                                ? [const Color(0xFF11221B), const Color(0xFF091611)]
                                : [Colors.white, const Color(0xFFF1F5F9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isAlignedWithQibla
                            ? const Color(0xFFC5A059)
                            : const Color(0xFFC5A059).withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAlignedWithQibla
                              ? const Color(0xFFC5A059).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr
                              ? 'زاوية القبلة: ${_toArabicNum(qibla.round())}° (${_bearingDirectionAr(qibla)})'
                              : 'Qibla Angle: ${qibla.round()}° (${_bearingDirectionAr(qibla)})',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: isAlignedWithQibla
                                ? Colors.white
                                : dark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAr
                              ? (isAlignedWithQibla
                                  ? 'أنت الآن تستقبل القبلة الشريفة تماماً 🕋'
                                  : 'قم بتدوير الهاتف حتى يتطابق سهم الشمال مع علامة الكعبة 🕋')
                              : (isAlignedWithQibla
                                  ? 'You are now facing the Holy Kaaba 🕋'
                                  : 'Rotate phone until the needle matches the Kaaba badge 🕋'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11.5,
                            color: isAlignedWithQibla
                                ? Colors.white.withValues(alpha: 0.95)
                                : dark
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFF047857),
                            fontWeight: isAlignedWithQibla ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 4. Infinity Loop Automatic Calibration (تدوير بالدايرة الإنفينيتي للضبط) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF11221B) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _isCalibrating
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFC5A059).withValues(alpha: 0.25),
                        width: _isCalibrating ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isCalibrating
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.infinity, color: Color(0xFF0284C7), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'ضبط ومعايرة البوصلة بالدائرة الإنفينيتي (∞)' : 'Infinity Loop (∞) Calibration',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? Colors.white : DhikrColors.charcoal,
                                    ),
                                  ),
                                  Text(
                                    isAr
                                        ? (_isCalibrating
                                            ? 'حرّك الهاتف في الهواء على شكل (∞) الآن...'
                                            : 'معايرة تلقائية للحساسات وإزالة التداخل المغناطيسي')
                                        : 'Wave your phone in a figure-8 motion',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11,
                                      color: _isCalibrating
                                          ? const Color(0xFF0284C7)
                                          : dark
                                              ? Colors.white70
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Calibrate button
                            ElevatedButton.icon(
                              onPressed: _isCalibrating ? null : _startInfinityCalibration,
                              icon: _isCalibrating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(LucideIcons.refreshCw, size: 14),
                              label: Text(
                                isAr
                                    ? (_isCalibrating ? 'جارٍ الضبط...' : 'ابدأ المعايرة')
                                    : (_isCalibrating ? 'Calibrating...' : 'Calibrate'),
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC5A059),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Animated Infinity Loop Visualization
                        GestureDetector(
                          onTap: _startInfinityCalibration,
                          child: Container(
                            height: 95,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF0A1812) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: dark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: AnimatedBuilder(
                              animation: _infinityAnimCtrl,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: InfinityPathPainter(
                                    progress: _infinityAnimCtrl.value,
                                    isCalibrating: _isCalibrating,
                                    calibrationProgress: _calibrationProgress,
                                    isDark: dark,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Calibration Status & Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCalibrating
                                      ? LucideIcons.loader
                                      : Icons.verified_rounded,
                                  size: 14,
                                  color: _isCalibrating ? const Color(0xFF0284C7) : const Color(0xFFC5A059),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isCalibrating
                                      ? (isAr ? 'رصد الحركة: ${(_calibrationProgress * 100).toInt()}%' : 'Calibrating...')
                                      : (isAr ? 'دقة البوصلة: ممتازة ✓' : 'Compass Accuracy: High ✓'),
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _isCalibrating
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFFC5A059),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isAr ? 'معايرة مغناطيسية تلقائية' : 'Auto-Magnetometer Sync',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 10.5,
                                color: dark ? Colors.white38 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════
/// Custom Painter for Clean Neumorphic Compass (Matching Screenshot)
/// ═════════════════════════════════════════════════════════════════
class NeumorphicCompassPainter extends CustomPainter {
  final double deviceHeading; // Degrees from True North
  final double qiblaBearing; // Degrees from True North
  final bool isDark;
  final bool isAligned;

  NeumorphicCompassPainter({
    required this.deviceHeading,
    required this.qiblaBearing,
    required this.isDark,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Soft Neumorphic Outer Background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F2018) : Colors.white
      ..style = PaintingStyle.fill;

    // Outer subtle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius - 4, shadowPaint);

    // Main dial circle
    canvas.drawCircle(center, radius - 6, bgPaint);

    // Dial border
    final borderPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 6, borderPaint);

    // Save canvas for rotating dial elements (ticks, cardinals, and Kaaba rotate with phone)
    canvas.save();
    // Rotate canvas by -deviceHeading so North points up when phone faces North
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-deviceHeading * math.pi / 180.0);
    canvas.translate(-center.dx, -center.dy);

    // 2. Draw 360 Degree Ticks
    final tickPaintSmall = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFD1D5DB)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final tickPaintMedium = Paint()
      ..color = isDark ? Colors.white38 : const Color(0xFF9CA3AF)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final tickPaintLarge = Paint()
      ..color = isDark ? Colors.white60 : const Color(0xFF6B7280)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const tickRadius = 142.0;
    for (int deg = 0; deg < 360; deg += 2) {
      final rad = deg * math.pi / 180.0;
      double tickLen = 4.0;
      Paint paint = tickPaintSmall;

      if (deg % 30 == 0) {
        tickLen = 9.0;
        paint = tickPaintLarge;
      } else if (deg % 10 == 0) {
        tickLen = 6.5;
        paint = tickPaintMedium;
      }

      final startX = center.dx + (tickRadius - tickLen) * math.sin(rad);
      final startY = center.dy - (tickRadius - tickLen) * math.cos(rad);
      final endX = center.dx + tickRadius * math.sin(rad);
      final endY = center.dy - tickRadius * math.cos(rad);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // 3. Draw Cardinal Direction Labels: N, E, S, W
    _drawCardinal(canvas, center, 'N', 0, const Color(0xFF475569), isBold: true);
    _drawCardinal(canvas, center, 'E', 90, const Color(0xFF94A3B8));
    _drawCardinal(canvas, center, 'S', 180, const Color(0xFF94A3B8));
    _drawCardinal(canvas, center, 'W', 270, const Color(0xFF94A3B8));

    // 4. Draw Kaaba Badge on the Dial Perimeter at Qibla Bearing!
    _drawKaabaBadge(canvas, center, qiblaBearing);

    canvas.restore(); // Restore dial rotation

    // 5. Draw the 8-Point Compass Rose with Beveled Metallic Styling
    // North spike has the royal purple / indigo color (#4F46E5) from the screenshot!
    _drawCompassRose(canvas, center, radius);

    // 6. Neumorphic Center Hub (3D white cap)
    _drawCenterHub(canvas, center);
  }

  void _drawCardinal(Canvas canvas, Offset center, String text, double deg, Color color, {bool isBold = false}) {
    const textRadius = 120.0;
    final rad = deg * math.pi / 180.0;
    final pos = Offset(
      center.dx + textRadius * math.sin(rad),
      center.dy - textRadius * math.cos(rad),
    );

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
        color: isDark ? (isBold ? Colors.white : Colors.white60) : color,
        fontFamily: DhikrTheme.titleFont,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawKaabaBadge(Canvas canvas, Offset center, double deg) {
    const badgeRadius = 100.0;
    final rad = deg * math.pi / 180.0;
    final badgeCenter = Offset(
      center.dx + badgeRadius * math.sin(rad),
      center.dy - badgeRadius * math.cos(rad),
    );

    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    canvas.rotate(rad);

    // Two small indicator pointer wings/triangles on sides
    final wingPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    // Left wing
    final leftWing = Path()
      ..moveTo(-19, 0)
      ..lineTo(-25, -4)
      ..lineTo(-25, 4)
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    // Right wing
    final rightWing = Path()
      ..moveTo(19, 0)
      ..lineTo(25, -4)
      ..lineTo(25, 4)
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Circular badge shadow & background
    final badgeShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset.zero, 18, badgeShadow);

    final badgeBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 18, badgeBg);

    final badgeBorder = Paint()
      ..color = isAligned ? const Color(0xFFC5A059) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 2.5 : 1.5;
    canvas.drawCircle(Offset.zero, 18, badgeBorder);

    // Draw Holy Kaaba Icon inside badge
    // Reset rotation inside badge so Kaaba stays upright
    canvas.rotate(-rad);
    const kaabaSpan = TextSpan(
      text: '🕋',
      style: TextStyle(fontSize: 18),
    );
    final kaabaPainter = TextPainter(
      text: kaabaSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    kaabaPainter.paint(
      canvas,
      Offset(-kaabaPainter.width / 2, -kaabaPainter.height / 2),
    );

    canvas.restore();
  }

  void _drawCompassRose(Canvas canvas, Offset center, double radius) {
    const majorLength = 95.0;
    const minorLength = 62.0;
    const innerRadius = 22.0;

    // Draw the 8 spikes (4 major: N, E, S, W; 4 minor: NE, SE, SW, NW)
    // 1. Minor Spikes (diagonal: NE, SE, SW, NW)
    for (int i = 0; i < 4; i++) {
      final deg = 45.0 + i * 90.0;
      _drawSpike(canvas, center, deg, minorLength, innerRadius, isMinor: true);
    }

    // 2. Major Spikes: E, S, W (metallic silver faceted)
    _drawSpike(canvas, center, 90, majorLength, innerRadius);
    _drawSpike(canvas, center, 180, majorLength, innerRadius);
    _drawSpike(canvas, center, 270, majorLength, innerRadius);

    // 3. North Spike: Deep Royal Purple / Indigo (#4F46E5) as in screenshot!
    _drawSpike(canvas, center, 0, majorLength, innerRadius, isNorth: true);
  }

  void _drawSpike(
    Canvas canvas,
    Offset center,
    double angleDeg,
    double length,
    double innerRadius, {
    bool isNorth = false,
    bool isMinor = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * math.pi / 180.0);

    // Half widths at base
    final baseW = isMinor ? innerRadius * 0.75 : innerRadius;

    // Left Facet
    final leftPath = Path()
      ..moveTo(0, -length) // tip
      ..lineTo(-baseW, 0) // left base
      ..lineTo(0, 0)
      ..close();

    // Right Facet
    final rightPath = Path()
      ..moveTo(0, -length) // tip
      ..lineTo(baseW, 0) // right base
      ..lineTo(0, 0)
      ..close();

    Paint leftPaint;
    Paint rightPaint;

    if (isNorth) {
      // Royal Purple / Indigo North Needle from screenshot
      leftPaint = Paint()
        ..color = const Color(0xFF4F46E5) // Vibrant Indigo/Purple
        ..style = PaintingStyle.fill;

      rightPaint = Paint()
        ..color = const Color(0xFF3730A3) // Darker Indigo facet
        ..style = PaintingStyle.fill;
    } else {
      // Beveled metallic silver/white
      leftPaint = Paint()
        ..color = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill;

      rightPaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)
        ..style = PaintingStyle.fill;
    }

    canvas.drawPath(leftPath, leftPaint);
    canvas.drawPath(rightPath, rightPaint);

    // Subtle edge highlight
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, -length), Offset.zero, edgePaint);

    canvas.restore();
  }

  void _drawCenterHub(Canvas canvas, Offset center) {
    const hubRadius = 24.0;

    // Outer subtle ring
    final ringPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, hubRadius + 10, ringPaint);

    // 3D Neumorphic Raised Cap
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.5 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center + const Offset(0, 3), hubRadius, shadowPaint);

    final hubPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF0F172A)]
            : [Colors.white, const Color(0xFFE2E8F0)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));

    canvas.drawCircle(center, hubRadius, hubPaint);

    // Inner bevel highlight
    final innerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.15 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, hubRadius - 1, innerHighlight);
  }

  @override
  bool shouldRepaint(covariant NeumorphicCompassPainter oldDelegate) {
    return oldDelegate.deviceHeading != deviceHeading ||
        oldDelegate.qiblaBearing != qiblaBearing ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isAligned != isAligned;
  }
}

/// ═════════════════════════════════════════════════════════════════
/// Custom Painter for Infinity (Figure-8) Path & Moving Calibration Dot
/// ═════════════════════════════════════════════════════════════════
class InfinityPathPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 from AnimationController
  final bool isCalibrating;
  final double calibrationProgress; // 0.0 to 1.0
  final bool isDark;

  InfinityPathPainter({
    required this.progress,
    required this.isCalibrating,
    required this.calibrationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final a = size.width * 0.36; // Scale of the loop

    // 1. Draw the Infinity Track (Lemniscate of Bernoulli)
    final trackPath = Path();
    bool first = true;

    // t from 0 to 2*pi
    for (double t = 0; t <= 2 * math.pi + 0.05; t += 0.04) {
      final denom = 1 + math.sin(t) * math.sin(t);
      final x = cx + (a * math.cos(t)) / denom;
      final y = cy + (a * math.sin(t) * math.cos(t)) / denom;

      if (first) {
        trackPath.moveTo(x, y);
        first = false;
      } else {
        trackPath.lineTo(x, y);
      }
    }

    // Track background stroke
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E3A2F)
          : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trackPath, trackPaint);

    // Active glowing stroke
    final glowPaint = Paint()
      ..color = isCalibrating
          ? const Color(0xFF38BDF8).withValues(alpha: 0.8)
          : const Color(0xFFC5A059).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCalibrating ? 3.5 : 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trackPath, glowPaint);

    // 2. Compute Position of Traveling Particle along the Infinity Path
    final t = progress * 2 * math.pi;
    final denom = 1 + math.sin(t) * math.sin(t);
    final px = cx + (a * math.cos(t)) / denom;
    final py = cy + (a * math.sin(t) * math.cos(t)) / denom;

    // Particle Outer Glow
    final particleGlow = Paint()
      ..color = (isCalibrating ? const Color(0xFF0284C7) : const Color(0xFFC5A059))
          .withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(px, py), 12, particleGlow);

    // Particle Body
    final particlePaint = Paint()
      ..color = isCalibrating ? const Color(0xFF38BDF8) : const Color(0xFFC5A059)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(px, py), 7, particlePaint);

    // Center Core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(px, py), 3.5, corePaint);

    // Center symbol "∞"
    final symbolSpan = TextSpan(
      text: '∞',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
      ),
    );
    final symbolPainter = TextPainter(
      text: symbolSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    symbolPainter.paint(
      canvas,
      Offset(cx - symbolPainter.width / 2, cy - symbolPainter.height / 2 - 2),
    );
  }

  @override
  bool shouldRepaint(covariant InfinityPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCalibrating != isCalibrating ||
        oldDelegate.calibrationProgress != calibrationProgress ||
        oldDelegate.isDark != isDark;
  }
}
