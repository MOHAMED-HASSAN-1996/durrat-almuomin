import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../screens/prayer_times_screen.dart';
import '../services/aladhan_service.dart';
import '../services/prayer_times.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Hijri date conversion & formatting
class HijriDate {
  static const List<String> hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> hijriMonthsEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];

  static const List<String> weekDays = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const List<String> weekDaysEn = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> weekDaysShortAr = [
    'أحد',
    'إثن',
    'ثلا',
    'أرب',
    'خمي',
    'جمع',
    'سبت',
  ];

  static const List<String> weekDaysShortEn = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> gregorianMonthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> gregorianMonthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static (int year, int month, int day) toHijri(DateTime date) {
    final a = ((14 - date.month) / 12).floor();
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;
    final jd =
        date.day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;

    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j =
        ((10985 - l2) / 5316).floor() * ((50 * l2) / 17719).floor() +
        (l2 / 5670).floor() * ((43 * l2) / 15238).floor();
    final l3 =
        l2 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = ((24 * l3) / 709).floor();
    final day = l3 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;

    return (year, month, day);
  }

  static String format(DateTime date, bool isArabic) {
    final (year, month, day) = toHijri(date);
    if (isArabic) {
      return '$day ${hijriMonths[month - 1]} $year هـ';
    } else {
      return '$day ${hijriMonthsEn[month - 1]} $year AH';
    }
  }

  static String monthName(DateTime date, bool isArabic) {
    final (_, month, _) = toHijri(date);
    return isArabic ? hijriMonths[month - 1] : hijriMonthsEn[month - 1];
  }

  static String dayName(DateTime date, bool isArabic) {
    return isArabic ? weekDays[date.weekday % 7] : weekDaysEn[date.weekday % 7];
  }

  static String dayShortName(DateTime date, bool isArabic) {
    return isArabic
        ? weekDaysShortAr[date.weekday % 7]
        : weekDaysShortEn[date.weekday % 7];
  }

  static String gregorianMonthName(DateTime date, bool isArabic) {
    return isArabic
        ? gregorianMonthsAr[date.month - 1]
        : gregorianMonthsEn[date.month - 1];
  }
}

/// A Masterpiece Islamic Calendar Card (supports compact minimalist mode)
class CalendarWidget extends StatefulWidget {
  final bool compact;
  final bool? forceDark;

  const CalendarWidget({super.key, this.compact = false, this.forceDark});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
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
    final lang = context.watch<AppState>().language;
    final dark =
        widget.forceDark ?? (Theme.of(context).brightness == Brightness.dark);
    final isArabic = lang == AppLanguage.arabic;
    final today = DateTime.now();

    final (hijriYear, hijriMonth, hijriDay) = HijriDate.toHijri(_selectedDate);

    final isFriday = _selectedDate.weekday == DateTime.friday;
    final isWhiteDay = hijriDay == 13 || hijriDay == 14 || hijriDay == 15;
    final isRamadan = hijriMonth == 9;

    String? occasionTag;
    if (isRamadan) {
      occasionTag = isArabic ? 'شهر رمضان المبارك' : 'Ramadan';
    } else if (isFriday) {
      occasionTag = isArabic ? 'جمعة مباركة' : 'Blessed Friday';
    } else if (isWhiteDay) {
      occasionTag = isArabic ? 'من الأيام البيض' : 'White Days';
    }

    final primaryAccent = dark ? DhikrColors.sage : DhikrColors.forest;

    if (widget.compact) {
      return _buildCompactDateCard(
        context: context,
        isArabic: isArabic,
        dark: dark,
        primaryAccent: primaryAccent,
        hijriDay: hijriDay,
        hijriMonth: hijriMonth,
        hijriYear: hijriYear,
        date: _selectedDate,
        occasionTag: occasionTag,
      );
    }

    // Days in current week (Sunday to Saturday)
    final sundayOffset = _selectedDate.weekday % 7;
    final sunday = _selectedDate.subtract(Duration(days: sundayOffset));
    final weekDays = List.generate(7, (i) => sunday.add(Duration(days: i)));

