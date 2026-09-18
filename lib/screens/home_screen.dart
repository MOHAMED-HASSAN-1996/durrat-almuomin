import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
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
import '../widgets/nawafil_tracker_sheet.dart';

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

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: CustomScrollView(
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
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F3B2C).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'دُرَّةُ الْمُؤْمِن' : "Durrat Al-Mu'min",
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: dark ? Colors.white : DhikrColors.charcoal,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          // Right: Dynamic Location Chip + Notifications Button
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (context) {
                                  final savedLoc = appState.storage.getSavedLocation();
                                  String cityDisplay = isAr ? 'بغداد' : 'Baghdad';
                                  String countryDisplay = isAr ? 'العراق' : 'Iraq';

                                  if (savedLoc != null) {
                                    final rawAr = (savedLoc['cityAr'] as String?)?.trim() ?? '';
                                    final rawEn = (savedLoc['cityEn'] as String?)?.trim() ?? '';
                                    final cAr = (savedLoc['countryAr'] as String?)?.trim() ?? '';
                                    final cEn = (savedLoc['countryEn'] as String?)?.trim() ?? '';

                                    if (isAr) {
                                      if (rawAr.isNotEmpty && !rawAr.toLowerCase().contains('city')) {
                                        cityDisplay = rawAr;
                                      } else if (rawEn.toLowerCase().contains('mit ghamr') || rawAr.toLowerCase().contains('mit ghamr')) {
                                        cityDisplay = 'ميت غمر';
                                      } else if (rawEn.toLowerCase().contains('baghdad') || rawAr.toLowerCase().contains('baghdad')) {
                                        cityDisplay = 'بغداد';
                                      } else {
                                        cityDisplay = rawAr.isNotEmpty ? rawAr : (rawEn.isNotEmpty ? rawEn : 'بغداد');
                                      }
                                      cityDisplay = cityDisplay.replaceAll(' City', '').replaceAll(' Governorate', '').replaceAll('محافظة', '').trim();
                                      countryDisplay = cAr.isNotEmpty ? cAr : (cEn.isNotEmpty ? cEn : 'العراق');
                                      if (countryDisplay.toLowerCase().contains('egypt')) countryDisplay = 'مصر';
                                      if (countryDisplay.toLowerCase().contains('iraq')) countryDisplay = 'العراق';
                                    } else {
                                      cityDisplay = rawEn.isNotEmpty ? rawEn : (rawAr.isNotEmpty ? rawAr : 'Baghdad');
                                      cityDisplay = cityDisplay.replaceAll(' City', '').replaceAll(' Governorate', '').trim();
                                      countryDisplay = cEn.isNotEmpty ? cEn : (cAr.isNotEmpty ? cAr : 'Iraq');
                                    }
                                  }

                                  final locationLabel = countryDisplay.isNotEmpty
                                      ? '$cityDisplay، $countryDisplay'
                                      : cityDisplay;

                                  return Tooltip(
                                    message: isAr ? 'انقر لتحديد موقعك يدوياً عبر الخريطة' : 'Tap to pick location on map',
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => LocationMapPickerScreen(
                                              initialLat: (savedLoc?['lat'] as num?)?.toDouble(),
                                              initialLng: (savedLoc?['lng'] as num?)?.toDouble(),
                                              initialCityAr: savedLoc?['cityAr'] as String?,
                                              initialCountryAr: savedLoc?['countryAr'] as String?,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : DhikrColors.sageSoft.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: dark
                                                ? const Color(0xFF34D399).withValues(alpha: 0.3)
                                                : DhikrColors.forest.withValues(alpha: 0.22),
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
                                              constraints: const BoxConstraints(maxWidth: 130),
                                              child: Text(
                                                locationLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                                style: TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
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
                                        builder: (_) => const NotificationsScreen(),
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
                                          : DhikrColors.sageSoft.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dark
                                            ? const Color(0xFF34D399).withValues(alpha: 0.3)
                                            : DhikrColors.forest.withValues(alpha: 0.22),
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
                  const SliverToBoxAdapter(
                    child: HomeHeroCard(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ─────────────────────────────────────────────
                  // 3. DAILY ADHKAR (Title Only, 4 Essential Categories)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildSectionHeader(
                        context,
                        title: isAr ? 'أذكارك اليومية' : 'Daily Adhkar',
                        dark: dark,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Row 1: Morning & Evening
                          Row(
                            children: [
                              Expanded(
                                child: _buildAdhkarBentoCard(
                                  context: context,
                                  category: DhikrCategory.morning,
                                  title: isAr ? 'أذكار الصباح' : 'Morning Adhkar',
                                  icon: LucideIcons.sun,
                                  isPrimary: true,
                                  dark: dark,
                                  isAr: isAr,
                                  onTap: () => onOpenCategory(DhikrCategory.morning),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildAdhkarBentoCard(
                                  context: context,
                                  category: DhikrCategory.evening,
                                  title: isAr ? 'أذكار المساء' : 'Evening Adhkar',
                                  icon: LucideIcons.moon,
                                  isPrimary: true,
                                  dark: dark,
                                  isAr: isAr,
                                  onTap: () => onOpenCategory(DhikrCategory.evening),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Row 2: After Prayer & Ruqyah
                          Row(
                            children: [
                              Expanded(
                                child: _buildAdhkarBentoCard(
                                  context: context,
                                  category: DhikrCategory.afterPrayer,
                                  title: isAr ? 'أذكار بعد الصلاة' : 'After Prayer',
                                  icon: LucideIcons.sparkles,
                                  isPrimary: false,
                                  dark: dark,
                                  isAr: isAr,
                                  onTap: () => onOpenCategory(DhikrCategory.afterPrayer),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildAdhkarBentoCard(
                                  context: context,
                                  category: DhikrCategory.ruqyah,
                                  title: isAr ? 'الرقية الشرعية' : 'Ruqyah',
                                  icon: LucideIcons.shieldCheck,
                                  isPrimary: false,
                                  dark: dark,
                                  isAr: isAr,
                                  onTap: () => onOpenCategory(DhikrCategory.ruqyah),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // ─────────────────────────────────────────────
                  // 4. ISLAMIC KNOWLEDGE & SCIENCES (المعرفة والعلوم الشرعية)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                      child: _buildSectionHeader(
                        context,
                        title: isAr ? 'المعرفة والعلوم الشرعية' : 'Islamic Knowledge',
                        dark: dark,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Trio Row 1: [ المصحف الشريف | الأحاديث النبوية | جوامع الذكر ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'المصحف الشريف' : 'Holy Quran',
                                  imageAsset: 'assets/images/clay_3d_quran.png',
                                  icon: LucideIcons.bookOpen,
                                  accentColor: const Color(0xFF059669),
                                  pastelLightStart: const Color(0xFFECFDF5),
                                  pastelLightEnd: const Color(0xFFA7F3D0),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const QuranMushafScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'الأحاديث النبوية' : 'Prophetic Hadiths',
                                  imageAsset: 'assets/images/clay_3d_hadith.png',
                                  icon: LucideIcons.bookCheck,
                                  accentColor: const Color(0xFFD97706),
                                  pastelLightStart: const Color(0xFFFFFBEB),
                                  pastelLightEnd: const Color(0xFFFDE68A),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const HadithScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'جوامع الذكر' : "Jawami' Dhikr",
                                  imageAsset: 'assets/images/clay_3d_jawami.png',
                                  icon: LucideIcons.sparkles,
                                  accentColor: const Color(0xFF0284C7),
                                  pastelLightStart: const Color(0xFFF0F9FF),
                                  pastelLightEnd: const Color(0xFFBAE6FD),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const JawamiDhikrScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Trio Row 2: [ خواطر الشعراوي | قصص الصحابة | قصص دينية ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'خواطر الشعراوي' : 'Shaarawi Lessons',
                                  imageAsset: 'assets/images/clay_3d_shaarawi.png',
                                  icon: LucideIcons.graduationCap,
                                  accentColor: const Color(0xFF65A30D),
                                  pastelLightStart: const Color(0xFFF7FEE7),
                                  pastelLightEnd: const Color(0xFFD9F99D),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ShaarawiScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'قصص الصحابة' : 'Companions',
                                  imageAsset: 'assets/images/clay_3d_companions.png',
                                  icon: LucideIcons.users,
                                  accentColor: const Color(0xFF8B5CF6),
                                  pastelLightStart: const Color(0xFFF5F3FF),
                                  pastelLightEnd: const Color(0xFFDDD6FE),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CompanionsScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'قصص دينية' : 'Religious Stories',
                                  imageAsset: 'assets/images/clay_3d_stories.png',
                                  icon: LucideIcons.tvMinimalPlay,
                                  accentColor: const Color(0xFFEC4899),
                                  pastelLightStart: const Color(0xFFFDF2F8),
                                  pastelLightEnd: const Color(0xFFFBCFE8),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AnimeStoriesScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ─────────────────────────────────────────────
                  // 5. WORSHIP & SUPPLICATIONS (العبادات والمناجاة)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildSectionHeader(
                        context,
                        title: isAr ? 'العبادات والمناجاة' : 'Worship & Supplications',
                        dark: dark,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Highlight Card: [ صلوات النوافل والسنن الرواتب ]
                          _buildWideServiceCard(
                            context: context,
                            title: isAr ? 'صلوات النوافل والسنن الرواتب' : 'Nawafil & Sunnah Tracker',
                            imageAsset: 'assets/images/clay_3d_after_prayer.png',
                            icon: LucideIcons.sparkles,
                            accentColor: const Color(0xFF059669),
                            pastelLightStart: const Color(0xFFECFDF5),
                            pastelLightEnd: const Color(0xFFA7F3D0),
                            dark: dark,
                            onTap: () => NawafilTrackerSheet.show(context),
                          ),
                          const SizedBox(height: 8),

                          // Card 2: [ دعاء بظهر الغيب ]
                          _buildWideServiceCard(
                            context: context,
                            title: isAr ? 'دعاء بظهر الغيب' : 'Dua in Absentia',
                            imageAsset: 'assets/images/clay_3d_loved_ones.png',
                            icon: LucideIcons.heartHandshake,
                            accentColor: const Color(0xFFE11D48),
                            pastelLightStart: const Color(0xFFFFF1F2),
                            pastelLightEnd: const Color(0xFFFECDD3),
                            dark: dark,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LovedOnesScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ─────────────────────────────────────────────
                  // 6. ZAKAT & CHARITIES (الزكاة والصدقات والأضاحي)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildSectionHeader(
                        context,
                        title: isAr ? 'الزكاة والصدقات والأضاحي' : 'Zakat & Charities',
                        dark: dark,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Row 1: [ حاسبة | حاسبة ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'حاسبة' : 'Zakat',
                                  titleLine2: isAr ? 'الزكاة' : 'Calculator',
                                  imageAsset: 'assets/images/clay_3d_zakat_calc.png',
                                  icon: LucideIcons.calculator,
                                  accentColor: const Color(0xFF059669),
                                  pastelLightStart: const Color(0xFFECFDF5),
                                  pastelLightEnd: const Color(0xFFA7F3D0),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 0)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'حاسبة' : 'Nisab',
                                  titleLine2: isAr ? 'النصاب' : 'Calculator',
                                  imageAsset: 'assets/images/clay_3d_nisab.png',
                                  icon: LucideIcons.coins,
                                  accentColor: const Color(0xFFD97706),
                                  pastelLightStart: const Color(0xFFFFFBEB),
                                  pastelLightEnd: const Color(0xFFFDE68A),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 1)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Row 2: [ مستحقو الزكاة | مستحقو الأضحية ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'مستحقو' : 'Zakat',
                                  titleLine2: isAr ? 'الزكاة' : 'Beneficiaries',
                                  imageAsset: 'assets/images/clay_3d_zakat_beneficiaries.png',
                                  icon: LucideIcons.usersRound,
                                  accentColor: const Color(0xFF2563EB),
                                  pastelLightStart: const Color(0xFFEFF6FF),
                                  pastelLightEnd: const Color(0xFFBFDBFE),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'مستحقو' : 'Udhiyah',
                                  titleLine2: isAr ? 'الأضحية' : 'Beneficiaries',
                                  imageAsset: 'assets/images/clay_3d_udhiyah.png',
                                  icon: LucideIcons.gift,
                                  accentColor: const Color(0xFFDC2626),
                                  pastelLightStart: const Color(0xFFFEF2F2),
                                  pastelLightEnd: const Color(0xFFFECACA),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 3)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Row 3: [ أضحية بعد صلاة العيد | أضحية صدقة ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'أضحية بعد' : 'Post-Eid',
                                  titleLine2: isAr ? 'صلاة العيد' : 'Udhiyah',
                                  imageAsset: 'assets/images/clay_3d_udhiyah.png',
                                  icon: LucideIcons.calendarCheck,
                                  accentColor: const Color(0xFFEA580C),
                                  pastelLightStart: const Color(0xFFFFF7ED),
                                  pastelLightEnd: const Color(0xFFFED7AA),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'أضحية' : 'Sadaqa',
                                  titleLine2: isAr ? 'صدقة' : 'Udhiyah',
                                  imageAsset: 'assets/images/clay_3d_udhiyah.png',
                                  icon: LucideIcons.heart,
                                  accentColor: const Color(0xFFDB2777),
                                  pastelLightStart: const Color(0xFFFDF2F8),
                                  pastelLightEnd: const Color(0xFFFBCFE8),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen(initialTabIndex: 3)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ─────────────────────────────────────────────
                  // 7. MUSLIM TOOLS & SERVICES (أدوات وخدمات المسلم)
                  // ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildSectionHeader(
                        context,
                        title: isAr ? 'أدوات وخدمات المسلم' : 'Muslim Tools',
                        dark: dark,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Trio Row: [ بوصلة القبلة | أقرب مسجد | مناسك الحج والعمرة ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'بوصلة القبلة' : 'Qibla Compass',
                                  imageAsset: 'assets/images/tool_qibla_3d.png',
                                  icon: LucideIcons.compass,
                                  accentColor: const Color(0xFF0284C7),
                                  pastelLightStart: const Color(0xFFF0F9FF),
                                  pastelLightEnd: const Color(0xFFBAE6FD),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const QiblaScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'أقرب مسجد' : 'Nearest Mosque',
                                  imageAsset: 'assets/images/clay_3d_minaret.png',
                                  icon: LucideIcons.mapPin,
                                  accentColor: const Color(0xFF059669),
                                  pastelLightStart: const Color(0xFFECFDF5),
                                  pastelLightEnd: const Color(0xFFA7F3D0),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NearestMosquesScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTrioServiceCard(
                                  context: context,
                                  title: isAr ? 'الحج والعمرة' : 'Hajj & Umrah',
                                  imageAsset: 'assets/images/tool_hajj_3d.png',
                                  icon: LucideIcons.landmark,
                                  accentColor: const Color(0xFFD97706),
                                  pastelLightStart: const Color(0xFFFFFBEB),
                                  pastelLightEnd: const Color(0xFFFDE68A),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const HajjUmrahScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Wide Feature Card: Quran Live Radio (Title Only)
                          _buildWideServiceCard(
                            context: context,
                            title: isAr ? 'إذاعة القرآن الكريم — القاهرة' : 'Cairo Quran Live Radio',
                            imageAsset: 'assets/images/clay_3d_radio.png',
                            icon: LucideIcons.radio,
                            accentColor: const Color(0xFFE11D48),
                            pastelLightStart: const Color(0xFFFFF1F2),
                            pastelLightEnd: const Color(0xFFFECDD3),
                            dark: dark,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const QuranRadioScreen()),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 2-Column: [ صيدلية الروح | الالتزام بالصلاة ]
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'صيدلية الروح' : 'Soul Remedy',
                                  titleLine2: isAr ? 'أدعية لكل شعور' : 'Duas for feelings',
                                  imageAsset: 'assets/images/clay_3d_soul.png',
                                  icon: LucideIcons.heart,
                                  accentColor: const Color(0xFF10B981),
                                  pastelLightStart: const Color(0xFFECFDF5),
                                  pastelLightEnd: const Color(0xFFA7F3D0),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SoulRemedyScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactServiceCard(
                                  context: context,
                                  title: isAr ? 'الالتزام بالصلاة' : 'Prayer Tracking',
                                  titleLine2: isAr ? 'متابعة الفرائض والسنن' : 'Obligatory & Sunan tracker',
                                  imageAsset: 'assets/images/clay_3d_minaret.png',
                                  icon: LucideIcons.calendarCheck,
                                  accentColor: const Color(0xFF6366F1),
                                  pastelLightStart: const Color(0xFFEEF2FF),
                                  pastelLightEnd: const Color(0xFFC7D2FE),
                                  dark: dark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PrayerCommitmentScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom padding for navigation bar ensuring last cards are completely visible
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
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

  /// 3D Pastel Claymorphic Icon Badge — Soft dimensional depth with pastel ambiance or 3D Clay Asset
  Widget _build3DPastelIconBadge({
    String? imageAsset,
    IconData? icon,
    required Color accentColor,
    required bool dark,
    double size = 44,
    double iconSize = 22,
    Color? pastelLightStart,
    Color? pastelLightEnd,
  }) {
    if (imageAsset != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          imageAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => Icon(
            icon ?? LucideIcons.sparkles,
            size: iconSize,
            color: dark ? Colors.white : accentColor,
          ),
        ),
      );
    }

    // True 3D pastel claymorphism fallback:
    final bgStart = dark
        ? accentColor.withValues(alpha: 0.35)
        : (pastelLightStart ?? Color.lerp(Colors.white, accentColor, 0.14)!);
    final bgEnd = dark
        ? accentColor.withValues(alpha: 0.14)
        : (pastelLightEnd ?? Color.lerp(Colors.white, accentColor, 0.30)!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.35),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.22) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          // Top-left specular highlight (gives the 3D raised clay feel)
          BoxShadow(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
          // Bottom-right soft dimensional shadow
          BoxShadow(
            color: accentColor.withValues(alpha: dark ? 0.35 : 0.28),
            blurRadius: 10,
            offset: const Offset(3, 4),
          ),
          // Ambient spread shadow
          BoxShadow(
            color: accentColor.withValues(alpha: dark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.70,
          height: size * 0.70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: dark ? 0.07 : 0.45),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.12 : 0.60),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              icon ?? LucideIcons.sparkles,
              size: iconSize,
              color: dark ? Colors.white : accentColor,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: dark ? 0.60 : 0.38),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Adhkar Bento Card (3D Pastel Clay Asset + Tailored Palette)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAdhkarBentoCard({
    required BuildContext context,
    required DhikrCategory category,
    required String title,
    required IconData icon,
    required bool isPrimary,
    required bool dark,
    required bool isAr,
    required VoidCallback onTap,
  }) {
    final progress = context.watch<AppState>().categoryProgress(category);
    final percent = progress.total == 0
        ? 0
        : (progress.completed * 100 / progress.total).round();
    final progressValue = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);
    final isCompleted = progress.total > 0 && progress.completed >= progress.total;

    final (accentColor, pastelStart, pastelEnd, imageAsset) = switch (category) {
      DhikrCategory.morning => (
          dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          'assets/images/clay_3d_morning.png',
        ),
      DhikrCategory.evening => (
          dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
          const Color(0xFFDDD6FE),
          'assets/images/clay_3d_evening.png',
        ),
      DhikrCategory.afterPrayer => (
          dark ? const Color(0xFF34D399) : const Color(0xFF059669),
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          'assets/images/clay_3d_after_prayer.png',
        ),
      DhikrCategory.ruqyah => (
          dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          const Color(0xFFF0F9FF),
          const Color(0xFFBAE6FD),
          'assets/images/clay_3d_ruqyah.png',
        ),
      _ => (
          dark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
          const Color(0xFFF0FDFA),
          const Color(0xFF99F6E4),
          null,
        ),
    };

    final Color surfaceColor = dark
        ? (isPrimary ? const Color(0xFF132A23) : const Color(0xFF10241E))
        : (isPrimary ? Colors.white : const Color(0xFFFCFAF7));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: isPrimary ? 0.14 : 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: 3D Pastel Clay Asset & Completion Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _build3DPastelIconBadge(
                  imageAsset: imageAsset,
                  icon: icon,
                  accentColor: accentColor,
                  dark: dark,
                  size: 64,
                  iconSize: 30,
                  pastelLightStart: pastelStart,
                  pastelLightEnd: pastelEnd,
                ),

                // Percentage Badge / Checkmark
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                        : (dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isCompleted ? 'مكتمل ✓' : '$percent%',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCompleted
                          ? const Color(0xFF34D399)
                          : (dark ? DhikrColors.sage : DhikrColors.charcoalSoft),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title (Centered, bold, title only)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
            ),

            const SizedBox(height: 14),

            // Smooth Rounded Progress Bar matching Category Accent
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 4.5,
                backgroundColor: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Wide Highlight Service Card (Title Only, 3D Clay Asset)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWideServiceCard({
    required BuildContext context,
    required String title,
    String? imageAsset,
    required IconData icon,
    required Color accentColor,
    required bool dark,
    required VoidCallback onTap,
    Color? pastelLightStart,
    Color? pastelLightEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF132A23) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // 3D Pastel Clay Icon
            _build3DPastelIconBadge(
              imageAsset: imageAsset,
              icon: icon,
              accentColor: accentColor,
              dark: dark,
              size: 66,
              iconSize: 30,
              pastelLightStart: pastelLightStart,
              pastelLightEnd: pastelLightEnd,
            ),
            const SizedBox(width: 16),

            // Content (Title Only)
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : DhikrColors.charcoal,
                ),
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronLeft,
              size: 14,
              color: dark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Trio Service Card (Title Only, 3 in a row, 3D Clay Asset)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTrioServiceCard({
    required BuildContext context,
    required String title,
    String? imageAsset,
    required IconData icon,
    required Color accentColor,
    required bool dark,
    required VoidCallback onTap,
    Color? pastelLightStart,
    Color? pastelLightEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF10241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _build3DPastelIconBadge(
              imageAsset: imageAsset,
              icon: icon,
              accentColor: accentColor,
              dark: dark,
              size: 62,
              iconSize: 28,
              pastelLightStart: pastelLightStart,
              pastelLightEnd: pastelLightEnd,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : DhikrColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Compact Service Card (Title Only, 3D Clay Asset)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCompactServiceCard({
    required BuildContext context,
    required String title,
    String? titleLine2,
    String? imageAsset,
    required IconData icon,
    required Color accentColor,
    required bool dark,
    required VoidCallback onTap,
    Color? pastelLightStart,
    Color? pastelLightEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF10241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _build3DPastelIconBadge(
              imageAsset: imageAsset,
              icon: icon,
              accentColor: accentColor,
              dark: dark,
              size: 56,
              iconSize: 26,
              pastelLightStart: pastelLightStart,
              pastelLightEnd: pastelLightEnd,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: titleLine2 != null ? 13.5 : 14.5,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                      height: 1.2,
                    ),
                  ),
                  if (titleLine2 != null) ...[
                    Text(
                      titleLine2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : DhikrColors.charcoal,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
