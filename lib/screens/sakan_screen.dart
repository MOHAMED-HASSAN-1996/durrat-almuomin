import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// شاشة «خريطة السَّكَن» — نمط روتينك الروحي الأسبوعي ومسار العودة.
///
/// تعتمد على بيانات موجودة مسبقًا (الستريك + سجل الورد اليومي) وتضيف
/// تسجيلًا يوميًا ذاتيًا لدرجة السكينة (١-٥) ليربط المستخدم انتظامه بحال قلبه.
class SakanScreen extends StatelessWidget {
  const SakanScreen({super.key});

  static const List<int> _moods = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(lang, 'sakan_map'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _buildMoodRater(context, isAr, dark),
                const SizedBox(height: 20),
                _buildWeeklyPattern(context, isAr, dark),
                const SizedBox(height: 16),
                _buildReturnPath(context, isAr, dark),
                const SizedBox(height: 12),
                _buildMoodWeekRow(context, isAr, dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1) مقياس السكينة اليومي
  // --------------------------------------------------------------------------
  Widget _buildMoodRater(BuildContext context, bool isAr, bool dark) {
    final app = context.watch<AppState>();
    final lang = app.language;
    final today = app.todayMoodRating;

    const moodLabels = {
      1: ('mood_1', Colors.red),
      2: ('mood_2', Colors.orange),
      3: ('mood_3', Colors.amber),
      4: ('mood_4', Colors.lightGreen),
      5: ('mood_5', Color(0xFF2E7D32)),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF1E2E28), Color(0xFF15221E)]
              : const [Color(0xFFF6FBF8), Color(0xFFE8F3EE)],
        ),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  LucideIcons.handHeart,
                  size: 20,
                  color: dark ? const Color(0xFF5EEAD4) : DhikrColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(lang, 'sakan_how_calm'),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t(lang, 'sakan_rate_me'),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11.5,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moods.map((m) {
              final label = moodLabels[m]!;
              final selected = today == m;
              final color = label.$2;
              return GestureDetector(
                onTap: () => app.setTodayMoodRating(m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 46 : 40,
                      height: selected ? 46 : 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? color.withValues(alpha: dark ? 0.4 : 0.3)
                            : color.withValues(alpha: dark ? 0.12 : 0.08),
                        border: Border.all(
                          color: selected ? color : color.withValues(alpha: 0.3),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: Text(
                        '$m',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: selected ? 17 : 14,
                          color: selected
                              ? (dark ? Colors.white : color)
                              : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t(lang, label.$1),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 9.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected
                            ? color
                            : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (today > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.verified, size: 15, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(
                  '${isAr ? 'درجة اليوم' : AppStrings.t(lang, 'sakan_today_rating')}: $today',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2) النمط الأسبوعي (من الستريك وسجل الورد)
  // --------------------------------------------------------------------------
  Widget _buildWeeklyPattern(BuildContext context, bool isAr, bool dark) {
    final app = context.watch<AppState>();
    final lang = app.language;
    final history = app.getHistory(limit: 7);
    final streak = app.streakCount;

    // تحليل آخر ٧ أيام: عدد الأيام النشطة + توازن الصباح/المساء.
    var activeDays = 0;
    var morningDays = 0;
    var eveningDays = 0;
    for (final e in history) {
      final morning = e['morning'];
      final evening = e['evening'];
      final mComp = (morning is Map<String, dynamic> ? morning['completed'] : 0) as num;
      final eComp = (evening is Map<String, dynamic> ? evening['completed'] : 0) as num;
      if (mComp > 0 || eComp > 0) activeDays++;
      if (mComp > 0) morningDays++;
      if (eComp > 0) eveningDays++;
    }
    final consistency = history.isEmpty ? 0 : (activeDays * 100 / history.length).round();
    final nightOrMorning = morningDays >= eveningDays;
    final peakCount = nightOrMorning ? morningDays : eveningDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(dark, const Color(0xFF0F766E)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(isAr, 'sakan_consistency', LucideIcons.activity, dark,
              const Color(0xFF0F766E)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statTile(
                isAr: isAr,
                dark: dark,
                label: AppStrings.t(lang, 'sakan_week_days'),
                value: '$activeDays/${history.length}',
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(width: 10),
              _statTile(
                isAr: isAr,
                dark: dark,
                label: AppStrings.t(lang, 'sakan_consistency'),
                value: '$consistency%',
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(width: 10),
              _statTile(
                isAr: isAr,
                dark: dark,
                label: AppStrings.t(lang, 'sakan_streak'),
                value: '$streak',
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // أهدأ فترة (أنشط فترة)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.moonStar,
                  size: 22,
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? AppStrings.t(lang, 'sakan_peak') : 'Calmest anchor: ${nightOrMorning ? 'Morning' : 'Evening'}',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${nightOrMorning ? AppStrings.t(lang, 'sakan_morning') : AppStrings.t(lang, 'sakan_evening')} — $peakCount/7',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
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
    );
  }

  // --------------------------------------------------------------------------
  // 3) مسار العودة
  // --------------------------------------------------------------------------
  Widget _buildReturnPath(BuildContext context, bool isAr, bool dark) {
    final app = context.watch<AppState>();
    final lang = app.language;
    final streak = app.streakCount;

    // مسار العودة: عندما تبدأ من جديد (ستريك صغير) أو حين لا زالت اليوم.
    final needsReturn = streak <= 1;
    final accent = const Color(0xFF4E8E6A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(dark, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(isAr, 'sakan_return_path', LucideIcons.route, dark, accent),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  needsReturn ? LucideIcons.footprints : LucideIcons.shieldCheck,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      needsReturn
                          ? (isAr ? AppStrings.t(lang, 'sakan_return_empty') : 'Start fresh — one small wird holds value.')
                          : (isAr ? 'أنت على الطريق — واصل بخطوات صغيرة.' : 'You\'re on the way — keep going with small steps.'),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13.5,
                        height: 1.5,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${isAr ? AppStrings.t(lang, 'sakan_return_tip1') : 'Take the first step with the morning wird only.'}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        height: 1.5,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                    Text(
                      '• ${isAr ? AppStrings.t(lang, 'sakan_return_tip2') : 'A missed day never erases what came before it.'}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        height: 1.5,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4) صفّ درجات السكينة خلال الأسبوع
  // --------------------------------------------------------------------------
  Widget _buildMoodWeekRow(BuildContext context, bool isAr, bool dark) {
    final app = context.watch<AppState>();
    final lang = app.language;
    final moods = app.getMoodHistory(limit: 7);
    if (moods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(dark, const Color(0xFF23423B)),
        child: Text(
          AppStrings.t(lang, 'sakan_no_data'),
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 13,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
      );
    }
    // آخر ٧ أيام حتى اليوم.
    final byDate = {for (final m in moods) m['date'] as String: m['rating'] as int};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(dark, const Color(0xFF23423B)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(isAr, 'sakan_mood_week', LucideIcons.sparkles, dark, const Color(0xFF23423B)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (i) {
              final d = _dateNDaysAgo(_moods.length - 1 - i);
              final rating = byDate[d] ?? 0;
              final active = rating > 0;
              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? _moodColor(rating).withValues(alpha: dark ? 0.4 : 0.3)
                          : (dark ? DhikrColors.darkSurfaceHigh : Colors.grey.shade200),
                    ),
                    child: active
                        ? Text('$rating',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: dark ? Colors.white : _moodColor(rating),
                            ))
                        : Text('·',
                            style: TextStyle(
                              fontSize: 16,
                              color: dark ? DhikrColors.darkMuted : Colors.grey.shade400,
                            )),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dayInitial(isAr, i),
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 10,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _moodColor(int rating) {
    return switch (rating) {
      1 => Colors.red,
      2 => Colors.orange,
      3 => Colors.amber,
      4 => Colors.lightGreen,
      _ => const Color(0xFF2E7D32),
    };
  }

  String _dayInitial(bool isAr, int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    if (isAr) {
      const ar = ['س', 'ح', 'ث', 'أ', 'خ', 'ج', 'س'];
      return ar[d.weekday - 1];
    }
    const en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return en[d.weekday - 1];
  }

  String _dateNDaysAgo(int n) {
    final d = DateTime.now().subtract(Duration(days: n));
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  // --------------------------------------------------------------------------
  // أدوات مساعدة
  // --------------------------------------------------------------------------
  BoxDecoration _cardDecoration(bool dark, Color accent) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: dark
            ? const [Color(0xFF1F2A25), Color(0xFF161D1A)]
            : const [Color(0xFFF9FDFB), Color(0xFFEDF7F2)],
      ),
      border: Border.all(color: accent.withValues(alpha: dark ? 0.3 : 0.2), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: dark ? 0.12 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _cardTitle(bool isAr, String key, IconData icon, bool dark, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          AppStrings.t(isAr ? AppLanguage.arabic : AppLanguage.english, key),
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required bool isAr,
    required bool dark,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.15 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: dark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