    final isSelectedToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? [DikrColorsCustom.darkCardBg, DikrColorsCustom.darkCardBg2]
              : [Colors.white, DhikrColors.ivoryWarm],
        ),
        border: Border.all(
          color: dark
              ? primaryAccent.withValues(alpha: 0.25)
              : primaryAccent.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.4)
                : DhikrColors.forest.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background crescent & stars watermark
            Positioned(
              top: -20,
              left: isArabic ? -20 : null,
              right: isArabic ? null : -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: dark ? 0.06 : 0.04,
                  child: Icon(
                    Icons.nights_stay_rounded,
                    size: 160,
                    color: primaryAccent,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TOP BAR: Islamic Month & Year + Occasion / Today Button ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Month icon indicator
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryAccent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Month & Year header
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              HijriDate.monthName(_selectedDate, isArabic),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? DhikrColors.darkText
                                    : DhikrColors.charcoal,
                              ),
                            ),
                            Text(
                              isArabic ? '$hijriYear هجرية' : '$hijriYear AH',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: dark
                                    ? DhikrColors.darkMuted
                                    : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Occasion Tag or "Today" return button
                      if (!isSelectedToday)
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedDate = today);
                          },
                          icon: const Icon(Icons.today_rounded, size: 16),
                          label: Text(
                            isArabic ? 'اليوم' : 'Today',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      else if (occasionTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFC5A059,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFFC5A059,
                              ).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            occasionTag,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? const Color(0xFFE5C378)
                                  : const Color(0xFF996515),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- WEEK STRIP: Interactive days showing Day name OUTSIDE the box, and Hijri day inside the box ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((d) {
                      final isSelected =
                          d.year == _selectedDate.year &&
                          d.month == _selectedDate.month &&
                          d.day == _selectedDate.day;
                      final isRealToday =
                          d.year == today.year &&
                          d.month == today.month &&
                          d.day == today.day;
                      final dayHijri = HijriDate.toHijri(d);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = d);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Day name OUTSIDE the box — full name (الأحد، الإثنين، ...)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    HijriDate.dayName(d, isArabic),
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 10,
                                      height: 1.4,
                                      fontWeight: isSelected || isRealToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? primaryAccent
                                          : (isRealToday
                                                ? (dark
                                                      ? const Color(0xFFE5C378)
                                                      : const Color(0xFF996515))
                                                : (dark
                                                      ? DhikrColors.darkMuted
                                                      : DhikrColors
                                                            .charcoalSoft)),
                                    ),
                                  ),
                                ),
                              ),
                              // Number Box
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryAccent
                                      : (isRealToday
                                            ? primaryAccent.withValues(
                                                alpha: 0.14,
                                              )
                                            : (dark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.04,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: 0.6,
                                                    ))),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryAccent
                                        : (isRealToday
                                              ? primaryAccent.withValues(
                                                  alpha: 0.45,
                                                )
                                              : (dark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06,
                                                      )
                                                    : DhikrColors.charcoal
                                                          .withValues(
                                                            alpha: 0.06,
                                                          ))),
                                    width: isRealToday ? 1.4 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: primaryAccent.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${dayHijri.$3}',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 16,
                                      fontWeight: isSelected || isRealToday
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (dark
                                                ? DhikrColors.darkText
                                                : DhikrColors.charcoal),
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

                  const SizedBox(height: 14),

                  // --- BOTTOM FOOTER: Gregorian Date & Day Info ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : primaryAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : primaryAccent.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Day name full
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              HijriDate.dayName(_selectedDate, isArabic),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? DhikrColors.darkText
                                    : DhikrColors.charcoal,
                              ),
                            ),
                          ],
                        ),

                        // Gregorian Date
                        Text(
                          '${_selectedDate.day} ${HijriDate.gregorianMonthName(_selectedDate, isArabic)} ${_selectedDate.year} ${isArabic ? 'م' : 'AD'}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
            ),
          ],
        ),
      ),
    );
  }

  /// Islamic Pattern Hero Date Card (Awwwards / Framer style with Arabesque lattice, live clock & next prayer countdown)
  Widget _buildCompactDateCard({
    required BuildContext context,
    required bool isArabic,
    required bool dark,
    required Color primaryAccent,
    required int hijriDay,
    required int hijriMonth,
    required int hijriYear,
    required DateTime date,
    required String? occasionTag,
  }) {
    final dayName = HijriDate.dayName(date, isArabic);
    final hijriMonthName = isArabic
        ? HijriDate.hijriMonths[hijriMonth - 1]
        : HijriDate.hijriMonthsEn[hijriMonth - 1];
    final gregMonthName = HijriDate.gregorianMonthName(date, isArabic);
    final hijriFormatted = isArabic
        ? '$dayName، $hijriDay $hijriMonthName $hijriYear هـ'
        : '$dayName, $hijriDay $hijriMonthName $hijriYear AH';
    final gregFormatted = isArabic
        ? '${date.day} $gregMonthName ${date.year} م'
        : '${date.day} $gregMonthName ${date.year} AD';

    // 1. Calculate live high-clarity time
    final rawH = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final hourStr = rawH.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final secStr = _now.second.toString().padLeft(2, '0');
    final isPm = _now.hour >= 12;
    final periodStr = isArabic ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');

    // 2. Next prayer calculation from offline prayer calculator & saved location
    final storage = context.read<AppState>().storage;
    final savedLoc = storage.getSavedLocation();
    final lat = (savedLoc?['lat'] as num?)?.toDouble() ?? 30.0444;
    final lng = (savedLoc?['lng'] as num?)?.toDouble() ?? 31.2357;

    // استخدام كاش Aladhan إن وُجد فورياً وإلا الحساب المحلي
    final cachedToday = AladhanService.instance.cachedSync(_now, lat, lng);
    final prayerTimes = cachedToday != null
        ? PrayerTimes(
            fajr: cachedToday['fajr']!,
            sunrise: cachedToday['sunrise']!,
            dhuhr: cachedToday['dhuhr']!,
            asr: cachedToday['asr']!,
            maghrib: cachedToday['maghrib']!,
            isha: cachedToday['isha']!,
          )
        : PrayerCalculator.calculate(
            date: _now,
            lat: lat,
            lng: lng,
          );

    final prayersList = [
      ('الفجر', 'Fajr', prayerTimes.fajr, LucideIcons.sunrise),
      ('الشروق', 'Sunrise', prayerTimes.sunrise, LucideIcons.sunMedium),
      ('الظهر', 'Dhuhr', prayerTimes.dhuhr, LucideIcons.sun),
      ('العصر', 'Asr', prayerTimes.asr, LucideIcons.cloudSun),
      ('المغرب', 'Maghrib', prayerTimes.maghrib, LucideIcons.sunset),
      ('العشاء', 'Isha', prayerTimes.isha, LucideIcons.moonStar),
    ];

    (String, String, DateTime, IconData)? nextPrayer;
    for (int i = 0; i < prayersList.length; i++) {
      if (prayersList[i].$3.isAfter(_now)) {
        nextPrayer = prayersList[i];
        break;
      }
    }
    if (nextPrayer == null) {
      final tomorrow = _now.add(const Duration(days: 1));
      final cachedTm =
          AladhanService.instance.cachedSync(tomorrow, lat, lng);
      final tmPrayers = cachedTm != null
          ? PrayerTimes(
              fajr: cachedTm['fajr']!,
              sunrise: cachedTm['sunrise']!,
              dhuhr: cachedTm['dhuhr']!,
              asr: cachedTm['asr']!,
              maghrib: cachedTm['maghrib']!,
              isha: cachedTm['isha']!,
            )
          : PrayerCalculator.calculate(
              date: tomorrow,
              lat: lat,
              lng: lng,
            );
      nextPrayer = ('الفجر', 'Fajr', tmPrayers.fajr, LucideIcons.sunrise);
    }

    final diff = nextPrayer.$3.difference(_now);
    final hRem = diff.inHours;
    final mRem = diff.inMinutes % 60;
    final countdownStr = isArabic
        ? (hRem > 0
              ? 'متبقي $hRem س و $mRem د'
              : (mRem > 0 ? 'متبقي $mRem دقيقة' : 'حان موعد الصلاة الآن'))
        : (hRem > 0
              ? '${hRem}h ${mRem}m left'
              : (mRem > 0 ? '${mRem}m left' : 'Prayer time now'));

    final ph = nextPrayer.$3.hour % 12 == 0 ? 12 : nextPrayer.$3.hour % 12;
    final pm = nextPrayer.$3.minute.toString().padLeft(2, '0');
    final pPm = nextPrayer.$3.hour >= 12;
    final prayerTimeFormatted = isArabic
        ? '$ph:$pm ${pPm ? "م" : "ص"}'
        : '$ph:$pm ${pPm ? "PM" : "AM"}';
    final prayerName = isArabic ? nextPrayer.$1 : nextPrayer.$2;

    const gold = Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  const Color(0xFF0D1711),
                  const Color(0xFF132219),
                  const Color(0xFF0B140F),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF7FCF9),
                  const Color(0xFFEFF8F3),
                ],
        ),
        border: Border.all(
          color: primaryAccent.withValues(alpha: dark ? 0.28 : 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: dark ? 0.14 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Islamic Geometric Pattern Backdrop
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: primaryAccent.withValues(alpha: dark ? 0.048 : 0.032),
                  strokeWidth: 0.85,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ROW 1: TOP BAR (Islamic Badge + Occasion Tag) ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(
                            alpha: dark ? 0.16 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: primaryAccent.withValues(alpha: 0.24),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryAccent.withValues(alpha: 0.7),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              isArabic
                                  ? 'التقويم الإسلامي المعتمد'
                                  : 'Islamic Calendar',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? DhikrColors.darkText
                                    : DhikrColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Occasion / Daily Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: dark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.32),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.sparkles,
                              size: 12.5,
                              color: gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              occasionTag ??
                                  (isArabic ? 'ورد اليوم' : 'Daily Adhkar'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: dark ? const Color(0xFFFBBF24) : gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // --- ROW 2: MASTER CLOCK & CALENDAR CARD (Awwwards Studio Hero Layout) ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF09120D).withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryAccent.withValues(
                          alpha: dark ? 0.22 : 0.14,
                        ),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.25 : 0.03,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Large Natural Digital Clock (Awwwards Clean Digits)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Big Digits: 10:14
                            Text(
                              '$hourStr:$minStr',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                letterSpacing: -0.5,
                                color: dark
                                    ? Colors.white
                                    : const Color(0xFF0D331F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Period & Seconds Column (ص / م + الثواني الحية)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Period Badge (م / ص)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryAccent,
                                        primaryAccent.withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    periodStr,
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3.5),
                                // Pulsing Seconds (ثانية)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$secStr ث',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: dark
                                            ? DhikrColors.darkMuted
                                            : DhikrColors.charcoalSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Elegant Hairline Divider
                        Container(
                          width: 1,
                          height: 42,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: primaryAccent.withValues(
                            alpha: dark ? 0.22 : 0.14,
                          ),
                        ),

                        // Hijri & Gregorian Date Column (التاريخ الهجري والميلادي)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hijriFormatted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                gregFormatted,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                  ),

                  const SizedBox(height: 12),

                  // --- ROW 3: NEXT PRAYER SHOWCASE RUNWAY (Awwwards Architectural Runway) ---
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrayerTimesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF101C14) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: gold.withValues(alpha: dark ? 0.32 : 0.22),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: dark ? 0.12 : 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Illuminated Prayer Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: gold.withValues(
                                  alpha: dark ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: gold.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Icon(nextPrayer.$4, size: 22, color: gold),
                            ),
                            const SizedBox(width: 12),

                            // Prayer Info & Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isArabic
                                                  ? 'الصلاة القادمة:'
                                                  : 'Next:',
                                              style: TextStyle(
                                                fontFamily:
                                                    DhikrTheme.arabicFont,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: dark
                                                    ? DhikrColors.darkMuted
                                                    : DhikrColors.charcoalSoft,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                'صلاة $prayerName',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily:
                                                      DhikrTheme.arabicFont,
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: dark
                                                      ? Colors.white
                                                      : DhikrColors.charcoal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Exact Prayer Time Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: gold.withValues(
                                            alpha: dark ? 0.24 : 0.13,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        child: Text(
                                          prayerTimeFormatted,
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: gold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  // Live Countdown
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.timer,
                                        size: 12.5,
                                        color: gold,
                                      ),
                                      const SizedBox(width: 4.5),
                                      Expanded(
                                        child: Text(
                                          countdownStr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: gold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isArabic ? 'المواقيت' : 'Times',
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: dark
                                              ? DhikrColors.darkMuted
                                              : DhikrColors.charcoalSoft,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        isArabic
                                            ? LucideIcons.chevronLeft
                                            : LucideIcons.chevronRight,
                                        size: 12.5,
                                        color: dark
                                            ? DhikrColors.darkMuted
                                            : DhikrColors.charcoalSoft,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// Islamic Geometric Pattern Painter (Arabesque tessellation & 8-pointed star motif)
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const IslamicPatternPainter({required this.color, this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    const step = 42.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        const r = step * 0.42;
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final angle = i * 3.141592653589793 / 4;
          final px = x + r * math.cos(angle);
          final py = y + r * math.sin(angle);
          const innerR = r * 0.55;
          final inAngle = angle + 3.141592653589793 / 8;
          final inX = x + innerR * math.cos(inAngle);
          final inY = y + innerR * math.sin(inAngle);
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
          path.lineTo(inX, inY);
        }
        path.close();
        canvas.drawPath(path, paint);

        // Interlocking diamond diagonals
        canvas.drawLine(Offset(x - r, y), Offset(x, y - r), paint);
        canvas.drawLine(Offset(x, y - r), Offset(x + r, y), paint);
        canvas.drawLine(Offset(x + r, y), Offset(x, y + r), paint);
        canvas.drawLine(Offset(x, y + r), Offset(x - r, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Helper colors for card gradients
class DikrColorsCustom {
  DikrColorsCustom._();
  static const Color darkCardBg = Color(0xFF1E2823);
  static const Color darkCardBg2 = Color(0xFF26332C);
}
