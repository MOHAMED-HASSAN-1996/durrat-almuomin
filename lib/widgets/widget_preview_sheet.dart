import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/home_widget_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'calendar_widget.dart';
import 'app_toast.dart';

/// نافذة فخمة لمعاينة وتثبيت ويدجيت الشاشة الرئيسية
class WidgetPreviewSheet extends StatefulWidget {
  const WidgetPreviewSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WidgetPreviewSheet(),
    );
  }

  @override
  State<WidgetPreviewSheet> createState() => _WidgetPreviewSheetState();
}

class _WidgetPreviewSheetState extends State<WidgetPreviewSheet> {
  int _selectedWidgetIndex = 0; // 0: Prayer & Calligraphy, 1: Prayer Tracker

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);
    final now = DateTime.now();
    final hijriStr = HijriDate.format(now, true);
    final gregorianMonth = HijriDate.gregorianMonthsAr[now.month - 1];
    final gregStr = '${now.day} $gregorianMonth';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B17) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: DhikrColors.forest.withValues(alpha: isDark ? 0.25 : 0.12),
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: DhikrColors.forest.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.layoutGrid,
                  color: DhikrColors.forest,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أدوات الشاشة الرئيسية (Widgets)',
                      style: TextStyle(
                        fontFamily: DhikrTheme.titleFont,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : DhikrColors.charcoal,
                      ),
                    ),
                    Text(
                      'اختر مظهر الأداة وثبتها على شاشة هاتفك الرئيسية',
                      style: TextStyle(
                        fontFamily: DhikrTheme.bodyFont,
                        fontSize: 12,
                        color: isDark ? DhikrColors.darkMuted : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Widget Selector Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2420) : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'ويدجيت المواقيت والثلث',
                    icon: LucideIcons.moon,
                    isSelected: _selectedWidgetIndex == 0,
                    onTap: () => setState(() => _selectedWidgetIndex = 0),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    title: 'ويدجيت متابعة الصلوات 🔥',
                    icon: LucideIcons.flame,
                    isSelected: _selectedWidgetIndex == 1,
                    onTap: () => setState(() => _selectedWidgetIndex = 1),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Preview Area
          _buildLivePreviewCard(appState, hijriStr, gregStr, isDark),
          const SizedBox(height: 22),

          // Pin Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DhikrColors.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final isTracker = _selectedWidgetIndex == 1;
                final success = await HomeWidgetService.instance.pinWidget(isTracker: isTracker);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(context, 
                  SnackBar(
                    backgroundColor: DhikrColors.forest,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            success
                                ? 'تم إرسال طلب تثبيت الأداة إلى الشاشة الرئيسية بنجاح ✨'
                                : 'يرجى إضافة الأداة بالسحب والإفلات من قائمة الأدوات بهاتفك 📱',
                            style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.pin, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'تثبيت الأداة على الشاشة الرئيسية',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.bodyFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '💡 يمكنك أيضاً الضغط مطولاً على أي مساحة فارغة في الشاشة الرئيسية واختيار «درة المؤمن»',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.bodyFont,
              fontSize: 11,
              color: isDark ? DhikrColors.darkMuted.withValues(alpha: 0.7) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? DhikrColors.forest : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.bodyFont,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : DhikrColors.forest)
                      : (isDark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(AppState appState, String hijriStr, String gregStr, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        // Modern frosted translucent glass card to demonstrate the transparent widget
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1.2,
        ),
      ),
      child: _selectedWidgetIndex == 0
          ? _buildPrayerCalligraphyPreview(hijriStr, gregStr, isDark)
          : _buildPrayerTrackerPreview(appState),
    );
  }

  // Preview 1: Prayer times with Thuluth calligraphy, White Clock, Hijri above, Gregorian below
  Widget _buildPrayerCalligraphyPreview(String hijriStr, String gregStr, bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '${displayHour.toString().padLeft(2, '0')}:$minute $period';
    
    // Day calligraphy map with Kashida (كشيدة بخط الثلث)
    final dayNames = {
      DateTime.saturday: 'السَّــــبْت',
      DateTime.sunday: 'الأَحَــــد',
      DateTime.monday: 'الإِثْنَــــيْن',
      DateTime.tuesday: 'الثُّـلَاثَــــاء',
      DateTime.wednesday: 'الأَرْبِعَــــاء',
      DateTime.thursday: 'الخَمِيــــس',
      DateTime.friday: 'الجُـمُعَــــة',
    };
    final dayCalligraphy = dayNames[now.weekday] ?? 'الأَحَــــد';
    final gregorianMonth = HijriDate.gregorianMonthsAr[now.month - 1];
    final cleanGreg = '${now.day} $gregorianMonth ${now.year} م';

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    final combinedDate = '$cleanGreg . $hijriStr';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Side: Thuluth Day Name with Kashida (اسم اليوم كشيدة على اليسار مصغر 8px)
            Text(
              dayCalligraphy,
              style: TextStyle(
                fontFamily: DhikrTheme.thuluthFont,
                fontSize: 36,
                color: textColor,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: isDark ? Colors.black87 : Colors.black26,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            // Right Side: Clock (top) -> Combined Date (bottom) (الساعة والتاريخ على اليمين)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clock / Time in WHITE (Enlarged)
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: DhikrTheme.bodyFont,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Combined Date: Gregorian . Hijri
                Text(
                  combinedDate,
                  style: TextStyle(
                    fontFamily: DhikrTheme.bodyFont,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Divider
        Divider(
          color: isDark ? Colors.white12 : Colors.black12,
          height: 1,
        ),
        const SizedBox(height: 12),
        // 6 Prayers Row in Somar Sans
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _PrayerCol(name: 'الفجر', time: '5:10', isNext: false),
            _PrayerCol(name: 'الشروق', time: '6:38', isNext: false),
            _PrayerCol(name: 'الظهر', time: '12:51', isNext: false),
            _PrayerCol(name: 'العصر', time: '4:23', isNext: false),
            _PrayerCol(name: 'المغرب', time: '7:04', isNext: true),
            _PrayerCol(name: 'العشاء', time: '8:23', isNext: false),
          ],
        ),
      ],
    );
  }

  // Preview 2: Prayer Tracker with Streaks & Checkmarks
  Widget _buildPrayerTrackerPreview(AppState appState) {
    final streak = appState.streakCount.clamp(1, 999);
    final completedCount = appState.todayPrayerTasks.length.clamp(0, 5);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'متابعة صلوات اليوم',
              style: TextStyle(
                fontFamily: DhikrTheme.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '🔥 $streak أيام',
                style: const TextStyle(
                  fontFamily: DhikrTheme.bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 5 Prayers Checkmarks
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TrackerCol(name: 'الفجر', isDone: appState.todayPrayerTasks.contains('fajr'), time: '5:10'),
            _TrackerCol(name: 'الظهر', isDone: appState.todayPrayerTasks.contains('dhuhr'), time: '12:51'),
            _TrackerCol(name: 'العصر', isDone: appState.todayPrayerTasks.contains('asr'), time: '4:23'),
            _TrackerCol(name: 'المغرب', isDone: appState.todayPrayerTasks.contains('maghrib'), time: '7:04'),
            _TrackerCol(name: 'العشاء', isDone: appState.todayPrayerTasks.contains('isha'), time: '8:23'),
          ],
        ),
        const SizedBox(height: 10),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completedCount / 5,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          completedCount == 5
              ? 'بارك الله فيك! أتممت جميع صلوات اليوم 🌟'
              : 'أديت $completedCount من 5 صلوات • واصل التزامك المبارك',
          style: TextStyle(
            fontFamily: DhikrTheme.bodyFont,
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _PrayerCol extends StatelessWidget {
  final String name;
  final String time;
  final bool isNext;

  const _PrayerCol({required this.name, required this.time, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final color = isNext ? const Color(0xFF4ADE80) : Colors.white;
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontFamily: DhikrTheme.bodyFont,
            fontSize: 11,
            color: color,
            fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontFamily: DhikrTheme.bodyFont,
            fontSize: 11.5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrackerCol extends StatelessWidget {
  final String name;
  final bool isDone;
  final String time;

  const _TrackerCol({required this.name, required this.isDone, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontFamily: DhikrTheme.bodyFont,
            fontSize: 11,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isDone ? '✔' : time,
          style: TextStyle(
            fontFamily: DhikrTheme.bodyFont,
            fontSize: isDone ? 13 : 11,
            fontWeight: FontWeight.w800,
            color: isDone ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
