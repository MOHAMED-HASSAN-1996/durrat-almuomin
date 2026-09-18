import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../screens/prayer_times_screen.dart';
import '../services/prayer_times.dart';
import '../services/home_widget_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'calendar_widget.dart';

/// Atmospheric, ultra-curved Hero Card designed in RonDesignLab's signature style.
/// Displays Hijri & Gregorian dates, current time, next prayer countdown, and a 5-prayer mini-timeline.
class HomeHeroCard extends StatefulWidget {
  const HomeHeroCard({super.key});

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<HomeHeroCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  String? _lastWidgetSignature;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAr = appState.language == AppLanguage.arabic;
    final streak = appState.streakCount;

    // Location & coordinates (from saved preferences or default Baghdad, Iraq)
    final loc = appState.storage.getSavedLocation();
    final lat = (loc?['lat'] as num?)?.toDouble() ?? 33.3152;
    final lng = (loc?['lng'] as num?)?.toDouble() ?? 44.3661;

    // Calculate prayer times
    final prayerTimes = PrayerCalculator.calculate(
      date: _now,
      lat: lat,
      lng: lng,
    );

    // Determine next prayer & remaining duration
    final (nextNameAr, nextNameEn, nextTime, remainingStr, nextKey) =
        _getNextPrayerInfo(prayerTimes, _now, isAr);

    final currentPrayerName = isAr ? nextNameAr : nextNameEn;
    final currentPrayerTime = _formatPrayerTime(nextTime, isAr);

    final fajrStr = _formatTimeOnly(prayerTimes.fajr, isAr);
    final sunriseStr = _formatTimeOnly(prayerTimes.sunrise, isAr);
    final dhuhrStr = _formatTimeOnly(prayerTimes.dhuhr, isAr);
    final asrStr = _formatTimeOnly(prayerTimes.asr, isAr);
    final maghribStr = _formatTimeOnly(prayerTimes.maghrib, isAr);
    final ishaStr = _formatTimeOnly(prayerTimes.isha, isAr);

    // Widget date payload (rendered as calligraphy + Eastern Arabic digits)
    final widgetDayName = HijriDate.dayName(_now, true);
    final (widgetHijriYear, widgetHijriMonth, widgetHijriDay) =
        HijriDate.toHijri(_now);
    final widgetHijriDate =
        '${_toArabicDigits('$widgetHijriDay')} ${HijriDate.hijriMonths[widgetHijriMonth - 1]} ${_toArabicDigits('$widgetHijriYear')} هـ';
    final widgetGregorianDate =
        '$widgetDayName، ${_toArabicDigits('${_now.day}')} ${HijriDate.gregorianMonthsAr[_now.month - 1]} ${_toArabicDigits('${_now.year}')} م';

