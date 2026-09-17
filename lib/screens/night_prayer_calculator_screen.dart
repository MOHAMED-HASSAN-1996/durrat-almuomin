import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/prayer_times.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

class NightPrayerCalculatorScreen extends StatefulWidget {
  const NightPrayerCalculatorScreen({super.key});

  @override
  State<NightPrayerCalculatorScreen> createState() => _NightPrayerCalculatorScreenState();
}

class _NightPrayerCalculatorScreenState extends State<NightPrayerCalculatorScreen> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final storage = context.read<AppState>().storage;
    final saved = storage.getSavedLocation();
    final lat = (saved?['lat'] as num?)?.toDouble() ?? 30.0444;
    final lng = (saved?['lng'] as num?)?.toDouble() ?? 31.2357;

    // حساب مواقيت الصلاة لليوم وللغد لتحديد موعد المغرب والفجر بدقة
    final todayPrayers = PrayerCalculator.calculate(date: _now, lat: lat, lng: lng);
    final tomorrowPrayers = PrayerCalculator.calculate(
      date: _now.add(const Duration(days: 1)),
      lat: lat,
      lng: lng,
    );

    // تحديد وقت المغرب والفجر المناسبين لليل الحالي
    DateTime maghribTime;
    DateTime fajrTime;

    if (_now.isBefore(todayPrayers.fajr)) {
      // نحن قبل فجر اليوم: المغرب كان أمس، والفجر هو فجر اليوم
      final yesterdayPrayers = PrayerCalculator.calculate(
        date: _now.subtract(const Duration(days: 1)),
        lat: lat,
        lng: lng,
      );
      maghribTime = yesterdayPrayers.maghrib;
      fajrTime = todayPrayers.fajr;
    } else {
      // نحن بعد فجر اليوم: المغرب هو مغرب اليوم، والفجر هو فجر الغد
      maghribTime = todayPrayers.maghrib;
      fajrTime = tomorrowPrayers.fajr;
    }

    final totalNightDuration = fajrTime.difference(maghribTime);
    final oneThirdSeconds = totalNightDuration.inSeconds / 3.0;

    final firstThirdEnd = maghribTime.add(Duration(seconds: oneThirdSeconds.round()));
    final midnightTime = maghribTime.add(Duration(seconds: (totalNightDuration.inSeconds / 2.0).round()));
    final lastThirdStart = maghribTime.add(Duration(seconds: (oneThirdSeconds * 2).round()));

    // هل نحن الآن في الثلث الأخير؟
    final isInLastThird = _now.isAfter(lastThirdStart) && _now.isBefore(fajrTime);
    final isBeforeLastThird = _now.isBefore(lastThirdStart);

    String countdownText = '';
    if (isInLastThird) {
      final diff = fajrTime.difference(_now);
      countdownText = 'متبقٍ على أذان الفجر: ${_formatDuration(diff)}';
    } else if (isBeforeLastThird) {
      final diff = lastThirdStart.difference(_now);
      countdownText = 'متبقٍ على بدء الثلث الأخير: ${_formatDuration(diff)}';
    } else {
      // بعد الفجر
      final diff = lastThirdStart.difference(_now);
      countdownText = 'متبقٍ على ثلث الليل القادم: ${_formatDuration(diff)}';
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF07130F) : const Color(0xFFF7F6F2),
        appBar: AppBar(
          title: Text(
            isAr ? 'حاسبة الثلث الأخير وقيام الليل 🌙' : 'Tahajjud & Night Calculator 🌙',
            style: const TextStyle(
              fontFamily: DhikrTheme.titleFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              // ── Hero Countdown Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isInLastThird
                        ? (dark
                            ? [const Color(0xFF133E2B), const Color(0xFF0A2218)]
                            : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)])
                        : (dark
                            ? [const Color(0xFF16251F), const Color(0xFF0E1A15)]
                            : [Colors.white, const Color(0xFFF3F2EC)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isInLastThird
                        ? const Color(0xFF10B981)
                        : (dark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    width: isInLastThird ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isInLastThird
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isInLastThird ? LucideIcons.sparkles : LucideIcons.moon,
                          size: 20,
                          color: isInLastThird ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isInLastThird
                            ? 'أنت الآن في الثلث الأخير من الليل 🤲'
                            : 'وقت الثلث الأخير الليلة',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isInLastThird
                                ? (dark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46))
                                : (dark ? Colors.white : const Color(0xFF1F2937)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'يبدأ من ${_formatTime(lastThirdStart)} حتى ${_formatTime(fajrTime)}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInLastThird
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : (dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countdownText,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isInLastThird
                              ? (dark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
                              : (dark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Night Division Breakdown Cards ──
              Text(
                isAr ? 'تقسيم ساعات الليل الشرعية' : 'Night Division',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: dark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),

              _buildNightCard(
                title: 'غروب الشمس (أذان المغرب)',
                subtitle: 'بداية الليل الشرعي وتناول الإفطار',
                time: _formatTime(maghribTime),
                icon: LucideIcons.sunset,
                color: const Color(0xFFD97706),
                dark: dark,
              ),
              const SizedBox(height: 8),

              _buildNightCard(
                title: 'نهاية الثلث الأول',
                subtitle: 'وقت مستحب لصلاة العشاء والوتر قبل النوم',
                time: _formatTime(firstThirdEnd),
                icon: LucideIcons.clock,
                color: const Color(0xFF3B82F6),
                dark: dark,
              ),
              const SizedBox(height: 8),

              _buildNightCard(
                title: 'منتصف الليل الشرعي',
                subtitle: 'آخر وقت لصلاة العشاء اختياراً (نصف الليل)',
                time: _formatTime(midnightTime),
                icon: LucideIcons.moonStar,
                color: const Color(0xFF8B5CF6),
                dark: dark,
              ),
              const SizedBox(height: 8),

              _buildNightCard(
                title: 'بداية الثلث الأخير (وقت السحر)',
                subtitle: '«ينزل ربنا إلى السماء الدنيا فيقول: هل من داعٍ فأستجيب له؟»',
                time: _formatTime(lastThirdStart),
                icon: LucideIcons.sparkles,
                color: const Color(0xFF10B981),
                isHighlighted: true,
                dark: dark,
              ),
              const SizedBox(height: 8),

              _buildNightCard(
                title: 'طلوع الفجر الصادق (أذان الفجر)',
                subtitle: 'نهاية الليل ووقت الإمساك وبدء صلاة الفجر',
                time: _formatTime(fajrTime),
                icon: LucideIcons.sunrise,
                color: const Color(0xFFEF4444),
                dark: dark,
              ),

              const SizedBox(height: 20),

              // ── Recommended Duas & Tahajjud Virtues ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF13221B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.heart, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'دعاء النبي ﷺ عند قيام الليل' : 'Prophetic Tahajjud Dua',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: dark ? const Color(0xFFA7F3D0) : const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '«اللَّهُمَّ لَكَ الحَمْدُ أَنْتَ نُورُ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، وَلَكَ الحَمْدُ أَنْتَ قَيِّمُ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، أَنْتَ الحَقُّ، وَوَعْدُكَ الحَقُّ، وَقَوْلُكَ الحَقُّ، وَلِقَاؤُكَ الحَقُّ، وَالجَنَّةُ حَقٌّ، وَالنَّارُ حَقٌّ، فَاغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ»',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 14.5,
                        height: 1.8,
                        color: dark ? Colors.white : const Color(0xFF1F2937),
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

  String _formatDuration(Duration d) {
    if (d.isNegative) return '٠٠:٠٠:٠٠';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildNightCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required bool dark,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (dark ? const Color(0xFF18382A) : const Color(0xFFECFDF5))
            : (dark ? const Color(0xFF11221B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? color : (dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: dark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11.5,
                    color: dark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
