import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_content_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/broadcast_banner.dart';
import '../widgets/home_cards.dart';
import '../widgets/home_hero_card.dart';
import 'anime_stories_screen.dart';
import 'companions_screen.dart';
import 'hadith_screen.dart';
import 'hajj_umrah_screen.dart';
import 'jawami_dhikr_screen.dart';
import 'location_map_picker_screen.dart';
import 'loved_ones_screen.dart';
import 'nearest_mosques_screen.dart';
import 'prayer_commitment_screen.dart';
import 'qibla_screen.dart';
import 'quran_mushaf_screen.dart';
import 'quran_radio_screen.dart';
import 'shaarawi_screen.dart';
import 'soul_remedy_screen.dart';
import 'zakat_calculator_screen.dart';
import 'notifications_screen.dart';

/// The redesigned Home Screen — engineered in RonDesignLab's signature style:
/// Ultra-curved glass cards (28-32px), subtle depth, atmospheric gradients,
/// DGA-compliant geometric stroke icons, and generous breathing room.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenCategory});

  final ValueChanged<DhikrCategory> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // ملاحظة أداء: لا نستدعي initialize() داخل build (كانت تُستدعى مع كل
    // إعادة بناء). التهيئة تتم مرة واحدة من main في الخلفية، وهنا نكتفي
    // بالاستماع عبر ListenableBuilder أدناه.
    final popup = RemoteContentService.instance.popupAnnouncement;
    if (popup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPopupIfNeeded(context, popup);
      });
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark
            ? const Color(0xFF0A1612)
            : const Color(0xFFF7F5F0),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListenableBuilder(
                listenable: RemoteContentService.instance,
                builder: (context, _) => CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ─────────────────────────────────────────────
                  // 1. TOP HEADER (Brand wordmark + Greeting)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: App Icon + Title
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0F3B2C,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/app_icon.webp',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isAr ? 'درة المؤمن' : "Durrat Al-Mu'min",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: dark
                                          ? Colors.white
                                          : DhikrColors.charcoal,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right: Dynamic Location Chip + Notifications Button
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (context) {
                                  final savedLoc = appState.storage
                                      .getSavedLocation();
                                  String cityDisplay = isAr
                                      ? 'بغداد'
                                      : 'Baghdad';
                                  String countryDisplay = isAr
                                      ? 'العراق'
                                      : 'Iraq';
                                  String locationLabel = isAr
                                      ? 'بغداد، العراق'
                                      : 'Baghdad, Iraq';

                                  if (savedLoc != null) {
                                    final rawAr =
                                        (savedLoc['cityAr'] as String?)
                                            ?.trim() ??
                                        '';
                                    final rawEn =
                                        (savedLoc['cityEn'] as String?)
                                            ?.trim() ??
                                        '';
                                    final cAr =
                                        (savedLoc['countryAr'] as String?)
                                            ?.trim() ??
                                        '';
                                    final cEn =
                                        (savedLoc['countryEn'] as String?)
                                            ?.trim() ??
                                        '';
                                    final pAr =
                                        (savedLoc['provinceAr'] as String?)
                                            ?.trim() ??
                                        '';
                                    final pEn =
                                        (savedLoc['provinceEn'] as String?)
                                            ?.trim() ??
                                        '';

                                    if (isAr) {
                                      if (rawAr.isNotEmpty &&
                                          !rawAr.toLowerCase().contains(
                                            'city',
                                          )) {
                                        cityDisplay = rawAr;
                                      } else if (rawEn.toLowerCase().contains(
                                            'mit ghamr',
                                          ) ||
                                          rawAr.toLowerCase().contains(
                                            'mit ghamr',
                                          )) {
                                        cityDisplay = 'ميت غمر';
                                      } else if (rawEn.toLowerCase().contains(
                                            'baghdad',
                                          ) ||
                                          rawAr.toLowerCase().contains(
                                            'baghdad',
                                          )) {
                                        cityDisplay = 'بغداد';
                                      } else {
                                        cityDisplay = rawAr.isNotEmpty
                                            ? rawAr
                                            : (rawEn.isNotEmpty
                                                  ? rawEn
                                                  : 'بغداد');
                                      }
                                      cityDisplay = cityDisplay
                                          .replaceAll(' City', '')
                                          .replaceAll(' Governorate', '')
                                          .replaceAll('محافظة', '')
                                          .trim();
                                      countryDisplay = cAr.isNotEmpty
                                          ? cAr
                                          : (cEn.isNotEmpty ? cEn : 'العراق');
                                      if (countryDisplay.toLowerCase().contains(
                                        'egypt',
                                      )) {
                                        countryDisplay = 'مصر';
                                      }
                                      if (countryDisplay.toLowerCase().contains(
                                        'iraq',
                                      )) {
                                        countryDisplay = 'العراق';
                                      }
                                    } else {
                                      cityDisplay = rawEn.isNotEmpty
                                          ? rawEn
                                          : (rawAr.isNotEmpty
                                                ? rawAr
                                                : 'Baghdad');
                                      cityDisplay = cityDisplay
                                          .replaceAll(' City', '')
                                          .replaceAll(' Governorate', '')
                                          .trim();
                                      countryDisplay = cEn.isNotEmpty
                                          ? cEn
                                          : (cAr.isNotEmpty ? cAr : 'Iraq');
                                    }

                                    final displayProvince = isAr
                                        ? (pAr.isNotEmpty
                                              ? pAr
                                              : (pEn.isNotEmpty ? pEn : ''))
                                        : (pEn.isNotEmpty
                                              ? pEn
                                              : (pAr.isNotEmpty ? pAr : ''));
                                    final cleanedProvince = displayProvince
                                        .replaceAll(' Governorate', '')
                                        .replaceAll('محافظة', '')
                                        .replaceAll(' Province', '')
                                        .trim();

                                    locationLabel =
                                        cleanedProvince.isNotEmpty &&
                                                cleanedProvince != cityDisplay
                                            ? '$cityDisplay، $cleanedProvince'
                                            : countryDisplay.isNotEmpty
                                                  ? '$cityDisplay، $countryDisplay'
                                                  : cityDisplay;
                                  }

                                  return Tooltip(
                                    message: isAr
                                        ? 'انقر لتحديد موقعك يدوياً عبر الخريطة'
                                        : 'Tap to pick location on map',
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                LocationMapPickerScreen(
                                                  initialLat:
                                                      (savedLoc?['lat'] as num?)
                                                          ?.toDouble(),
                                                  initialLng:
                                                      (savedLoc?['lng'] as num?)
                                                          ?.toDouble(),
                                                  initialCityAr:
                                                      savedLoc?['cityAr']
                                                          as String?,
                                                  initialProvinceAr:
                                                      savedLoc?['provinceAr']
                                                          as String?,
                                                  initialCountryAr:
                                                      savedLoc?['countryAr']
                                                          as String?,
                                                ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : DhikrColors.sageSoft.withValues(
                                                  alpha: 0.65,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: dark
                                                ? const Color(
                                                    0xFF34D399,
                                                  ).withValues(alpha: 0.3)
                                                : DhikrColors.forest.withValues(
                                                    alpha: 0.22,
                                                  ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.mapPin,
                                              size: 13,
                                              color: dark
                                                  ? const Color(0xFF34D399)
                                                  : DhikrColors.forest,
                                            ),
                                            const SizedBox(width: 5),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 130,
                                              ),
                                              child: Text(
                                                locationLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: isAr
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                                style: TextStyle(
                                                  fontFamily:
                                                      DhikrTheme.arabicFont,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: dark
                                                      ? Colors.white
                                                      : DhikrColors.charcoal,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(
                                              LucideIcons.chevronDown,
                                              size: 12,
                                              color: dark
                                                  ? DhikrColors.darkMuted
                                                  : DhikrColors.charcoalSoft,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              // Notification Bell Button
                              Tooltip(
                                message: isAr ? 'الإشعارات' : 'Notifications',
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : DhikrColors.sageSoft.withValues(
                                              alpha: 0.65,
                                            ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dark
                                            ? const Color(
                                                0xFF34D399,
                                              ).withValues(alpha: 0.3)
                                            : DhikrColors.forest.withValues(
                                                alpha: 0.22,
                                              ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.bell,
                                        size: 16,
                                        color: dark
                                            ? const Color(0xFF34D399)
                                            : DhikrColors.forest,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─────────────────────────────────────────────
                  // 2. HERO CARD (RonDesignLab atmospheric card)
                  // ─────────────────────────────────────────────
                  const SliverToBoxAdapter(child: HomeHeroCard()),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // ─────────────────────────────────────────────
                  // 3..7. SECTIONS — كل قسم عنوان + شبكة كروت موحّدة
                  // (نفس مقاس الكارد، نفس المسافات، نفس ترتيب الصورة/النص)
                  // ─────────────────────────────────────────────
                  ..._buildSectionSlivers(
                    context: context,
                    appState: appState,
                    isAr: isAr,
                    dark: dark,
                  ),

                  // Bottom padding for navigation bar ensuring last cards are completely visible
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
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
  // Section Header with clean typographic hierarchy
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool dark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : DhikrColors.charcoal,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTIONS — الكروت معرّفة كبيانات، وكل قسم يُرسم بنفس الشبكة
  //
  // كانت الشاشة تخلط أربعة أنماط كروت (٣ أعمدة / ٢ أعمدة / عريض / بكامل
  // العرض) بأحجام ومسافات مختلفة، فتبيّن «مساحات غلط» بين الأقسام. الآن كل
  // قسم شبكة واحدة بمسافات متطابقة، ومقاس الخليّة يتغيّر فقط مع عدد الأعمدة.
  // ══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildSectionSlivers({
    required BuildContext context,
    required AppState appState,
    required bool isAr,
    required bool dark,
  }) {
    final slivers = <Widget>[];

    final remote = RemoteContentService.instance;
    bool cardVisible(HomeCardSpec c) =>
        c.remoteKey == null || remote.isCardVisible(c.remoteKey!);

    void section(
      String title,
      List<HomeCardSpec> cards, {
      int columns = 3,
      double cellHeight = 134,
      double imageSize = 58,
      bool first = false,
    }) {
      final visible = cards.where(cardVisible).toList();
      if (visible.isEmpty) return;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            // حافة العنوان = حافة الكروت (16) — كانوا 20/16 فالنص بادٍ
            // أبعد من الكروت وبيبان «غير متناسق».
            padding: EdgeInsets.fromLTRB(16, first ? 2 : 22, 16, 10),
            child: _buildSectionHeader(context, title: title, dark: dark),
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HomeCardGrid(
              cards: visible,
              dark: dark,
              columns: columns,
              cellHeight: cellHeight,
              imageSize: imageSize,
            ),
          ),
        ),
      );
    }

    // أذكار التطبيق: الكارد يحمل شريط تقدّم وشارة النسبة بدل بطاقة منفصلة.
    HomeCardSpec adhkarCard(
      DhikrCategory category, {
      required String titleAr,
      required String titleEn,
      required IconData icon,
      required Color accent,
      required Color pastelStart,
      required Color pastelEnd,
      required String imageAsset,
      String? remoteKey,
    }) {
      final progress = appState.categoryProgress(category);
      final percent = progress.total == 0
          ? 0
          : (progress.completed * 100 / progress.total).round();
      final isCompleted =
          progress.total > 0 && progress.completed >= progress.total;
      return HomeCardSpec(
        title: isAr ? titleAr : titleEn,
        icon: icon,
        accent: accent,
        imageAsset: imageAsset,
        pastelStart: pastelStart,
        pastelEnd: pastelEnd,
        badgeText: isCompleted ? '✓' : '$percent%',
        progress: progress.total == 0
            ? 0.0
            : (progress.completed / progress.total).clamp(0.0, 1.0),
        remoteKey: remoteKey,
        onTap: () => onOpenCategory(category),
      );
    }

    // ── 1. أذكارك اليومية (شبكة ٢×٢) ──────────────────────────────────────
    section(
      isAr ? 'أذكارك اليومية' : 'Daily Adhkar',
      [
        adhkarCard(
          DhikrCategory.morning,
          titleAr: 'أذكار الصباح',
          titleEn: 'Morning Adhkar',
          icon: LucideIcons.sun,
          accent: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          pastelStart: const Color(0xFFFFFBEB),
          pastelEnd: const Color(0xFFFDE68A),
          imageAsset: 'assets/images/clay_3d_morning.webp',
          remoteKey: 'morningEvening',
        ),
        adhkarCard(
          DhikrCategory.evening,
          titleAr: 'أذكار المساء',
          titleEn: 'Evening Adhkar',
          icon: LucideIcons.moon,
          accent: dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          pastelStart: const Color(0xFFF5F3FF),
          pastelEnd: const Color(0xFFDDD6FE),
          imageAsset: 'assets/images/clay_3d_evening.webp',
          remoteKey: 'morningEvening',
        ),
        adhkarCard(
          DhikrCategory.afterPrayer,
          titleAr: 'أذكار بعد الصلاة',
          titleEn: 'After Prayer',
          icon: LucideIcons.sparkles,
          accent: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
          pastelStart: const Color(0xFFECFDF5),
          pastelEnd: const Color(0xFFA7F3D0),
          imageAsset: 'assets/images/clay_3d_after_prayer.webp',
          remoteKey: 'morningEvening',
        ),
        adhkarCard(
          DhikrCategory.ruqyah,
          titleAr: 'الرقية الشرعية',
          titleEn: 'Ruqyah',
          icon: LucideIcons.shieldCheck,
          accent: dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          pastelStart: const Color(0xFFF0F9FF),
          pastelEnd: const Color(0xFFBAE6FD),
          imageAsset: 'assets/images/clay_3d_ruqyah.webp',
          remoteKey: 'morningEvening',
        ),
      ],
      columns: 2,
      cellHeight: 140,
      imageSize: 72,
      first: true,
    );

    // ── 2. المعرفة والعلوم الشرعية (شبكة ٣×٢) ─────────────────────────────
    section(
      isAr ? 'المعرفة والعلوم الشرعية' : 'Islamic Knowledge',
      [
        HomeCardSpec(
          title: isAr ? 'المصحف الشريف' : 'Holy Quran',
          icon: LucideIcons.bookOpen,
          accent: const Color(0xFF059669),
          imageAsset: 'assets/images/clay_3d_quran.webp',
          pastelStart: const Color(0xFFECFDF5),
          pastelEnd: const Color(0xFFA7F3D0),
          remoteKey: 'quranMushaf',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuranMushafScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'الأحاديث النبوية' : 'Prophetic Hadiths',
          icon: LucideIcons.bookCheck,
          accent: const Color(0xFFD97706),
          imageAsset: 'assets/images/clay_3d_hadith.webp',
          pastelStart: const Color(0xFFFFFBEB),
          pastelEnd: const Color(0xFFFDE68A),
          remoteKey: 'hadith',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HadithScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'جوامع الذكر' : "Jawami' Dhikr",
          icon: LucideIcons.sparkles,
          accent: const Color(0xFF0284C7),
          imageAsset: 'assets/images/jawami_mosque.png',
          pastelStart: const Color(0xFFF0F9FF),
          pastelEnd: const Color(0xFFBAE6FD),
          remoteKey: 'jawamiDhikr',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JawamiDhikrScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'خواطر الشعراوي' : 'Shaarawi Lessons',
          icon: LucideIcons.graduationCap,
          accent: const Color(0xFF65A30D),
          imageAsset: 'assets/images/clay_3d_shaarawi.webp',
          pastelStart: const Color(0xFFF7FEE7),
          pastelEnd: const Color(0xFFD9F99D),
          remoteKey: 'shaarawi',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShaarawiScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'قصص الصحابة' : 'Companions',
          icon: LucideIcons.users,
          accent: const Color(0xFF8B5CF6),
          imageAsset: 'assets/images/clay_3d_companions.webp',
          pastelStart: const Color(0xFFF5F3FF),
          pastelEnd: const Color(0xFFDDD6FE),
          remoteKey: 'companions',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CompanionsScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'انمي اسلامي' : 'Islamic Anime',
          icon: LucideIcons.tvMinimalPlay,
          accent: const Color(0xFFEC4899),
          imageAsset: 'assets/images/clay_3d_stories.webp',
          pastelStart: const Color(0xFFFDF2F8),
          pastelEnd: const Color(0xFFFBCFE8),
          remoteKey: 'animeStories',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AnimeStoriesScreen()),
          ),
        ),
      ],
    );

    // ── 3. المجتمع والالتزام (شبكة ٢×١) ──────────────────────────────────
    section(
      isAr ? 'المجتمع والالتزام' : 'Community & Commitment',
      [
        HomeCardSpec(
          title: isAr ? 'دعاء بظهر الغيب' : 'Dua in Absentia',
          icon: LucideIcons.heartHandshake,
          accent: const Color(0xFFE11D48),
          imageAsset: 'assets/images/clay_3d_loved_ones.webp',
          pastelStart: const Color(0xFFFFF1F2),
          pastelEnd: const Color(0xFFFECDD3),
          remoteKey: 'duaInAbsentia',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LovedOnesScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'الالتزام بالصلاة' : 'Prayer Tracking',
          icon: LucideIcons.calendarCheck,
          accent: const Color(0xFF6366F1),
          imageAsset: 'assets/images/clay_3d_minaret.webp',
          pastelStart: const Color(0xFFEEF2FF),
          pastelEnd: const Color(0xFFC7D2FE),
          remoteKey: 'commitmentTree',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrayerCommitmentScreen()),
          ),
        ),
      ],
      columns: 2,
      cellHeight: 140,
      imageSize: 72,
    );

    // ── 4. الزكاة والصدقات والأضاحي (شبكة ٢×٢) ────────────────────────────
    section(
      isAr ? 'الزكاة والصدقات والأضاحي' : 'Zakat & Charities',
      [
        HomeCardSpec(
          title: isAr ? 'حاسبة الزكاة' : 'Zakat Calculator',
          icon: LucideIcons.calculator,
          accent: const Color(0xFF059669),
          imageAsset: 'assets/images/clay_3d_zakat_calc.webp',
          pastelStart: const Color(0xFFECFDF5),
          pastelEnd: const Color(0xFFA7F3D0),
          remoteKey: 'zakatCalc',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 0),
            ),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'حاسبة النصاب' : 'Nisab Calculator',
          icon: LucideIcons.coins,
          accent: const Color(0xFFD97706),
          imageAsset: 'assets/images/clay_3d_nisab.webp',
          pastelStart: const Color(0xFFFFFBEB),
          pastelEnd: const Color(0xFFFDE68A),
          remoteKey: 'nisabCalc',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 1),
            ),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'مستحقي الزكاة' : 'Zakat Beneficiaries',
          icon: LucideIcons.usersRound,
          accent: const Color(0xFF2563EB),
          imageAsset: 'assets/images/clay_3d_zakat_beneficiaries.webp',
          pastelStart: const Color(0xFFEFF6FF),
          pastelEnd: const Color(0xFFBFDBFE),
          remoteKey: 'zakatBeneficiaries',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 2),
            ),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'مستحقي الأضحية' : 'Udhiyah Beneficiaries',
          icon: LucideIcons.gift,
          accent: const Color(0xFFDC2626),
          imageAsset: 'assets/images/clay_3d_udhiyah.webp',
          pastelStart: const Color(0xFFFEF2F2),
          pastelEnd: const Color(0xFFFECACA),
          remoteKey: 'udhiyahBeneficiaries',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 3),
            ),
          ),
        ),
      ],
      columns: 2,
      cellHeight: 140,
      imageSize: 72,
    );

    // ── 5. أدوات وخدمات المسلم (شبكة ٣×٢) ─────────────────────────────────
    section(
      isAr ? 'أدوات وخدمات المسلم' : 'Muslim Tools',
      [
        HomeCardSpec(
          title: isAr ? 'إذاعة القرآن' : 'Quran Radio',
          icon: LucideIcons.radio,
          accent: const Color(0xFFE11D48),
          imageAsset: 'assets/images/clay_3d_radio.webp',
          pastelStart: const Color(0xFFFFF1F2),
          pastelEnd: const Color(0xFFFECDD3),
          remoteKey: 'quranRadio',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuranRadioScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'الحج والعمرة' : 'Hajj & Umrah',
          icon: LucideIcons.landmark,
          accent: const Color(0xFFD97706),
          imageAsset: 'assets/images/tool_hajj_3d.webp',
          pastelStart: const Color(0xFFFFFBEB),
          pastelEnd: const Color(0xFFFDE68A),
          remoteKey: 'hajjUmrah',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HajjUmrahScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'صيدلية الروح' : 'Soul Remedy',
          icon: LucideIcons.heart,
          accent: const Color(0xFF10B981),
          imageAsset: 'assets/images/clay_3d_soul.webp',
          pastelStart: const Color(0xFFECFDF5),
          pastelEnd: const Color(0xFFA7F3D0),
          remoteKey: 'soulMedicine',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SoulRemedyScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'بوصلة القبلة' : 'Qibla Compass',
          icon: LucideIcons.compass,
          accent: const Color(0xFF0284C7),
          imageAsset: 'assets/images/tool_qibla_3d.webp',
          pastelStart: const Color(0xFFF0F9FF),
          pastelEnd: const Color(0xFFBAE6FD),
          remoteKey: 'qibla',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QiblaScreen()),
          ),
        ),
        HomeCardSpec(
          title: isAr ? 'مساجد معروفة' : 'Famous Mosques',
          icon: LucideIcons.mapPin,
          accent: const Color(0xFF059669),
          imageAsset: 'assets/images/mosque_glow.png',
          pastelStart: const Color(0xFFECFDF5),
          pastelEnd: const Color(0xFFA7F3D0),
          remoteKey: 'nearestMosque',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NearestMosquesScreen()),
          ),
        ),
      ],
    );

    return slivers;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Remote-Controlled Featured Dhikr Banner
