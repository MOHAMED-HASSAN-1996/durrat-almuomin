import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../screens/prayer_times_screen.dart';
import '../services/prayer_times.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Luxury Pinned Adhan & Prayer Times Widget for the Home Screen.
/// Displays live countdown to the next prayer, daily prayer strip, and quick Adhan toggle.
class PinnedPrayerWidget extends StatefulWidget {
  const PinnedPrayerWidget({super.key});

  @override
  State<PinnedPrayerWidget> createState() => _PinnedPrayerWidgetState();
}

class _PinnedPrayerWidgetState extends State<PinnedPrayerWidget> {
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // Audio preview
  AudioPlayer? _previewPlayer;
  bool _isPlayingPreview = false;

  // Default coordinates: Cairo (lat: 30.0444, lng: 31.2357)
  static const double _lat = 30.0444;
  static const double _lng = 31.2357;

  late PrayerTimes _todayPrayers;
  late PrayerTimes _tomorrowPrayers;

  @override
  void initState() {
    super.initState();
    _recalculate();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  void _recalculate() {
    final now = DateTime.now();
    _todayPrayers = PrayerCalculator.calculate(
      date: now,
      lat: _lat,
      lng: _lng,
    );
    _tomorrowPrayers = PrayerCalculator.calculate(
      date: now.add(const Duration(days: 1)),
      lat: _lat,
      lng: _lng,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _previewPlayer?.dispose();
    super.dispose();
  }

  /// Determine the next prayer, its time, and duration remaining
  ({String nameAr, String nameEn, DateTime time, String key}) _getNextPrayer() {
    final prayers = [
      (nameAr: 'صَلَاةُ الفَجْر', nameEn: 'Fajr', time: _todayPrayers.fajr, key: 'fajr'),
      (nameAr: 'الشُّرُوق', nameEn: 'Sunrise', time: _todayPrayers.sunrise, key: 'sunrise'),
      (nameAr: 'صَلَاةُ الظُّهْر', nameEn: 'Dhuhr', time: _todayPrayers.dhuhr, key: 'dhuhr'),
      (nameAr: 'صَلَاةُ العَصْر', nameEn: 'Asr', time: _todayPrayers.asr, key: 'asr'),
      (nameAr: 'صَلَاةُ المَغْرِب', nameEn: 'Maghrib', time: _todayPrayers.maghrib, key: 'maghrib'),
      (nameAr: 'صَلَاةُ العِشَاء', nameEn: 'Isha', time: _todayPrayers.isha, key: 'isha'),
    ];

    for (final p in prayers) {
      if (p.time.isAfter(_now)) {
        return p;
      }
    }

    // If past Isha, next prayer is tomorrow's Fajr
    return (
      nameAr: 'صَلَاةُ الفَجْر',
      nameEn: 'Fajr',
      time: _tomorrowPrayers.fajr,
      key: 'fajr',
    );
  }

  String _formatCountdown(Duration diff) {
    if (diff.isNegative) return '٠٠:٠٠:٠٠';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTime(DateTime dt, bool isAr) {
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12
        ? (isAr ? 'م' : 'PM')
        : (isAr ? 'ص' : 'AM');
    return '$hour:$minute $period';
  }

  Future<void> _toggleAdhanPreview() async {
    HapticFeedback.lightImpact();
    if (_isPlayingPreview) {
      await _previewPlayer?.stop();
      if (mounted) setState(() => _isPlayingPreview = false);
      return;
    }

    _previewPlayer ??= AudioPlayer();
    try {
      setState(() => _isPlayingPreview = true);
      await _previewPlayer!.play(
        UrlSource('https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3'),
      );
      _previewPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingPreview = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlayingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final next = _getNextPrayer();
    final remaining = next.time.difference(_now);

    final prayersList = [
      (key: 'fajr', name: isAr ? 'الفجر' : 'Fajr', time: _todayPrayers.fajr),
      (key: 'dhuhr', name: isAr ? 'الظهر' : 'Dhuhr', time: _todayPrayers.dhuhr),
      (key: 'asr', name: isAr ? 'العصر' : 'Asr', time: _todayPrayers.asr),
      (key: 'maghrib', name: isAr ? 'المغرب' : 'Maghrib', time: _todayPrayers.maghrib),
      (key: 'isha', name: isAr ? 'العشاء' : 'Isha', time: _todayPrayers.isha),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04130F).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF0C241D),
                Color(0xFF091A15),
                Color(0xFF06120F),
              ],
            ),
            border: Border.all(
              color: DhikrColors.sand.withValues(alpha: 0.22),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Ambient Crescent Glow
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TOP BAR: Label + Location + Adhan Preview Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DhikrColors.sand.withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                LucideIcons.bellRing,
                                size: 13,
                                color: DhikrColors.sand,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr
                                  ? 'مواقيت الصلاة والنداء'
                                  : 'Prayer Call & Times',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                        // City Pill & Adhan Listen
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 11,
                                    color: DhikrColors.sand,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? 'القاهرة' : 'Cairo',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Adhan Preview Button
                            InkWell(
                              onTap: _toggleAdhanPreview,
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _isPlayingPreview
                                      ? DhikrColors.sand
                                      : DhikrColors.sand.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: DhikrColors.sand.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isPlayingPreview
                                          ? LucideIcons.volumeX
                                          : LucideIcons.volume2,
                                      size: 12,
                                      color: _isPlayingPreview
                                          ? const Color(0xFF0F1E19)
                                          : DhikrColors.sand,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isPlayingPreview
                                          ? (isAr ? 'إيقاف' : 'Stop')
                                          : (isAr ? 'الأذان' : 'Adhan'),
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: _isPlayingPreview
                                            ? const Color(0xFF0F1E19)
                                            : DhikrColors.sand,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // MAIN FOCUS: NEXT PRAYER & COUNTDOWN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Next Prayer Name & Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'الصَّلَاةُ القَادِمَة' : 'NEXT PRAYER',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: DhikrColors.sand.withValues(alpha: 0.85),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr ? next.nameAr : next.nameEn,
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${isAr ? "موعد الأذان: " : "Adhan at: "}${_formatTime(next.time, isAr)}',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Big Glowing Countdown Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF13342A),
                                Color(0xFF0B211A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.hourglass,
                                    size: 13,
                                    color: Color(0xFF34D399),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? 'متبقي على النداء' : 'Remaining',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatCountdown(remaining),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5 PRAYERS HORIZONTAL STRIP
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: prayersList.map((p) {
                          final isTarget = next.key == p.key;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isTarget
                                  ? DhikrColors.sand.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isTarget
                                    ? DhikrColors.sand.withValues(alpha: 0.45)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 11.5,
                                    fontWeight: isTarget
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isTarget
                                        ? DhikrColors.sand
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(p.time, isAr),
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 10,
                                    fontWeight: isTarget
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isTarget
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // BOTTOM LINK TO FULL PRAYER SCREEN
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrayerTimesScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAr
                                  ? 'عرض جدول الصلاة والقبلة كاملاً'
                                  : 'Full Prayer Schedule & Qibla',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: DhikrColors.sand.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isAr
                                  ? LucideIcons.chevronLeft
                                  : LucideIcons.chevronRight,
                              size: 14,
                              color: DhikrColors.sand,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
