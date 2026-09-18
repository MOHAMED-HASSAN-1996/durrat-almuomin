import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/strings.dart';
import '../services/admin_sync_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'auth_screen.dart';
import 'about_app_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_screen.dart';
import 'profile_details_screen.dart';

import 'setup_permissions_screen.dart';

/// Redesigned Settings screen — sleek, organized into grouped cards,
/// with segmented switches and premium typography.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AppBar(
              title: Text(
                AppStrings.t(lang, 'settings'),
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                // User Profile & Registration Section at the top
                _UserProfileCard(language: lang, dark: dark),
                const SizedBox(height: 20),

                // Section 1: Appearance & Language
                _SectionTitle(
                  title: isAr ? 'التفضيلات العامة' : 'General Preferences',
                  icon: LucideIcons.settings,
                  dark: dark,
                ),
                const SizedBox(height: 8),
                _GroupedCard(
                  dark: dark,
                  children: [
                    _LanguageSelectorRow(language: lang, dark: dark),
                    const _SectionDivider(),
                    _ThemeSelectorRow(language: lang, dark: dark),
                    const _SectionDivider(),
                    _AudioSwitchRow(language: lang, dark: dark),
                  ],
                ),
                const SizedBox(height: 22),

                // Section 2: Activity & Progress
                _SectionTitle(
                  title: isAr ? 'النشاط والمحتوى' : 'Activity & Content',
                  icon: LucideIcons.barChart3,
                  dark: dark,
                ),
                const SizedBox(height: 8),
                _GroupedCard(
                  dark: dark,
                  children: [
                    _SettingsNavTile(
                      icon: LucideIcons.church,
                      iconColor: const Color(0xFF0F766E),
                      title: isAr
                          ? 'سجل الالتزام بالصلاة والنشاط'
                          : 'Prayer Commitment & Analytics',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const _PrayerCommitmentAnalyticsPage(),
                          ),
                        );
                      },
                      dark: dark,
                    ),
                    const _SectionDivider(),
                    _SettingsNavTile(
                      icon: LucideIcons.refreshCw,
                      iconColor: const Color(0xFFE55353),
                      title: AppStrings.t(lang, 'reset_today'),
                      onTap: () async {
                        final confirmed = await _confirmReset(context);
                        if (confirmed == true && context.mounted) {
                          await context.read<AppState>().resetToday();
                        }
                      },
                      dark: dark,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Section 3: Engagement & Feedback
                _SectionTitle(
                  title: isAr ? 'المشاركة والتواصل' : 'Feedback & Community',
                  icon: LucideIcons.thumbsUp,
                  dark: dark,
                ),
                const SizedBox(height: 8),
                _GroupedCard(
                  dark: dark,
                  children: [
                    _SettingsNavTile(
                      icon: LucideIcons.star,
                      iconColor: const Color(0xFFFFB300),
                      title: isAr ? 'تقييم التطبيق' : 'Rate the App',
                      onTap: () => _showRateSheet(context, lang, dark),
                      dark: dark,
                    ),
                    const _SectionDivider(),
                    _SettingsNavTile(
                      icon: LucideIcons.messageCircle,
                      iconColor: dark ? DhikrColors.sage : DhikrColors.forest,
                      title: isAr ? 'إرسال ملاحظة أو اقتراح' : 'Send Feedback',
                      onTap: () => _showFeedbackSheet(context, lang, dark),
                      dark: dark,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Section 4: About & References
                _SectionTitle(
                  title: isAr ? 'عن التطبيق' : 'About',
                  icon: LucideIcons.info,
                  dark: dark,
                ),
                const SizedBox(height: 8),
                _GroupedCard(
                  dark: dark,
                  children: [
                    _SettingsNavTile(
                      icon: LucideIcons.shieldCheck,
                      iconColor: dark ? DhikrColors.sage : DhikrColors.forest,
                      title: AppStrings.t(lang, 'privacy'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        );
                      },
                      dark: dark,
                    ),
                    const _SectionDivider(),
                    _SettingsNavTile(
                      icon: LucideIcons.lock,
                      iconColor: const Color(0xFF10B981),
                      title: isAr ? 'أذونات الأذان والموقع والبطارية' : 'Azan & GPS Permissions',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SetupPermissionsScreen(
                              onFinished: () => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      },
                      dark: dark,
                    ),
                    const _SectionDivider(),
                    _SettingsNavTile(
                      icon: LucideIcons.helpCircle,
                      iconColor: dark ? DhikrColors.sage : DhikrColors.forest,
                      title: AppStrings.t(lang, 'about'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        );
                      },
                      dark: dark,
                    ),
                    const _SectionDivider(),
                    _SettingsNavTile(
                      icon: LucideIcons.sparkles,
                      iconColor: const Color(0xFFD97706),
                      title: isAr ? 'جولة في التطبيق (دليل البداية)' : 'App Tour & Onboarding',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnboardingScreen(
                              onFinished: (_) => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      },
                      dark: dark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _DeveloperCard(language: lang, dark: dark),
                const SizedBox(height: 12),
                _AppHeaderCard(language: lang, dark: dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmReset(BuildContext context) async {
    final lang = context.read<AppState>().language;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? DhikrColors.darkSurface
              : DhikrColors.ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppStrings.t(lang, 'reset_today'),
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            AppStrings.t(lang, 'reset_confirm'),
            style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppStrings.t(lang, 'cancel'),
                style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE55353),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.t(lang, 'ok'),
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRateSheet(BuildContext context, AppLanguage lang, bool dark) {
    final isAr = lang == AppLanguage.arabic;
    int selectedStars = 5;
    final Set<String> selectedTags = {};
    final commentCtrl = TextEditingController();

    final availableTags = isAr
        ? [
            'تصميم هادئ ومريح 🌿',
            'أذكار موثوقة ومحققة 📖',
            'مواقيت صلاة دقيقة 🕌',
            'تطبيق بدون إعلانات ✨',
            'السبحة الذكية 📿',
            'إذاعة القرآن الكريم 📻',
          ]
        : [
            'Serene Design 🌿',
            'Authentic Adhkar 📖',
            'Accurate Prayers 🕌',
            'Ad-Free Experience ✨',
            'Smart Tasbih 📿',
            'Quran Radio 📻',
          ];

    String getRatingLabel(int stars) {
      if (isAr) {
        return switch (stars) {
          1 => 'بحاجة لتحسين وتطوير 🙁',
          2 => 'مقبول، ولكن ينقصه بعض المزايا 🙂',
          3 => 'جيد ومفيد بشكل عام 👍',
          4 => 'ممتاز جداً وسلس في الاستخدام 🌟',
          5 => 'رائع ومميز، بارك الله في جهودكم! 💚',
          _ => '',
        };
      } else {
        return switch (stars) {
          1 => 'Needs improvement 🙁',
          2 => 'Fair, needs features 🙂',
          3 => 'Good and useful 👍',
          4 => 'Very good and smooth 🌟',
          5 => 'Outstanding! May Allah reward you! 💚',
          _ => '',
        };
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isAr ? 'تقييم تطبيق درة المؤمن' : 'Rate Durrat Al-Mu\'min',  
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'رأيك الصادق يساعدنا في تطوير وتحسين التطبيق'
                        : 'Your honest feedback helps us improve the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13,
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Interactive Glowing Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= selectedStars;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() => selectedStars = starIndex);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 42,
                              color: isSelected
                                  ? const Color(0xFFFFB300)
                                  : Colors.grey.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Animated Rating Emotion Label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      getRatingLabel(selectedStars),
                      key: ValueKey(selectedStars),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: selectedStars >= 4
                            ? const Color(0xFF4E8E6A)
                            : (selectedStars <= 2
                                  ? const Color(0xFFE55353)
                                  : const Color(0xFFE5A93C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Tags
                  Text(
                    isAr
                        ? 'ما أكثر ما أعجبك في التطبيق؟'
                        : 'What did you like most?',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isTagSelected = selectedTags.contains(tag);
                      return FilterChip(
                        selected: isTagSelected,
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            fontWeight: isTagSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isTagSelected
                                ? (dark ? DhikrColors.darkBg : Colors.white)
                                : (dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal),
                          ),
                        ),
                        selectedColor: dark
                            ? DhikrColors.sage
                            : DhikrColors.forest,
                        backgroundColor:
                            (dark ? Colors.white : DhikrColors.forest)
                                .withValues(alpha: 0.06),
                        checkmarkColor: dark
                            ? DhikrColors.darkBg
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isTagSelected
                                ? Colors.transparent
                                : (dark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Comment Input
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'ملاحظة إضافية أو دعوة من القلب (اختياري)...'
                          : 'Additional feedback or comment (optional)...',
                      hintStyle: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft,
                      ),
                      filled: true,
                      fillColor: (dark ? Colors.white : DhikrColors.forest)
                          .withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx);

                      final user = context
                          .read<AppState>()
                          .userProfile?['name'];

                      // Sync to local queue & admin dashboard
                      await AdminSyncService.instance.submitRating(
                        stars: selectedStars,
                        tags: selectedTags.toList(),
                        comment: commentCtrl.text.trim(),
                        userName: user,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'جزاكم الله خيراً! تم تسجيل تقييمكم وإرساله لإدارة التطبيق 💚'
                                  : 'Thank you! Your rating has been received 💚',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.send, size: 18),
                    label: Text(
                      isAr ? 'إرسال التقييم' : 'Submit Rating',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: dark
                          ? DhikrColors.sage
                          : DhikrColors.forest,
                      foregroundColor: dark ? DhikrColors.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, AppLanguage lang, bool dark) {
    final isAr = lang == AppLanguage.arabic;
    final ctrl = TextEditingController();
    String selectedCategory = isAr ? 'اقتراح تحسين' : 'Improvement Suggestion';

    final categories = isAr
        ? ['اقتراح تحسين', 'ملاحظة على ذكر أو حديث', 'مشكلة تقنية', 'أخرى']
        : ['Improvement', 'Content Note', 'Technical Bug', 'Other'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isAr ? 'إرسال ملاحظات واقتراحات' : 'Send us your Feedback',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'نرحب بكل اقتراح يسهم في تحسين وتطوير التطبيق'
                        : 'We welcome any suggestions to improve the app',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13,
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: dark
                        ? DhikrColors.darkSurface
                        : Colors.white,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      labelText: isAr ? 'نوع الرسالة' : 'Category',
                      labelStyle: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                      ),
                      filled: true,
                      fillColor: (dark ? Colors.white : DhikrColors.forest)
                          .withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'اكتب رسالتك أو اقتراحك هنا بكل تفصيل...'
                          : 'Write your feedback or suggestion here...',
                      hintStyle: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft,
                      ),
                      filled: true,
                      fillColor: (dark ? Colors.white : DhikrColors.forest)
                          .withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;

                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);

                      final email = context
                          .read<AppState>()
                          .userProfile?['email'];

                      // Send to AdminSyncService
                      await AdminSyncService.instance.submitFeedback(
                        message: text,
                        category: selectedCategory,
                        userContact: email,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم استلام ملاحظتك وإرسالها لإدارة التطبيق، شكراً لك!'
                                  : 'Feedback received and sent to dashboard, thank you!',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: dark
                          ? DhikrColors.sage
                          : DhikrColors.forest,
                      foregroundColor: dark ? DhikrColors.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isAr ? 'إرسال الملاحظة' : 'Send Feedback',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context, String kind) {
    final lang = context.read<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final String title;
    final String body;
    switch (kind) {
      case 'sources':
        title = AppStrings.t(lang, 'sources');
        body = isAr
            ? 'صحيح البخاري، صحيح مسلم، سنن أبي داود، سنن الترمذي، مسند الإمام أحمد، وحصن المسلم من أذكار الكتاب والسنة.'
            : 'Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud, Sunan at-Tirmidhi, and Musnad Ahmad.';
        break;
      default:
        title = AppStrings.t(lang, 'about');
        body = AppStrings.t(lang, 'about_text');
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dark ? DhikrColors.darkSurface : DhikrColors.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            height: 1.6,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: dark ? DhikrColors.sage : DhikrColors.forest,
              foregroundColor: dark ? DhikrColors.darkBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.t(lang, 'ok'),
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Sub-components for Settings
// ---------------------------------------------------------------------------

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isAr = language == AppLanguage.arabic;
    final userProfile = context.watch<AppState>().userProfile;
    final isLoggedIn = context.watch<AppState>().isLoggedIn;
    final userName = userProfile?['name'] ?? '';
    final userEmail = userProfile?['email'] ?? '';
    final userPhone = userProfile?['phone'] ?? '';

    final subtitle = isLoggedIn
        ? [
            if (userEmail.isNotEmpty && userEmail != 'غير مسجل') userEmail,
            if (userPhone.isNotEmpty && userPhone != 'غير مسجل') userPhone,
          ].join(' • ')
        : (isAr
              ? 'سجّل بحساب Google أو بالبريد ورقم الهاتف'
              : 'Sign in with Google, Email or Phone');

    return Material(
      color: dark ? DhikrColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
      ),
      elevation: dark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!isLoggedIn) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthScreen(
                  onSuccess: () {
                    context.read<AppState>().load();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileDetailsScreen(),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoggedIn
                        ? (dark
                              ? [DhikrColors.sage, const Color(0xFF6FA085)]
                              : [DhikrColors.forest, DhikrColors.forestLight])
                        : [
                            (dark ? DhikrColors.sage : DhikrColors.forest)
                                .withValues(alpha: 0.15),
                            (dark ? DhikrColors.sage : DhikrColors.forest)
                                .withValues(alpha: 0.08),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isLoggedIn
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: dark ? DhikrColors.darkBg : Colors.white,
                        ),
                      )
                    : Icon(
                        LucideIcons.userPlus,
                        size: 24,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn
                          ? (isAr
                                ? 'أهلاً بك، $userName'
                                : 'Welcome, $userName')
                          : (isAr ? 'تسجيل المستخدم' : 'User Account'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: dark
                            ? DhikrColors.darkText
                            : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle.isNotEmpty
                          ? subtitle
                          : (isAr ? 'حساب محفوظ ومزامن' : 'Account synced'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),

              // Action arrow or login button
              if (isLoggedIn)
                Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                )
              else
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          onSuccess: () {
                            context.read<AppState>().load();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.15),
                    foregroundColor: dark
                        ? DhikrColors.sage
                        : DhikrColors.forest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAr ? 'تسجيل' : 'Login',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLanguage lang, bool dark) {
    final isAr = lang == AppLanguage.arabic;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تسجيل الخروج' : 'Log Out',
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟'
              : 'Are you sure you want to log out from this account?',
          style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppState>().logoutUser();
              HapticFeedback.mediumImpact();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr ? 'تم تسجيل الخروج' : 'Logged out',
                      style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE55353),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isAr ? 'تسجيل الخروج' : 'Log Out',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeaderCard extends StatelessWidget {
  const _AppHeaderCard({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isAr = language == AppLanguage.arabic;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E5243).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1E5243),
                  alignment: Alignment.center,
                  child: const Text(
                    'دُرّة',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isAr ? 'دُرَّةُ الْمُؤْمِن' : 'Durrat Al-Mu’min',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: dark
                            ? DhikrColors.darkText
                            : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dark ? DhikrColors.sage : DhikrColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isAr = language == AppLanguage.arabic;
    return Material(
      color: dark ? DhikrColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
      ),
      elevation: dark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse('https://www.behance.net/mohameduxi');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/m_logo.jpg',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFF1E5243),
                    alignment: Alignment.center,
                    child: const Text(
                      'M',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تم الإنشاء بواسطة محمد حسن' : 'Created by Mohamed Hassan',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: dark
                            ? DhikrColors.darkText
                            : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Behance',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 16,
                color: dark ? Colors.white38 : DhikrColors.charcoalSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.dark,
  });

  final String title;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: dark ? DhikrColors.darkMuted : DhikrColors.forestLight,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children, required this.dark});

  final List<Widget> children;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? DhikrColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: dark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
      child: Column(children: children),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: dark
          ? Colors.white.withValues(alpha: 0.06)
          : DhikrColors.charcoal.withValues(alpha: 0.05),
    );
  }
}

class _LanguageSelectorRow extends StatelessWidget {
  const _LanguageSelectorRow({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isAr = language == AppLanguage.arabic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.languages,
              size: 20,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppStrings.t(language, 'language'),
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ),
          // Segmented Switch
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : DhikrColors.forest).withValues(
                alpha: 0.06,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentItem(
                  title: 'العربية',
                  selected: isAr,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<AppState>().setLanguage(AppLanguage.arabic);
                  },
                  dark: dark,
                ),
                _SegmentItem(
                  title: 'English',
                  selected: !isAr,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<AppState>().setLanguage(AppLanguage.english);
                  },
                  dark: dark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelectorRow extends StatelessWidget {
  const _ThemeSelectorRow({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppState>().themeMode;
    final isAr = language == AppLanguage.arabic;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              switch (themeMode) {
                ThemeModeSetting.light => LucideIcons.sun,
                ThemeModeSetting.dark => LucideIcons.moon,
                ThemeModeSetting.system => LucideIcons.monitor,
              },
              size: 20,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppStrings.t(language, 'appearance'),
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ),
          // Segmented Switch for System / Light / Dark
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : DhikrColors.forest).withValues(
                alpha: 0.06,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentItem(
                  icon: LucideIcons.sun,
                  title: isAr ? 'فاتح' : 'Light',
                  selected: themeMode == ThemeModeSetting.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<AppState>().setTheme(ThemeModeSetting.light);
                  },
                  dark: dark,
                ),
                _SegmentItem(
                  icon: LucideIcons.moon,
                  title: isAr ? 'داكن' : 'Dark',
                  selected: themeMode == ThemeModeSetting.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<AppState>().setTheme(ThemeModeSetting.dark);
                  },
                  dark: dark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.dark,
  });

  final IconData? icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? DhikrColors.sage : DhikrColors.forest)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? (dark ? DhikrColors.darkBg : Colors.white)
                    : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                  color: selected
                      ? (dark ? DhikrColors.darkBg : Colors.white)
                      : (dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioSwitchRow extends StatelessWidget {
  const _AudioSwitchRow({required this.language, required this.dark});

  final AppLanguage language;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<AppState>().audioEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              enabled ? LucideIcons.volume2 : LucideIcons.volumeX,
              size: 20,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppStrings.t(language, 'audio'),
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: dark ? DhikrColors.sage : DhikrColors.forest,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              context.read<AppState>().setAudioEnabled(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.dark,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool dark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
        ),
      ),
      trailing: trailing ??
          Icon(
            LucideIcons.chevronLeft,
            size: 20,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t(lang, 'history'),
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const _HistoryPageBody(),
          ),
        ),
      ),
    );
  }
}

class _HistoryPageBody extends StatelessWidget {
  const _HistoryPageBody();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final history = context.watch<AppState>().getHistory(limit: 30);
    if (history.isEmpty) {
      return Center(
        child: Text(
          lang == AppLanguage.arabic ? 'لا يوجد سجل بعد' : 'No history yet.',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      separatorBuilder: (context, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final entry = history[i];
        final date = entry['date'] as String;
        final isToday = i == 0;
        final label = isToday ? AppStrings.t(lang, 'today') : date;
        final morning = entry['morning'] as Map?;
        final evening = entry['evening'] as Map?;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
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
                  fontSize: 16,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              _histLine('🌅', AppStrings.t(lang, 'morning'), morning, lang),
              const SizedBox(height: 8),
              _histLine('🌙', AppStrings.t(lang, 'evening'), evening, lang),
            ],
          ),
        );
      },
    );
  }

  Widget _histLine(String icon, String title, Map? data, AppLanguage lang) {
    final completed = (data?['completed'] as num?)?.toInt() ?? 0;
    final total = (data?['total'] as num?)?.toInt() ?? 0;
    final pct = total == 0 ? 0 : (completed * 100 / total).round();
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$pct%',
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// شاشة تحليلات وسجل الالتزام بالصلوات الخمس والنشاط الشهري
class _PrayerCommitmentAnalyticsPage extends StatefulWidget {
  const _PrayerCommitmentAnalyticsPage();

  @override
  State<_PrayerCommitmentAnalyticsPage> createState() =>
      _PrayerCommitmentAnalyticsPageState();
}

class _PrayerCommitmentAnalyticsPageState
    extends State<_PrayerCommitmentAnalyticsPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        _selectedMonth = next;
      });
    }
  }

  static const _arabicMonths = [
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

  static const _englishMonths = [
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AppBar(
              title: Text(
                isAr ? 'سجل الالتزام بالصلاة' : 'Prayer Commitment',
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                // شريط التنقل بين الشهور
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 28),
                        onPressed: _previousMonth,
                        tooltip: isAr ? 'الشهر السابق' : 'Previous Month',
                      ),
                      Text(
                        '$monthName $yearStr',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: dark
                              ? DhikrColors.darkText
                              : DhikrColors.charcoal,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 28),
                        onPressed: isCurrentMonth ? null : _nextMonth,
                        tooltip: isAr ? 'الشهر التالي' : 'Next Month',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // كارت الستريك المتتالي (Streak Flame)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF38230D), const Color(0xFF241607)]
                          : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: goldAccent.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: goldAccent.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'سلسلة الالتزام: ${appState.streakCount} ${appState.streakCount == 1 ? "يوم" : "أيام متتالية"}'
                                  : '${appState.streakCount} Consecutive Days Streak',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: dark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isAr
                                  ? '«أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ»'
                                  : 'The most beloved deeds are those that are consistent.',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                color: dark
                                    ? const Color(
                                        0xFFFDE68A,
                                      ).withValues(alpha: 0.8)
                                    : const Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // شبكة ملخص الإحصائيات (4 بطاقات)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: isAr ? 'الصلوات المؤداة' : 'Prayers Done',
                        value: '$totalPrayers',
                        unit: isAr
                            ? 'من $maxPossiblePrayers'
                            : 'of $maxPossiblePrayers',
                        icon: LucideIcons.checkCircle,
                        accentColor: emerald,
                        dark: dark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: isAr ? 'نسبة الالتزام' : 'Commitment',
                        value: '$percentage%',
                        unit: isAr ? 'خلال الشهر' : 'this month',
                        icon: LucideIcons.trendingUp,
                        accentColor: const Color(0xFF4F46E5),
                        dark: dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: isAr ? 'أيام مكتملة (٥/٥)' : 'Full Days (5/5)',
                        value: '$fullDaysCount',
                        unit: isAr ? 'أيام مباركة' : 'days completed',
                        icon: LucideIcons.sparkles,
                        accentColor: goldAccent,
                        dark: dark,
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
                        icon: LucideIcons.church,
                        accentColor: const Color(0xFF0284C7),
                        dark: dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // تفصيل كل صلاة (5 أشرطة تقدم)
                Text(
                  isAr ? 'أداء الصلوات الخمس هذا الشهر' : '5 Prayers Breakdown',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? DhikrColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (dark ? DhikrColors.sage : DhikrColors.forest)
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPrayerBar(
                        name: isAr ? 'صلاة الفجر' : 'Fajr',
                        icon: LucideIcons.moon,
                        count: prayerCounts['fajr'] ?? 0,
                        max: activeDaysCount,
                        color: const Color(0xFF0F766E),
                        dark: dark,
                      ),
                      const SizedBox(height: 12),
                      _buildPrayerBar(
                        name: isAr ? 'صلاة الظهر' : 'Dhuhr',
                        icon: LucideIcons.sun,
                        count: prayerCounts['dhuhr'] ?? 0,
                        max: activeDaysCount,
                        color: const Color(0xFFD97706),
                        dark: dark,
                      ),
                      const SizedBox(height: 12),
                      _buildPrayerBar(
                        name: isAr ? 'صلاة العصر' : 'Asr',
                        icon: LucideIcons.sunset,
                        count: prayerCounts['asr'] ?? 0,
                        max: activeDaysCount,
                        color: const Color(0xFFEA580C),
                        dark: dark,
                      ),
                      const SizedBox(height: 12),
                      _buildPrayerBar(
                        name: isAr ? 'صلاة المغرب' : 'Maghrib',
                        icon: LucideIcons.moon,
                        count: prayerCounts['maghrib'] ?? 0,
                        max: activeDaysCount,
                        color: const Color(0xFF4F46E5),
                        dark: dark,
                      ),
                      const SizedBox(height: 12),
                      _buildPrayerBar(
                        name: isAr ? 'صلاة العشاء' : 'Isha',
                        icon: LucideIcons.moon,
                        count: prayerCounts['isha'] ?? 0,
                        max: activeDaysCount,
                        color: const Color(0xFF2563EB),
                        dark: dark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // تقويم أيام الشهر التفاعلي
                Text(
                  isAr ? 'تقويم التزام الشهر' : 'Monthly Activity Calendar',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'اضغط على أي يوم للاطلاع على الصلوات المؤداة فيه'
                      : 'Tap any day to see prayers completed on that day',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 11,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
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
            Text(
              '$count / $max',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
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
        ? ['سبت', 'أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع']
        : ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    // First day offset (1 = Monday, 7 = Sunday in Dart)
    final firstDate = DateTime(year, month, 1);
    // Saturday-based index: Saturday=0, Sunday=1, Monday=2, etc.
    final satOffset = (firstDate.weekday + 1) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Column(
        children: [
          // أسماء الأيام
          Row(
            children: weekdays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // شبكة خلايا الأيام
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: satOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
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

              if (count == 5) {
                cellBg = const Color(0xFF0F766E);
                borderColor = const Color(0xFF0F766E);
                textColor = Colors.white;
              } else if (count > 0) {
                cellBg = (dark
                    ? const Color(0xFF1E3A2F)
                    : const Color(0xFFE8F5E9));
                borderColor = const Color(0xFF0F766E).withValues(alpha: 0.4);
                textColor = dark ? Colors.white : const Color(0xFF0F766E);
              } else if (isToday) {
                cellBg = (dark
                    ? const Color(0xFF38230D)
                    : const Color(0xFFFEF3C7));
                borderColor = const Color(0xFFD97706);
                textColor = dark
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFF92400E);
              } else {
                cellBg = dark
                    ? const Color(0xFF161D1A)
                    : const Color(0xFFF7FAF8);
                borderColor = (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                );
                textColor = isFuture
                    ? (dark ? Colors.white24 : Colors.black26)
                    : (dark ? DhikrColors.darkMuted : DhikrColors.charcoal);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showDayPrayerDetails(
                      context,
                      day,
                      month,
                      year,
                      tasks,
                      isAr,
                      dark,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: isToday ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: isToday || count > 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                        if (count == 5)
                          const Text(
                            '★',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFFDE68A),
                            ),
                          )
                        else if (count > 0)
                          Text(
                            '$count/5',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayPrayerDetails(
    BuildContext context,
    int day,
    int month,
    int year,
    Set<String> tasks,
    bool isAr,
    bool dark,
  ) {
    final prayerTitles = {
      'fajr': isAr ? 'صلاة الفجر 🌌' : 'Fajr Prayer 🌌',
      'dhuhr': isAr ? 'صلاة الظهر ☀️' : 'Dhuhr Prayer ☀️',
      'asr': isAr ? 'صلاة العصر 🌤️' : 'Asr Prayer 🌤️',
      'maghrib': isAr ? 'صلاة المغرب 🌇' : 'Maghrib Prayer 🌇',
      'isha': isAr ? 'صلاة العشاء 🌙' : 'Isha Prayer 🌙',
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isAr
                      ? 'صلوات يوم $day/$month/$year'
                      : 'Prayers for $day/$month/$year',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'تم تسجيل ${tasks.length.toString().split('').map((d) {
                          const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
                          final i = int.tryParse(d);
                          return i != null ? arabicDigits[i] : d;
                        }).join()} من ٥ صلوات'
                      : '${tasks.length} of 5 prayers completed',
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 20),
                ...prayerTitles.entries.map((e) {
                  final isDone = tasks.contains(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? LucideIcons.checkCircle
                              : LucideIcons.circle,
                          color: isDone
                              ? const Color(0xFF0F766E)
                              : (dark ? Colors.white30 : Colors.black26),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 14,
                            fontWeight: isDone
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDone
                                ? (dark ? Colors.white : Colors.black87)
                                : (dark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