    final widgetSignature =
        '$currentPrayerName|$currentPrayerTime|$sunriseStr|$widgetHijriDate';
    if (_lastWidgetSignature != widgetSignature) {
      _lastWidgetSignature = widgetSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HomeWidgetService.instance.updateHomeWidget(
          nextPrayerName: currentPrayerName,
          nextPrayerTime: currentPrayerTime,
          nextPrayerKey: nextKey,
          nextPrayerTimestamp: nextTime.millisecondsSinceEpoch,
          fajrTime: fajrStr,
          sunriseTime: sunriseStr,
          dhuhrTime: dhuhrStr,
          asrTime: asrStr,
          maghribTime: maghribStr,
          ishaTime: ishaStr,
          widgetDayCalligraphy: widgetDayName,
          widgetHijriDate: widgetHijriDate,
          widgetGregorianDate: widgetGregorianDate,
          streakCount: streak,
          prayerTasks: appState.todayPrayerTasks,
        );
      });
    }

    // Format Dates
    final hijriStr = HijriDate.format(_now, isAr);
    final dayName = HijriDate.dayName(_now, isAr);
    final gregorianMonth = isAr
        ? HijriDate.gregorianMonthsAr[_now.month - 1]
        : HijriDate.gregorianMonthsEn[_now.month - 1];
    final gregorianStr = isAr
        ? '$dayName، ${_now.day} $gregorianMonth'
        : '$dayName, ${_now.day} $gregorianMonth';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF16382E),
              Color(0xFF0F2620),
              Color(0xFF091814),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071410).withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 1. Photographic Image Backdrop (changes dynamically per prayer time)
              Positioned.fill(
                child: Image.asset(
                  switch (nextKey) {
                    'fajr' => 'assets/images/hero_fajr.png',
                    'sunrise' => 'assets/images/hero_fajr.png',
                    'dhuhr' => 'assets/images/hero_dhuhr.png',
                    'asr' => 'assets/images/hero_asr.png',
                    'maghrib' => 'assets/images/hero_maghrib.png',
                    'isha' => 'assets/images/hero_isha.png',
                    _ => 'assets/images/hero_card_bg.png',
                  },
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/hero_card_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 2. Translucent Night Overlay for readability & high image visibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF081C16).withValues(alpha: 0.18),
                        const Color(0xFF061712).withValues(alpha: 0.38),
                        const Color(0xFF04100C).withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Ambient Highlights
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeroAtmospherePainter(),
                ),
              ),

              // 4. Foreground Content (Compact, balanced, no wasted space)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar inside Hero: Hijri Date Pill + Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Hijri Date Pill with DGA Calendar Icon
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.calendarDays,
                                size: 13,
                                color: DhikrColors.sage,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hijriStr,
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Streak Pill (DGA Flame Icon)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.flame,
                                size: 13,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$streak ${isAr ? 'يوم' : 'd'}',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFDE68A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Middle Section: Current Time + Date on RIGHT, Next prayer info on LEFT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Current Time display + Gregorian Date (Appears on the RIGHT in RTL)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(
                              _formatCurrentTime(_now, isAr),
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gregorianStr,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                        // 2. Next prayer details & countdown (Appears on the LEFT in RTL)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAr ? 'الصلاة القادمة:' : 'Next:',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: const [
                                      Shadow(color: Colors.black87, blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAr ? nextNameAr : nextNameEn,
                                  style: const TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFA5E6C7),
                                    shadows: [
                                      Shadow(color: Colors.black87, blurRadius: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Remaining countdown pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF4E9E80).withValues(alpha: 0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    remainingStr,
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFA5E6C7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom: 5-Prayer Mini Timeline (Compact)
                    _buildPrayerTimeline(prayerTimes, nextKey, appState, isAr),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimeline(
    PrayerTimes pt,
    String nextKey,
    AppState appState,
    bool isAr,
  ) {
    final list = [
      ('fajr', isAr ? 'الفجر' : 'Fajr', pt.fajr),
      ('dhuhr', isAr ? 'الظهر' : 'Dhuhr', pt.dhuhr),
      ('asr', isAr ? 'العصر' : 'Asr', pt.asr),
      ('maghrib', isAr ? 'المغرب' : 'Maghrib', pt.maghrib),
      ('isha', isAr ? 'العشاء' : 'Isha', pt.isha),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: list.map((item) {
          final key = item.$1;
          final name = item.$2;
          final time = item.$3;
          final isNext = key == nextKey;
          final isDone = appState.isPrayerTaskCompleted(key);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isNext
                    ? const Color(0xFF2E6353).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isNext
                      ? const Color(0xFF4E9E80).withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isNext) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA5E6C7),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11.5,
                            fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                            color: isNext
                                ? const Color(0xFFA5E6C7)
                                : Colors.white.withValues(alpha: isDone ? 0.9 : 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTimeOnly(time, isAr),
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 12,
                      fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                      color: isNext
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  (String, String, DateTime, String, String) _getNextPrayerInfo(
    PrayerTimes pt,
    DateTime now,
    bool isAr,
  ) {
    final list = [
      ('fajr', 'الفجر', 'Fajr', pt.fajr),
      ('dhuhr', 'الظهر', 'Dhuhr', pt.dhuhr),
      ('asr', 'العصر', 'Asr', pt.asr),
      ('maghrib', 'المغرب', 'Maghrib', pt.maghrib),
      ('isha', 'العشاء', 'Isha', pt.isha),
    ];

    for (final item in list) {
      if (item.$4.isAfter(now)) {
        final diff = item.$4.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        final remaining = isAr
            ? (hours > 0 ? 'متبقي $hours س و $mins د' : 'متبقي $mins دقيقة')
            : (hours > 0 ? '${hours}h ${mins}m left' : '${mins}m left');
        return (item.$2, item.$3, item.$4, remaining, item.$1);
      }
    }

    // After Isha -> Tomorrow's Fajr
    final tomorrowFajr = pt.fajr.add(const Duration(days: 1));
    final diff = tomorrowFajr.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final remaining = isAr
        ? 'متبقي $hours س و $mins د'
        : '${hours}h ${mins}m left';
    return ('الفجر', 'Fajr', tomorrowFajr, remaining, 'fajr');
  }

  String _formatPrayerTime(DateTime dt, bool isAr) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour < 12;
    final period = am ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    return '$h:$m $period';
  }

  String _formatCurrentTime(DateTime dt, bool isAr) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour < 12;
    final period = am ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    return '$h:$m $period';
  }

  String _formatTimeOnly(DateTime dt, bool isAr) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const _easternDigits = '٠١٢٣٤٥٦٧٨٩';

  /// Converts Western (0-9) digits in [input] to Eastern Arabic digits (٠-٩).
  String _toArabicDigits(String input) {
    return input.replaceAllMapped(RegExp(r'\d'), (m) {
      final digit = int.parse(m.group(0)!);
      return _easternDigits[digit];
    });
  }
}

/// Atmospheric custom painter that draws soft mesh aurora glow
/// and delicate silhouette elements behind the card.
class _HeroAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Emerald Aurora Mesh Glow
    final glowCenter = Offset(w * 0.85, h * 0.25);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2C6352).withValues(alpha: 0.45),
          const Color(0xFF1A4538).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: w * 0.55));
    canvas.drawCircle(glowCenter, w * 0.55, glowPaint);

    // 2. Faint Arch Outline in the upper background
    final arch = Path();
    arch.moveTo(w * 0.65, h);
    arch.lineTo(w * 0.65, h * 0.45);
    arch.cubicTo(
      w * 0.65,
      h * 0.15,
      w * 0.85,
      h * 0.05,
      w * 0.95,
      0,
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // 3. Subtle stars
    final starPaint = Paint()..color = const Color(0xFFC7F3DE).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(w * 0.72, h * 0.22), 1.2, starPaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.18), 1.6, starPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.38), 1.0, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