// ══════════════════════════════════════════════════════════════════════════
class _FeaturedDhikrBanner extends StatelessWidget {
  const _FeaturedDhikrBanner({required this.dark, required this.isAr});

  final bool dark;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RemoteContentService.instance,
      builder: (context, _) {
        final text = RemoteContentService.instance.featuredDhikr;
        if (text.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'ذكر اليوم المميز' : 'Featured Dhikr',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: dark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'تم نسخ الذكر بنجاح ✨' : 'Copied to clipboard',
                              textAlign: TextAlign.center,
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.8,
                    color: dark ? Colors.white : DhikrColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Remote-Controlled In-App Popup Announcement Dialog
// ══════════════════════════════════════════════════════════════════════════
String? _lastShownPopupId;

void _showPopupIfNeeded(BuildContext context, Map<String, dynamic> popup) {
  final id = (popup['id'] ?? popup['title'] ?? '').toString();
  if (id.isEmpty || id == _lastShownPopupId) return;
  _lastShownPopupId = id;

  final title = (popup['title'] ?? '').toString();
  final message = (popup['message'] ?? '').toString();
  final url = (popup['actionUrl'] ?? '').toString().trim();
  final btnText = (popup['actionText'] ?? '').toString().trim();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.bellRing, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.isNotEmpty ? title : 'تنبيه من إدارة التطبيق',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 14.5,
          height: 1.7,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'إغلاق',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (url.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              btnText.isNotEmpty ? btnText : 'عرض المزيد',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}

