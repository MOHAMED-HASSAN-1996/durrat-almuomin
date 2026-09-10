import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// شاشة تحليلات وسجل الالتزام بالصلوات الخمس والنشاط الشهري
class PrayerCommitmentScreen extends StatefulWidget {
  const PrayerCommitmentScreen({super.key});

  @override
  State<PrayerCommitmentScreen> createState() => _PrayerCommitmentScreenState();
}

class _PrayerCommitmentScreenState extends State<PrayerCommitmentScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedMonth;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
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
    final monthlyTasks = appState.getMonthlyPrayerTasks(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    int totalPrayers = 0;
    int fullDaysCount = 0;
    final Map<String, int> prayerCounts = {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };

    monthlyTasks.forEach((_, set) {
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
    final percentage = maxPossiblePrayers > 0
        ? ((totalPrayers * 100) / maxPossiblePrayers).clamp(0, 100).round()
        : 0;

    String topPrayerName = isAr ? 'الفجر' : 'Fajr';
    int maxCount = -1;
    final prayerNames = {
      'fajr': isAr ? 'الفجر' : 'Fajr',
      'dhuhr': isAr ? 'الظهر' : 'Dhuhr',
      'asr': isAr ? 'العصر' : 'Asr',
      'maghrib': isAr ? 'المغرب' : 'Maghrib',
      'isha': isAr ? 'العشاء' : 'Isha',
    };
    prayerCounts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        topPrayerName = prayerNames[k] ?? k;
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
                  slivers: [
                    // ──── Sliver App Bar with Hero Header ────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dark
                                ? [const Color(0xFF0D2820), const Color(0xFF051510), const Color(0xFF0A1F18)]
                                : [DhikrColors.forest, DhikrColors.forestDeep, const Color(0xFF0A2018)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(28),
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
                            // Back button + Title row
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    isAr ? 'سجل الالتزام بالصلاة' : 'Prayer Commitment',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: goldAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: goldAccent.withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: goldAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${appState.streakCount}',
                                        style: const TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: goldAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Hero Stats Row
                            Row(
                              children: [
                                // Radial Progress Circle
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: CircularProgressIndicator(
                                          value: percentage / 100,
                                          strokeWidth: 9,
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            percentage >= 80
                                                ? goldAccent
                                                : percentage >= 50
                                                    ? const Color(0xFF34D399)
                                                    : const Color(0xFF60A5FA),
                                          ),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$percentage%',
                                            style: const TextStyle(
                                              fontFamily: DhikrTheme.arabicFont,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 26,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            isAr ? 'التزام' : 'rate',
                                            style: TextStyle(
                                              fontFamily: DhikrTheme.arabicFont,
                                              fontSize: 11,
                                              color: Colors.white.withValues(alpha: 0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Vertical Stats
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHeroStat(
                                        icon: Icons.check_circle_rounded,
                                        value: '$totalPrayers',
                                        label: isAr ? 'صلاة مؤداة' : 'prayers done',
                                        color: const Color(0xFF34D399),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildHeroStat(
                                        icon: Icons.stars_rounded,
                                        value: '$fullDaysCount',
                                        label: isAr ? 'يوم مكتمل (۵/۵)' : 'full days',
                                        color: goldAccent,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildHeroStat(
                                        icon: Icons.mosque_rounded,
                                        value: topPrayerName,
                                        label: isAr ? 'أكثر صلاة تلتزم بها' : 'top prayer',
                                        color: const Color(0xFF818CF8),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ──── Scrollable Body ────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                    // ──── Month Navigation Bar ────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dark
                              ? [const Color(0xFF1A2E26), const Color(0xFF0D1F18)]
                              : [const Color(0xFFF0FDF9), const Color(0xFFECFDF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: emerald.withValues(alpha: dark ? 0.3 : 0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: emerald.withValues(alpha: dark ? 0.15 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _previousMonth,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: emerald.withValues(alpha: dark ? 0.2 : 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 26,
                                  color: dark ? DhikrColors.sage : emerald,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$monthName $yearStr',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                ),
                              ),
                              if (isCurrentMonth)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: goldAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAr ? 'الشهر الحالي' : 'Current Month',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: goldAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isCurrentMonth ? null : _nextMonth,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrentMonth
                                      ? Colors.transparent
                                      : emerald.withValues(alpha: dark ? 0.2 : 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 26,
                                  color: isCurrentMonth
                                      ? (dark ? Colors.white24 : Colors.black26)
                                      : (dark ? DhikrColors.sage : emerald),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ──── Streak Flame Card ────
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return ScaleTransition(
                          scale: _pulseAnimation,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dark
                                ? [const Color(0xFF2D1F0E), const Color(0xFF1A1207)]
                                : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: goldAccent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldAccent.withValues(alpha: dark ? 0.25 : 0.15),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    goldAccent.withValues(alpha: 0.4),
                                    goldAccent.withValues(alpha: 0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: goldAccent.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: goldAccent,
                                size: 38,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'سلسلة الالتزام: ${appState.streakCount} ${appState.streakCount == 1 ? "يوم" : "أيام متتالية"}'
                                        : 'Daily Streak: ${appState.streakCount} days',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: dark
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr
                                        ? '«وَأَقِمِ الصَّلَاةَ طَرَفَيِ النَّهَارِ وَزُلَفًا مِّنَ اللَّيْلِ»'
                                        : 'Consistency in 5 daily prayers brings inner peace.',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 13,
                                      height: 1.5,
                                      color: dark
                                          ? DhikrColors.darkMuted
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ──── Metric Cards Row 1 ────
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: isAr ? 'الصلوات المؤداة' : 'Completed Prayers',
                            value: '$totalPrayers',
                            unit: isAr ? 'صلاة فريضة' : 'prayers',
                            icon: Icons.check_circle_rounded,
                            accentColor: emerald,
                            dark: dark,
                            gradientColors: dark
                                ? [const Color(0xFF0D2B24), const Color(0xFF0A1F1A)]
                                : [const Color(0xFFF0FDF9), const Color(0xFFCCFBF1)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: isAr ? 'نسبة الالتزام' : 'Commitment',
                            value: '$percentage%',
                            unit: isAr ? 'من إجمالي الشهر' : 'monthly total',
                            icon: Icons.pie_chart_rounded,
                            accentColor: const Color(0xFF4F46E5),
                            dark: dark,
                            gradientColors: dark
                                ? [const Color(0xFF1E1B4B), const Color(0xFF15133A)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ──── Metric Cards Row 2 ────
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: isAr ? 'أيام مكتملة (٥/٥)' : 'Full Days (5/5)',
                            value: '$fullDaysCount',
                            unit: isAr ? 'أيام مباركة' : 'days completed',
                            icon: Icons.stars_rounded,
                            accentColor: goldAccent,
                            dark: dark,
                            gradientColors: dark
                                ? [const Color(0xFF2D1F0E), const Color(0xFF1A1207)]
                                : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: isAr ? 'أكثر صلاة حافظت عليها' : 'Top Prayer',
                            value: topPrayerName,
                            unit: maxCount > 0
                                ? (isAr ? '$maxCount مرة' : '$maxCount times')
                                : '-',
                            icon: Icons.mosque_rounded,
                            accentColor: const Color(0xFF0284C7),
                            dark: dark,
                            gradientColors: dark
                                ? [const Color(0xFF0C2940), const Color(0xFF081C2D)]
                                : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ──── Prayer Breakdown Section ────
                    _buildSectionHeader(
                      title: isAr ? 'أداء الصلوات الخمس هذا الشهر' : '5 Prayers Breakdown',
                      dark: dark,
                      icon: Icons.bar_chart_rounded,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: dark ? DhikrColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: (dark ? DhikrColors.sage : DhikrColors.forest)
                              .withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (dark ? Colors.black : Colors.grey)
                                .withValues(alpha: dark ? 0.3 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPrayerBar(
                            name: isAr ? 'صلاة الفجر' : 'Fajr',
                            icon: Icons.nights_stay_rounded,
                            count: prayerCounts['fajr'] ?? 0,
                            max: activeDaysCount,
                            color: const Color(0xFF0F766E),
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          _buildPrayerBar(
                            name: isAr ? 'صلاة الظهر' : 'Dhuhr',
                            icon: Icons.light_mode_rounded,
                            count: prayerCounts['dhuhr'] ?? 0,
                            max: activeDaysCount,
                            color: const Color(0xFFD97706),
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          _buildPrayerBar(
                            name: isAr ? 'صلاة العصر' : 'Asr',
                            icon: Icons.wb_twilight_rounded,
                            count: prayerCounts['asr'] ?? 0,
                            max: activeDaysCount,
                            color: const Color(0xFFEA580C),
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          _buildPrayerBar(
                            name: isAr ? 'صلاة المغرب' : 'Maghrib',
                            icon: Icons.bedtime_rounded,
                            count: prayerCounts['maghrib'] ?? 0,
                            max: activeDaysCount,
                            color: const Color(0xFF4F46E5),
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          _buildPrayerBar(
                            name: isAr ? 'صلاة العشاء' : 'Isha',
                            icon: Icons.dark_mode_rounded,
                            count: prayerCounts['isha'] ?? 0,
                            max: activeDaysCount,
                            color: const Color(0xFF2563EB),
                            dark: dark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ──── Calendar Section ────
                    _buildSectionHeader(
                      title: isAr ? 'تقويم التزام الشهر' : 'Monthly Activity Calendar',
                      dark: dark,
                      icon: Icons.calendar_month_rounded,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'اضغط على أي يوم للاطلاع على الصلوات المؤداة فيه'
                          : 'Tap any day to see prayers completed on that day',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMonthCalendarGrid(
                      context: context,
                      year: _selectedMonth.year,
                      month: _selectedMonth.month,
                      daysInMonth: daysInMonth,
                      monthlyTasks: monthlyTasks,
                      isCurrentMonth: isCurrentMonth,
                      currentDay: now.day,
                      isAr: isAr,
                      dark: dark,
                    ),
                    const SizedBox(height: 26),

                    // ──── Motivational Ayah ────
                    _buildMotivationalAyah(isAr: isAr, dark: dark),
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

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ],
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
            size: 18,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalAyah({required bool isAr, required bool dark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.25 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 28,
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.7 : 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isAr
                ? 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا'
                : 'Indeed, prayer has been decreed upon the believers at specified times.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.7,
              color: dark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: dark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAr ? '— سورة النساء، آية ١٠٣' : '— An-Nisa 4:103',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required bool dark,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: dark ? 0.18 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: dark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 10,
              color: dark ? DhikrColors.darkMuted.withValues(alpha: 0.7) : DhikrColors.charcoalSoft.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerBar({
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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count / $max',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * pct * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCalendarGrid({
    required BuildContext context,
    required int year,
    required int month,
    required int daysInMonth,
    required Map<int, Set<String>> monthlyTasks,
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
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(
            alpha: 0.2,
          ),
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

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: satOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (ctx, i) {
              if (i < satOffset) {
                return const SizedBox.shrink();
              }
              final day = i - satOffset + 1;
              final tasks = monthlyTasks[day] ?? {};
              final count = tasks.length;
              final isToday = isCurrentMonth && day == currentDay;
              final isFuture = isCurrentMonth && day > currentDay;

              Color cellBg;
              Color borderColor;
              Color textColor;
              List<Color>? cellGradient;

              if (count == 5) {
                cellGradient = dark
                    ? [const Color(0xFF0F766E), const Color(0xFF0A5C4F)]
                    : [const Color(0xFF0F766E), const Color(0xFF0D9488)];
                cellBg = const Color(0xFF0F766E);
                borderColor = const Color(0xFF0F766E);
                textColor = Colors.white;
              } else if (count > 0) {
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

              return Tooltip(
                message: '$day: $count / 5',
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
                        : count == 5
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
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (count > 0 && !isFuture) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            count.clamp(1, 5),
                            (idx) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0.8),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: count == 5 ? const Color(0xFFFBBF24) : textColor,
                                boxShadow: count == 5
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                                          blurRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
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
}
