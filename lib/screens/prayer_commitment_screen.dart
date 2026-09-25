import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/nawafil_tracker_sheet.dart';

/// شاشة تحليلات وسجل الالتزام بالصلوات الخمس والسنن الرواتب والنوافل
class PrayerCommitmentScreen extends StatefulWidget {
  const PrayerCommitmentScreen({super.key});

  @override
  State<PrayerCommitmentScreen> createState() => _PrayerCommitmentScreenState();
}

class _PrayerCommitmentScreenState extends State<PrayerCommitmentScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 0: الكل (نظرة شاملة), 1: الفرائض الخمس, 2: السنن والنوافل
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        _selectedMonth = next;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  static const _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  static const _englishMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _arabicWeekdays = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];

  static const _prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  static const Map<String, (String ar, String en, IconData icon, Color color)> _prayerMeta = {
    'fajr': ('الفجر', 'Fajr', Icons.nights_stay_rounded, Color(0xFF0F766E)),
    'dhuhr': ('الظهر', 'Dhuhr', Icons.light_mode_rounded, Color(0xFFD97706)),
    'asr': ('العصر', 'Asr', Icons.wb_twilight_rounded, Color(0xFFEA580C)),
    'maghrib': ('المغرب', 'Maghrib', Icons.bedtime_rounded, Color(0xFF4F46E5)),
      'isha': ('العشاء', 'Isha', Icons.dark_mode_rounded, Color(0xFF2563EB)),
    };

    static const Map<String, IconData> _nawafilIcons = {
      'sunnah_fajr': LucideIcons.sunrise,
      'duha': LucideIcons.sun,
      'sunnah_dhuhr_before': LucideIcons.sunMedium,
      'sunnah_dhuhr_after': LucideIcons.sunDim,
      'sunnah_asr': LucideIcons.cloudSun,
      'sunnah_maghrib': LucideIcons.sunset,
      'sunnah_isha': LucideIcons.moon,
      'qiyam_witr': LucideIcons.moonStar,
    };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    final monthName = isAr
        ? _arabicMonths[_selectedMonth.month - 1]
        : _englishMonths[_selectedMonth.month - 1];
    final yearStr = _selectedMonth.year.toString();

    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Monthly tasks for prayers & nawafil
    final monthlyPrayerTasks = appState.getMonthlyPrayerTasks(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final monthlyNawafilTasks = appState.getMonthlyNawafilTasks(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // ── Calculate Faridah stats ──
    int totalPrayers = 0;
    int fullDaysCount = 0;
    final Map<String, int> prayerCounts = {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };

    monthlyPrayerTasks.forEach((_, set) {
      totalPrayers += set.length;
      if (set.length == 5) fullDaysCount++;
      for (final p in set) {
        if (prayerCounts.containsKey(p)) {
          prayerCounts[p] = (prayerCounts[p] ?? 0) + 1;
        }
      }
    });

    final activeDaysCount = isCurrentMonth ? now.day : daysInMonth;
    final maxPossiblePrayers = activeDaysCount * 5;
    final faridahPercentage = maxPossiblePrayers > 0
        ? ((totalPrayers * 100) / maxPossiblePrayers).clamp(0, 100).round()
        : 0;

    // ── Calculate Nawafil stats ──
    int totalNawafilDone = 0;
    final Map<String, int> nawafilCounts = {};
    for (final item in allNawafilList) {
      nawafilCounts[item.keyId] = 0;
    }

    monthlyNawafilTasks.forEach((_, set) {
      totalNawafilDone += set.length;
      for (final key in set) {
        if (nawafilCounts.containsKey(key)) {
          nawafilCounts[key] = (nawafilCounts[key] ?? 0) + 1;
        }
      }
    });

    // Top Faridah prayer
    String topPrayerName = isAr ? 'الفجر' : 'Fajr';
    int maxPrayerCount = -1;
    prayerCounts.forEach((k, v) {
      if (v > maxPrayerCount) {
        maxPrayerCount = v;
        topPrayerName = isAr ? _prayerMeta[k]!.$1 : _prayerMeta[k]!.$2;
      }
    });

    const emerald = Color(0xFF0F766E);
    const goldAccent = Color(0xFFD97706);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ──── Hero Header ────
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Back button above the card (outside) to free space for texts
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? DhikrColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: emerald.withValues(
                                            alpha: dark ? 0.35 : 0.18),
                                      ),
                                    ),
                                    child: Icon(
                                      isAr
                                          ? Icons.arrow_back_ios_new_rounded
                                          : Icons.arrow_back_ios_new_rounded,
                                      color: dark
                                          ? DhikrColors.sage
                                          : emerald,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          Container(
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dark
                                ? [const Color(0xFF0D2820), const Color(0xFF051510), const Color(0xFF0A1F18)]
                                : [DhikrColors.forest, DhikrColors.forestDeep, const Color(0xFF0A2018)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: DhikrColors.forest.withValues(alpha: dark ? 0.4 : 0.35),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Title row (no back button inside — full space for texts)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAr ? 'سجل الصلوات والسنن' : 'Prayer & Sunan Record',
                                        style: const TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isAr
                                            ? 'متابعة الفرائض والسنن في $monthName $yearStr'
                                            : 'Obligatory & Sunan in $monthName $yearStr',
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 11.5,
                                          height: 1.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Nawafil Guide button
                                GestureDetector(
                                  onTap: () => NawafilTrackerSheet.show(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.sparkles, color: Color(0xFFFDE68A), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAr ? 'دليل السنن' : 'Guide',
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Streak Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: goldAccent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: goldAccent.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: goldAccent, size: 15),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${appState.streakCount}',
                                        style: const TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: goldAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Monthly progress bar — the headline number, kept
                            // compact so the daily action stays above the fold.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$faridahPercentage%',
                                  style: const TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 30,
                                    height: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    isAr
                                        ? 'التزامك بالفرائض • $totalPrayers من $maxPossiblePrayers'
                                        : 'Obligatory commitment • $totalPrayers of $maxPossiblePrayers',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11.5,
                                      color: Colors.white.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: faridahPercentage / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  faridahPercentage >= 80
                                      ? goldAccent
                                      : faridahPercentage >= 50
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF60A5FA),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _buildHeroChip(
                                  icon: Icons.check_circle_rounded,
                                  value: '$totalPrayers',
                                  label: isAr ? 'فروض' : 'Prayers',
                                  color: const Color(0xFF34D399),
                                ),
                                const SizedBox(width: 8),
                                _buildHeroChip(
                                  icon: LucideIcons.sparkles,
                                  value: '$totalNawafilDone',
                                  label: isAr ? 'سنن ونوافل' : 'Sunan',
                                  color: const Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 8),
                                _buildHeroChip(
                                  icon: Icons.stars_rounded,
                                  value: '$fullDaysCount',
                                  label: isAr ? 'أيام تامة' : 'Full days',
                                  color: const Color(0xFF818CF8),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                        ],
                      ),
                    ),

                    // ──── Scrollable Content ────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── 1. التنفيذ اليومي أولاً: أهم إجراء في الشاشة ──
                          _buildTodayQuickTracker(
                            context: context,
                            appState: appState,
                            isAr: isAr,
                            dark: dark,
                          ),
                          const SizedBox(height: 22),

                          // ── 2. ملخّص الشهر: نفس الأرقام بلوحة واحدة بدل شبكة ──
                          _buildSectionHeader(
                            title: isAr
                                ? 'ملخّص $monthName'
                                : '$monthName Summary',
                            dark: dark,
                            icon: Icons.insights_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildMonthNavigator(
                            isAr: isAr,
                            dark: dark,
                            isCurrentMonth: isCurrentMonth,
                          ),
                          const SizedBox(height: 14),
                          _buildMonthSummary(
                            isAr: isAr,
                            dark: dark,
                            totalPrayers: totalPrayers,
                            totalNawafilDone: totalNawafilDone,
                            faridahPercentage: faridahPercentage,
                            fullDaysCount: fullDaysCount,
                            maxPossiblePrayers: maxPossiblePrayers,
                            topPrayerName: topPrayerName,
                            activeDaysCount: activeDaysCount,
                          ),
                          const SizedBox(height: 22),

                          // ── 3. تصفية العرض (الفرائض / السنن) ──
                          _buildTabSelector(isAr: isAr, dark: dark),
                          const SizedBox(height: 18),

                          // ── 4. التقويم: الخريطة البصرية للشهر ──
                          _buildSectionHeader(
                            title: isAr ? 'تقويم النشاط اليومي' : 'Daily Activity Calendar',
                            dark: dark,
                            icon: Icons.calendar_month_rounded,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'اضغط على أي يوم لعرض أو تعديل صلواته وسننه'
                                : 'Tap any day to view or log prayers & sunan',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCalendarGrid(
                            context: context,
                            appState: appState,
                            year: _selectedMonth.year,
                            month: _selectedMonth.month,
                            daysInMonth: daysInMonth,
                            monthlyPrayerTasks: monthlyPrayerTasks,
                            monthlyNawafilTasks: monthlyNawafilTasks,
                            isCurrentMonth: isCurrentMonth,
                            currentDay: now.day,
                            isAr: isAr,
                            dark: dark,
                          ),
                          const SizedBox(height: 24),

                          // ── 5. تفصيل الأداء (يتبدّل حسب التبويب المختار) ──
                          if (_selectedTab == 0 || _selectedTab == 1) ...[
                            _buildSectionHeader(
                              title: isAr ? 'أداء الصلوات المفروضة هذا الشهر' : '5 Faridah Breakdown',
                              dark: dark,
                              icon: Icons.bar_chart_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildFaridahBreakdown(
                              context: context,
                              prayerCounts: prayerCounts,
                              activeDaysCount: activeDaysCount,
                              isAr: isAr,
                              dark: dark,
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (_selectedTab == 0 || _selectedTab == 2) ...[
                            _buildSectionHeader(
                              title: isAr ? 'أداء السنن الرواتب والنوافل هذا الشهر' : 'Nawafil & Sunan Breakdown',
                              dark: dark,
                              icon: LucideIcons.sparkles,
                            ),
                            const SizedBox(height: 12),
                            _buildNawafilBreakdown(
                              context: context,
                              nawafilCounts: nawafilCounts,
                              activeDaysCount: activeDaysCount,
                              isAr: isAr,
                              dark: dark,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── 6. التحفيز في النهاية ──
                          _buildMotivationalCard(isAr: isAr, dark: dark),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TODAY QUICK TRACKER (تسجيل صلوات وسنن اليوم فوراً)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayQuickTracker({
    required BuildContext context,
    required AppState appState,
    required bool isAr,
    required bool dark,
  }) {
    final now = DateTime.now();
    final todayWeekday = isAr
        ? _arabicWeekdays[now.weekday - 1]
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final todayDateStr = isAr
        ? '$todayWeekday، ${now.day} ${_arabicMonths[now.month - 1]}'
        : '$todayWeekday, ${now.day} ${_englishMonths[now.month - 1]}';

    final completedFaridahCount = appState.completedPrayerTasksCount;
    final completedNawafilCount = appState.completedNawafilTasksCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.35 : 0.18),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF0F766E)).withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.checkCheck, color: Color(0xFF0F766E), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تسجيل صلوات اليوم' : 'Today\'s Prayer Tracker',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                    Text(
                      todayDateStr,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11.5,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedFaridahCount/5 ${isAr ? "فروض" : "faridah"} • $completedNawafilCount ${isAr ? "سنن" : "sunan"}',
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtitle Faridah
          Text(
            isAr ? 'الفرائض الخمس:' : 'Obligatory Prayers:',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
          const SizedBox(height: 10),

          // 5 Faridah quick buttons
          Row(
            children: _prayerKeys.map((key) {
              final meta = _prayerMeta[key]!;
              final isDone = appState.isPrayerTaskCompleted(key);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    appState.togglePrayerTask(key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isDone
                          ? LinearGradient(
                              colors: [meta.$4, meta.$4.withValues(alpha: 0.7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isDone ? null : (dark ? const Color(0xFF1A2520) : const Color(0xFFF3F7F5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone
                            ? meta.$4.withValues(alpha: 0.8)
                            : (dark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                        width: isDone ? 1.5 : 1,
                      ),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: meta.$4.withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) => ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                          child: Icon(
                            isDone ? Icons.check_circle_rounded : meta.$3,
                            key: ValueKey(isDone),
                            size: 20,
                            color: isDone
                                ? Colors.white
                                : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isAr ? meta.$1 : meta.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 11,
                            color: isDone
                                ? Colors.white
                                : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Subtitle Sunan & Nawafil
          Row(
            children: [
              Text(
                isAr ? 'السنن الرواتب والنوافل:' : 'Sunan & Nawafil:',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: dark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => NawafilTrackerSheet.show(context),
                child: Row(
                  children: [
                    Text(
                      isAr ? 'تفاصيل السنن' : 'Details',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nawafil mini-cards grid (3 columns)
          for (var rowStart = 0;
              rowStart < allNawafilList.length;
              rowStart += 3)
            Padding(
              padding: EdgeInsets.only(
                bottom: rowStart + 3 < allNawafilList.length ? 8 : 0,
              ),
              // IntrinsicHeight يقيّد ارتفاع الصف (stretch مع قائمة غير محدودة
              // الارتفاع بيمدد الأبناء للانهاية ويفرّغ ما بعدها في release)
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < 3; col++)
                      if (rowStart + col < allNawafilList.length)
                        Expanded(
                          child: _buildNawafilMiniCard(
                            item: allNawafilList[rowStart + col],
                            appState: appState,
                            isAr: isAr,
                            dark: dark,
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAWAFIL MINI-CARD (كرت مصغّر للسنن — 3 أعمدة)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNawafilMiniCard({
    required NafilaItem item,
    required AppState appState,
    required bool isAr,
    required bool dark,
  }) {
    final isDone = appState.isNawafilTaskCompleted(item.keyId);
    final icon = _nawafilIcons[item.keyId] ?? LucideIcons.sparkles;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        appState.toggleNawafilTask(item.keyId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          gradient: isDone
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F766E), Color(0xFF0B5F59)],
                )
              : null,
          color: isDone
              ? null
              : (dark ? const Color(0xFF1B2421) : const Color(0xFFF7FAF8)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? const Color(0xFF0F766E)
                : (dark ? Colors.white12 : Colors.black12),
            width: isDone ? 1.3 : 1,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : icon,
              size: 18,
              color: isDone
                  ? const Color(0xFFFDE68A)
                  : (dark ? DhikrColors.darkMuted : Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              isAr ? item.titleAr : item.titleEn,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10.5,
                height: 1.2,
                fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                color: isDone
                    ? Colors.white
                    : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB SELECTOR (نظرة شاملة | الفرائض | السنن)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabSelector({required bool isAr, required bool dark}) {
    final tabs = [
      isAr ? 'نظرة شاملة' : 'Overview',
      isAr ? 'الفرائض الخمس' : 'Faridah',
      isAr ? 'السنن والنوافل' : 'Sunan & Nawafil',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14201C) : const Color(0xFFE9F1EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (dark ? const Color(0xFF0F766E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[idx],
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (dark ? Colors.white : const Color(0xFF0F766E))
                          : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MONTH NAVIGATOR (اختيار الشهر)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMonthNavigator({
    required bool isAr,
    required bool dark,
    required bool isCurrentMonth,
  }) {
    const emerald = Color(0xFF0F766E);
    const goldAccent = Color(0xFFD97706);
    final monthName = isAr
        ? _arabicMonths[_selectedMonth.month - 1]
        : _englishMonths[_selectedMonth.month - 1];

    Widget arrow({
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.transparent
                  : emerald.withValues(alpha: dark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: onTap == null
                  ? (dark ? Colors.white24 : Colors.black26)
                  : (dark ? DhikrColors.sage : emerald),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF1A2E26), const Color(0xFF0D1F18)]
              : [const Color(0xFFF0FDF9), const Color(0xFFECFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emerald.withValues(alpha: dark ? 0.3 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: emerald.withValues(alpha: dark ? 0.15 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          arrow(icon: Icons.chevron_left_rounded, onTap: _previousMonth),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$monthName ${_selectedMonth.year}',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
              if (isCurrentMonth) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAr ? 'الحالي' : 'Current',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: goldAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          arrow(
            icon: Icons.chevron_right_rounded,
            onTap: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MONTH SUMMARY (لوحة أرقام الشهر في صف واحد)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMonthSummary({
    required bool isAr,
    required bool dark,
    required int totalPrayers,
    required int totalNawafilDone,
    required int faridahPercentage,
    required int fullDaysCount,
    required int maxPossiblePrayers,
    required int activeDaysCount,
    required String topPrayerName,
  }) {
    const emerald = Color(0xFF0F766E);
    final nawafilTarget = activeDaysCount * allNawafilList.length;

    Widget cell({
      required IconData icon,
      required String value,
      required String label,
      Color? color,
    }) {
      final accent = color ?? emerald;
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
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
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: emerald.withValues(alpha: dark ? 0.28 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : emerald).withValues(alpha: dark ? 0.28 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(
                icon: Icons.percent_rounded,
                value: '$faridahPercentage%',
                label: isAr ? 'التزام الفرائض' : 'Commitment',
                color: faridahPercentage >= 80
                    ? const Color(0xFFD97706)
                    : emerald,
              ),
              cell(
                icon: Icons.check_circle_rounded,
                value: '$totalPrayers/$maxPossiblePrayers',
                label: isAr ? 'فروض مؤداة' : 'Prayers done',
              ),
              cell(
                icon: LucideIcons.sparkles,
                value: '$totalNawafilDone/$nawafilTarget',
                label: isAr ? 'سنن ونوافل' : 'Sunan done',
                color: const Color(0xFFD97706),
              ),
              cell(
                icon: Icons.stars_rounded,
                value: '$fullDaysCount',
                label: isAr ? 'أيام تامة' : 'Full days',
                color: const Color(0xFF6366F1),
              ),
            ],
          ),
          if (totalPrayers > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: emerald.withValues(alpha: dark ? 0.16 : 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mosque_rounded, size: 15, color: emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'أكثر فريضة التزمت بها: $topPrayerName'
                          : 'Most consistent prayer: $topPrayerName',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FARIDAH BREAKDOWN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFaridahBreakdown({
    required BuildContext context,
    required Map<String, int> prayerCounts,
    required int activeDaysCount,
    required bool isAr,
    required bool dark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _prayerKeys.map((key) {
          final meta = _prayerMeta[key]!;
          final count = prayerCounts[key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProgressBar(
              context: context,
              name: isAr ? meta.$1 : meta.$2,
              icon: meta.$3,
              count: count,
              max: activeDaysCount,
              color: meta.$4,
              dark: dark,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAWAFIL BREAKDOWN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNawafilBreakdown({
    required BuildContext context,
    required Map<String, int> nawafilCounts,
    required int activeDaysCount,
    required bool isAr,
    required bool dark,
  }) {
    const gold = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: gold.withValues(alpha: dark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: allNawafilList.map((item) {
          final count = nawafilCounts[item.keyId] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProgressBar(
              context: context,
              name: isAr ? item.titleAr : item.titleEn,
              icon: item.isConfirmedSunnah ? Icons.star_rounded : Icons.flare_rounded,
              count: count,
              max: activeDaysCount,
              color: item.isConfirmedSunnah ? const Color(0xFF0F766E) : const Color(0xFFD97706),
              dark: dark,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALENDAR GRID WITH DUAL INDICATORS & TAP MODAL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarGrid({
    required BuildContext context,
    required AppState appState,
    required int year,
    required int month,
    required int daysInMonth,
    required Map<int, Set<String>> monthlyPrayerTasks,
    required Map<int, Set<String>> monthlyNawafilTasks,
    required bool isCurrentMonth,
    required int currentDay,
    required bool isAr,
    required bool dark,
  }) {
    final weekdays = isAr
        ? ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة']
        : ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    final firstDate = DateTime(year, month, 1);
    final satOffset = (firstDate.weekday + 1) % 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: weekdays.map((d) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      d,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: isAr ? 10.5 : 11,
                        fontWeight: FontWeight.w800,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Calendar Grid Cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: satOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (ctx, i) {
              if (i < satOffset) {
                return const SizedBox.shrink();
              }
              final day = i - satOffset + 1;
              final prayerTasks = monthlyPrayerTasks[day] ?? {};
              final nawafilTasks = monthlyNawafilTasks[day] ?? {};
              final faridahCount = prayerTasks.length;
              final nawafilCount = nawafilTasks.length;
              final isToday = isCurrentMonth && day == currentDay;
              final isFuture = isCurrentMonth && day > currentDay;

              Color cellBg;
              Color borderColor;
              Color textColor;
              List<Color>? cellGradient;

              if (faridahCount == 5) {
                cellGradient = dark
                    ? [const Color(0xFF0F766E), const Color(0xFF0A5C4F)]
                    : [const Color(0xFF0F766E), const Color(0xFF0D9488)];
                cellBg = const Color(0xFF0F766E);
                borderColor = const Color(0xFF0F766E);
                textColor = Colors.white;
              } else if (faridahCount > 0) {
                cellBg = dark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9);
                borderColor = const Color(0xFF0F766E).withValues(alpha: 0.4);
                textColor = dark ? Colors.white : const Color(0xFF0F766E);
              } else if (isToday) {
                cellGradient = dark
                    ? [const Color(0xFF38230D), const Color(0xFF4A2E10)]
                    : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)];
                cellBg = const Color(0xFFFEF3C7);
                borderColor = const Color(0xFFD97706);
                textColor = dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
              } else {
                cellBg = dark ? const Color(0xFF161D1A) : const Color(0xFFF7FAF8);
                borderColor = (dark ? Colors.white : Colors.black).withValues(alpha: 0.05);
                textColor = isFuture
                    ? (dark ? Colors.white24 : Colors.black26)
                    : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft);
              }

              final dateOfCell = DateTime(year, month, day);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        _showDayDetailModal(
                          context: context,
                          appState: appState,
                          date: dateOfCell,
                          isAr: isAr,
                          dark: dark,
                        );
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: cellGradient == null ? cellBg : null,
                    gradient: cellGradient != null
                        ? LinearGradient(
                            colors: cellGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: isToday ? 2.0 : 1.2,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: borderColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : faridahCount == 5
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12.5,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (!isFuture) ...[
                        const SizedBox(height: 2),
                        // Dots row for Faridah
                        if (faridahCount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              faridahCount.clamp(1, 5),
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.6),
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: faridahCount == 5 ? const Color(0xFFFBBF24) : textColor,
                                ),
                              ),
                            ),
                          ),
                        // Small gold star/indicator if Nawafil were performed on this day
                        if (nawafilCount > 0) ...[
                          const SizedBox(height: 1.5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+$nawafilCount',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DAY DETAIL MODAL (عرض وتعديل صلوات وسنن اليوم المحدد)
  // ══════════════════════════════════════════════════════════════════════════
  void _showDayDetailModal({
    required BuildContext context,
    required AppState appState,
    required DateTime date,
    required bool isAr,
    required bool dark,
  }) {
    final dateIso =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final weekdayName = isAr
        ? _arabicWeekdays[date.weekday - 1]
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
    final dateStr = isAr
        ? '$weekdayName، ${date.day} ${_arabicMonths[date.month - 1]} ${date.year}'
        : '$weekdayName, ${date.day} ${_englishMonths[date.month - 1]} ${date.year}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final prayerTasks = appState.getPrayerTasksForDate(dateIso);
            final nawafilTasks = appState.getNawafilTasksForDate(dateIso);

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: dark ? DhikrColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.25 : 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF0F766E), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.5,
                                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                  ),
                                ),
                                Text(
                                  isAr ? 'تعديل أو تسجيل الصلوات المؤداة' : 'Update or log completed prayers',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 12,
                                    color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Scrollable Checklist
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          // ── Faridah Section ──
                          Row(
                            children: [
                              Text(
                                isAr ? 'الصلوات المفروضة' : 'Obligatory Prayers',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: dark ? DhikrColors.sage : DhikrColors.forest,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${prayerTasks.length}/5',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          ..._prayerKeys.map((key) {
                            final meta = _prayerMeta[key]!;
                            final isDone = prayerTasks.contains(key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    await appState.togglePrayerTaskForDate(dateIso, key);
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? const Color(0xFF0F766E).withValues(alpha: dark ? 0.2 : 0.08)
                                          : (dark ? const Color(0xFF1E2623) : const Color(0xFFF7FAF8)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDone
                                            ? const Color(0xFF0F766E).withValues(alpha: 0.5)
                                            : (dark ? Colors.white10 : Colors.black12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                          color: isDone ? const Color(0xFF0F766E) : Colors.grey,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(meta.$3, size: 18, color: meta.$4),
                                        const SizedBox(width: 10),
                                        Text(
                                          isAr ? meta.$1 : meta.$2,
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                                            fontSize: 14,
                                            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          isDone ? (isAr ? 'تمت' : 'Done') : (isAr ? 'لم تؤد' : 'Not done'),
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDone ? const Color(0xFF0F766E) : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 18),

                          // ── Nawafil Section ──
                          Row(
                            children: [
                              Text(
                                isAr ? 'السنن الرواتب والنوافل' : 'Sunan & Nawafil',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: dark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${nawafilTasks.length} ${isAr ? "نافلة" : "done"}',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          ...allNawafilList.map((item) {
                            final isDone = nawafilTasks.contains(item.keyId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    await appState.toggleNawafilTaskForDate(dateIso, item.keyId);
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? const Color(0xFFD97706).withValues(alpha: dark ? 0.2 : 0.08)
                                          : (dark ? const Color(0xFF1E2623) : const Color(0xFFF7FAF8)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDone
                                            ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                            : (dark ? Colors.white10 : Colors.black12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                          color: isDone ? const Color(0xFFD97706) : Colors.grey,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isAr ? item.titleAr : item.titleEn,
                                                style: TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
                                                  fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                                                  fontSize: 13.5,
                                                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                                ),
                                              ),
                                              Text(
                                                isAr ? item.rakahsAr : item.rakahsEn,
                                                style: TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
                                                  fontSize: 11,
                                                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (item.isConfirmedSunnah)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isAr ? 'راتبة' : 'Ratibah',
                                              style: const TextStyle(
                                                fontFamily: DhikrTheme.arabicFont,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════
  /// Compact monthly-stat chip used inside the hero card.
  ///
  /// Three of these replace the old vertical stat column + the duplicated
  /// metric-card grid: one number, one label, no repetition.
  Widget _buildHeroChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool dark,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required BuildContext context,
    required String name,
    required IconData icon,
    required int count,
    required int max,
    required Color color,
    required bool dark,
  }) {
    final double pct = max > 0 ? (count / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$count / $max',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: dark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: constraints.maxWidth * pct,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMotivationalCard({required bool isAr, required bool dark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF1A2E26), const Color(0xFF0D1F18), const Color(0xFF0A1A14)]
              : [const Color(0xFFF0FDF9), const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.35 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.2 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.25 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 26,
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.7 : 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? '«مَنْ صَلَّى فِي يَوْمٍ وَلَيْلَةٍ ثِنْتَيْ عَشْرَةَ رَكْعَةً بُنِيَ لَهُ بَيْتٌ فِي الْجَنَّةِ»'
                : '“Whoever prays twelve rak\'ahs during the day and night, a house will be built for him in Paradise.”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              height: 1.65,
              color: dark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isAr ? '— صحيح مسلم (فضل السنن الرواتب)' : '— Sahih Muslim (Virtue of Sunan Rawatib)',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
