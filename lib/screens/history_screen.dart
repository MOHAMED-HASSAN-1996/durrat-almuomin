import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/progress_bar.dart';

/// Simple history screen: per-day rows with morning/evening completion.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final history = context.watch<AppState>().getHistory(limit: 14);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(lang, 'history')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: history.isEmpty
                ? Center(
                    child: Text(
                      lang == AppLanguage.arabic
                          ? 'لا يوجد سجل بعد'
                          : 'No history yet.',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    itemCount: history.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      return _DayRow(
                        entry: history[i],
                        language: lang,
                        isToday: i == 0,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.entry,
    required this.language,
    required this.isToday,
  });

  final Map<String, dynamic> entry;
  final AppLanguage language;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final date = entry['date'] as String;
    final morning = (entry['morning'] as Map?) ?? const {'completed': 0, 'total': 0};
    final evening = (entry['evening'] as Map?) ?? const {'completed': 0, 'total': 0};

    final label = isToday
        ? AppStrings.t(language, 'today')
        : _formatDate(date, language);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : DhikrColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? DhikrColors.darkText.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          _CategoryLine(
            icon: '🌅',
            title: AppStrings.t(language, 'morning'),
            completed: (morning['completed'] as num?)?.toInt() ?? 0,
            total: (morning['total'] as num?)?.toInt() ?? 0,
            language: language,
          ),
          const SizedBox(height: 12),
          _CategoryLine(
            icon: '🌙',
            title: AppStrings.t(language, 'evening'),
            completed: (evening['completed'] as num?)?.toInt() ?? 0,
            total: (evening['total'] as num?)?.toInt() ?? 0,
            language: language,
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso, AppLanguage lang) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final thisDay = DateTime(y, m, d);
    if (thisDay == DateTime(now.year, now.month, now.day)) {
      return AppStrings.t(lang, 'today');
    }
    if (thisDay == yesterday) {
      return AppStrings.t(lang, 'yesterday');
    }
    return '$d/$m/$y';
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.icon,
    required this.title,
    required this.completed,
    required this.total,
    required this.language,
  });

  final String icon;
  final String title;
  final int completed;
  final int total;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isComplete = total > 0 && completed >= total;
    final percent = total == 0 ? 0 : (completed * 100 / total).round();

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ProgressBar(
            fraction: total == 0 ? 0 : completed / total,
            height: 6,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            isComplete
                ? (language == AppLanguage.arabic ? '✓' : '✓')
                : '$percent%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isComplete
                  ? (dark ? DhikrColors.sage : DhikrColors.success)
                  : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
            ),
          ),
        ),
      ],
    );
  }
}