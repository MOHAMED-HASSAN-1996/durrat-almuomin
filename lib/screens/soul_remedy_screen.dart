import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/soul_remedies_data.dart';
import '../services/arabic_text_utils.dart';
import '../services/remote_content_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// الشاشة الأولى: استعراض صيدلية الروح ودواء القلوب (متوافقة كلياً مع براند درة المؤمن)
// ─────────────────────────────────────────────────────────────────────────────
class SoulRemedyScreen extends StatefulWidget {
  const SoulRemedyScreen({super.key, this.initialFeelingId});

  final String? initialFeelingId;

  @override
  State<SoulRemedyScreen> createState() => _SoulRemedyScreenState();
}

class _SoulRemedyScreenState extends State<SoulRemedyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Set<String> _favorites = {};
  int _todayOpenedCount = 0;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  static const _categories = [
    (key: 'all', titleAr: 'الكل', titleEn: 'All', icon: LucideIcons.layoutGrid),
    (key: 'distress', titleAr: 'هموم وكروب', titleEn: 'Distress', icon: LucideIcons.cloudRain),
    (key: 'peace', titleAr: 'سكينة وأمان', titleEn: 'Peace', icon: LucideIcons.shieldCheck),
    (key: 'faith', titleAr: 'توبة ورجاء', titleEn: 'Repentance', icon: LucideIcons.sparkles),
    (key: 'wellness', titleAr: 'عافية وشفاء', titleEn: 'Healing', icon: LucideIcons.heartPulse),
  ];

  static const _motivationalQuotesAr = [
    '«قَلْبُكَ أَمَانَةٌ عِنْدَ اللَّهِ.. فَاطْمَئِنَّ لِحُسْنِ تَدْبِيرِهِ»',
    '«مَا مِنْ صَعْبٍ يَمُرُّ بِكَ إِلَّا وَفَرَجُ اللَّهِ أَقْرَبُ إِلَيْكَ مِنْ نَفَسِكَ»',
    '«ادْعُونِي أَسْتَجِبْ لَكُمْ.. وَعْدٌ قُرْآنِيٌّ لَا يَخِيبُ»',
    '«إِنَّ مَعَ الْعُسْرِ يُسْراً.. بَشَارَةُ الرَّحْمَنِ لِكُلِّ قَلْبٍ مَكْرُوبٍ»',
    '«قُلْ هُوَ اللَّهُ أَحَدٌ.. وَكَفَى بِاللَّهِ وَكِيلاً وَحَسِيباً»',
    '«اللَّهُمَّ إِنِّي أَسْأَلُكَ صِدْقَ التَّوَكُّلِ عَلَيْكَ وَحُسْنَ الظَّنِّ بِكَ»',
    '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ.. بَلْسَمُ كُلِّ حَيْرَةٍ وَأَلَمٍ»',
  ];

  static const _motivationalQuotesEn = [
    'Your heart is a sacred trust with Allah — rest assured in His wise plan.',
    'No hardship strikes you except that Allah\'s relief is closer than your breath.',
    '"Call upon Me; I will respond to you" — a divine promise that never fails.',
    '"Indeed, with hardship comes ease" — the Merciful\'s guarantee to every tired soul.',
    'Say: "He is Allah, the One" — and suffice with Allah as your ultimate Guardian.',
    'O Allah, we ask You for sincere reliance and beautiful thoughts of You.',
    '"Truly, in the remembrance of Allah do hearts find peace."',
  ];

  String _randomQuote = '';
  String _randomQuoteEn = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    final rng = Random();
    _randomQuote = _motivationalQuotesAr[rng.nextInt(_motivationalQuotesAr.length)];
    _randomQuoteEn = _motivationalQuotesEn[rng.nextInt(_motivationalQuotesEn.length)];

    _loadFavorites();
    _loadTodayCount();
    RemoteContentService.instance.initialize();
    RemoteContentService.instance.addListener(_onRemoteContent);

    // إذا تم تمرير معرف أولي، نفتح تفاصيله مباشرة
    if (widget.initialFeelingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final match = _allRemedies.where((r) => r.id == widget.initialFeelingId);
        if (match.isNotEmpty && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SoulRemedyDetailScreen(
                remedy: match.first,
                onFavoriteToggle: _toggleFavorite,
                isFavorite: _favorites.contains(match.first.id),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    RemoteContentService.instance.removeListener(_onRemoteContent);
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onRemoteContent() {
    if (mounted) setState(() {});
  }

  /// Local feelings merged with admin-managed remote ones by id, so the
  /// dashboard can edit any feeling (remote version wins) or add new ones.
  List<SoulRemedy> get _allRemedies {
    final byId = <String, SoulRemedy>{
      for (final r in soulRemediesList) r.id: r,
      for (final r in RemoteContentService.instance.remoteSoulRemedies)
        r.id: r,
    };
    return byId.values.toList();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favorites = (prefs.getStringList('soul_remedy_favorites') ?? []).toSet();
      });
    }
  }

  Future<void> _loadTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('soul_remedy_count_date') ?? '';
    if (mounted) {
      if (savedDate == today) {
        setState(() => _todayOpenedCount = prefs.getInt('soul_remedy_count') ?? 0);
      } else {
        setState(() => _todayOpenedCount = 0);
      }
    }
  }

  Future<void> _incrementTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('soul_remedy_count_date') ?? '';
    if (savedDate == today) {
      _todayOpenedCount++;
    } else {
      _todayOpenedCount = 1;
    }
    await prefs.setString('soul_remedy_count_date', today);
    await prefs.setInt('soul_remedy_count', _todayOpenedCount);
    if (mounted) setState(() {});
  }

  void _toggleFavorite(String remedyId, bool currentState) {
    setState(() {
      if (currentState) {
        _favorites.remove(remedyId);
      } else {
        _favorites.add(remedyId);
      }
    });
    _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('soul_remedy_favorites', _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // تصفية الحالات حسب التصنيف والبحث
    final filteredRemedies = _allRemedies.where((remedy) {
      final matchCategory = _selectedCategory == 'all' || remedy.categoryKey == _selectedCategory;
      if (!matchCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final feeling = (isAr ? remedy.feelingAr : remedy.feelingEn).toLowerCase();
      final desc = remedy.descriptionAr.toLowerCase();
      final sub = remedy.subtitleAr.toLowerCase();
      return feeling.contains(q) || desc.contains(q) || sub.contains(q);
    }).toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF101D17) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: isAr ? 'رجوع' : 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isAr ? 'صيدلية الروح' : 'Soul Sanctuary',
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 18.5,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.info, size: 20),
              tooltip: isAr ? 'عن صيدلية الروح' : 'About Soul Sanctuary',
              onPressed: () => _showAboutDialog(context, isAr, dark),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                children: [
                  // ─────────────────────────────────────────────
                  // 1. HERO HEADER (RonDesignLab 28px glass card with 3D Soul Asset)
                  // ─────────────────────────────────────────────
                  _buildHeroHeader(isAr, dark),
                  const SizedBox(height: 14),

                  // ─────────────────────────────────────────────
                  // 2. DAILY HEALING TRACKER (إذا فُتحت حالات اليوم)
                  // ─────────────────────────────────────────────
                  if (_todayOpenedCount > 0) ...[
                    _buildTodayTracker(isAr, dark),
                    const SizedBox(height: 12),
                  ],

                  // ─────────────────────────────────────────────
                  // 3. SEARCH BAR
                  // ─────────────────────────────────────────────
                  _buildSearchBar(isAr, dark),
                  const SizedBox(height: 10),

                  // ─────────────────────────────────────────────
                  // 4. CATEGORY FILTER CHIPS
                  // ─────────────────────────────────────────────
                  _buildCategoryChips(isAr, dark),
                  const SizedBox(height: 16),

                  // ─────────────────────────────────────────────
                  // 5. FAVORITES CAROUSEL (إن وُجدت)
                  // ─────────────────────────────────────────────
                  if (_favorites.isNotEmpty) ...[
                    _buildSectionTitle(
                      title: isAr ? 'الحالات المحفوظة في المفضلة' : 'Favorite Remedies',
                      icon: LucideIcons.heart,
                      color: const Color(0xFFC44558),
                      dark: dark,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: _allRemedies
                            .where((r) => _favorites.contains(r.id))
                            .map((r) => _buildFavoritePill(context, r, isAr, dark))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ─────────────────────────────────────────────
                  // 6. REMEDIES GRID
                  // ─────────────────────────────────────────────
                  _buildSectionTitle(
                    title: isAr ? 'أدوية القلوب ومواضع السكينة' : 'Heart Remedies',
                    icon: LucideIcons.sparkles,
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),

                  if (filteredRemedies.isEmpty)
                    _buildEmptyState(isAr, dark)
                  else
                    _buildRemediesGrid(filteredRemedies, isAr, dark),

                  // ─────────────────────────────────────────────
                  // 7. BOTTOM SPIRITUAL QUOTE (Dhikr Brand Aesthetic)
                  // ─────────────────────────────────────────────
                  const SizedBox(height: 24),
                  _buildBottomQuoteCard(isAr, dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Hero Header ──
  Widget _buildHeroHeader(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF13241E), const Color(0xFF0B1612)]
              : [const Color(0xFFEBF3EE), const Color(0xFFDFEDE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark
              ? DhikrColors.forestLight.withValues(alpha: 0.25)
              : DhikrColors.forest.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black26 : DhikrColors.forest.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dark
                        ? DhikrColors.forestLight.withValues(alpha: 0.2)
                        : DhikrColors.forest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.heartHandshake,
                        size: 13,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'دواء القلوب ونور الصدور' : 'HEALING & TRANQUILITY',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: dark ? DhikrColors.sage : DhikrColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? 'بماذا يشعر قلبك اليوم؟' : 'How does your heart feel today?',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: dark ? Colors.white : DhikrColors.charcoal,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'اختر ما يمر به قلبك لتجد بلسم القرآن وهدي الحبيب ﷺ'
                      : 'Find Quranic healing & prophetic solace for your state',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12,
                    height: 1.45,
                    color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DhikrColors.sandDeep.withValues(alpha: dark ? 0.2 : 0.35),
                    ),
                  ),
                  child: Text(
                    isAr
                        ? '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾'
                        : '“In the remembrance of Allah do hearts find rest”',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dark ? DhikrColors.sand : DhikrColors.forestDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // المجسم ثلاثي الأبعاد الرسمي للروح مع نبض رقيق
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: SizedBox(
              width: 96,
              height: 96,
              child: Image.asset(
                'assets/images/clay_3d_soul.webp',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DhikrColors.forest.withValues(alpha: 0.15),
                  ),
                  child: const Icon(LucideIcons.heart, size: 40, color: DhikrColors.forest),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Daily Healing Tracker ──
  Widget _buildTodayTracker(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? DhikrColors.forestDeep.withValues(alpha: 0.4)
            : DhikrColors.sageSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? DhikrColors.sage.withValues(alpha: 0.2)
              : DhikrColors.forestLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.sparkle,
            size: 16,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? 'فتحت اليوم $_todayOpenedCount حالات • جعل الله قلوبكم عامرة بالسكينة'
                  : 'Explored $_todayOpenedCount soul remedies today • May Allah grant you peace',
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
    );
  }

  // ── 3. Search Bar ──
  Widget _buildSearchBar(bool isAr, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14211B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 13.5,
          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
        ),
        decoration: InputDecoration(
          hintText: isAr ? 'ابحث عما تشعر به (حزن، قلق، حيرة، كرب...)' : 'Search how you feel...',
          hintStyle: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 13,
            color: dark ? DhikrColors.darkMuted : Colors.grey[500],
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: dark ? DhikrColors.sage : DhikrColors.forest,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── 4. Category Chips ──
  Widget _buildCategoryChips(bool isAr, bool dark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat.key;
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat.key);
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (dark ? DhikrColors.forestLight : DhikrColors.forest)
                    : (dark ? const Color(0xFF14211B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : DhikrColors.charcoal.withValues(alpha: 0.08)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: DhikrColors.forest.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : (dark ? DhikrColors.sage : DhikrColors.charcoalSoft),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? cat.titleAr : cat.titleEn,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
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

  // ── 5. Favorite Pill ──
  Widget _buildFavoritePill(BuildContext context, SoulRemedy remedy, bool isAr, bool dark) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _navigateToDetail(context, remedy);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: dark
                  ? remedy.accentColor.withValues(alpha: 0.18)
                  : remedy.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: remedy.accentColor.withValues(alpha: dark ? 0.35 : 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(remedy.iconData, size: 16, color: remedy.accentColor),
                const SizedBox(width: 8),
                Text(
                  isAr ? remedy.feelingAr : remedy.feelingEn,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : remedy.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 6. Remedies Grid ──
  // شبكة من عمودين تتناسب مع حجم المحتوى الفعلي (بدون فراغات رأسية زائدة)
  // كل صف متساوي الارتفاع تماماً، والمسافات بين الصفوف والبطاقات موحدة (12).
  Widget _buildRemediesGrid(List<SoulRemedy> remedies, bool isAr, bool dark) {
    const double gutter = 12;
    final rows = <Widget>[];

    for (var start = 0; start < remedies.length; start += 2) {
      final hasSecond = start + 1 < remedies.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildAnimatedRemedyCard(remedies[start], start, isAr, dark),
              ),
              const SizedBox(width: gutter),
              if (hasSecond)
                Expanded(
                  child: _buildAnimatedRemedyCard(remedies[start + 1], start + 1, isAr, dark),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );

      if (hasSecond) rows.add(const SizedBox(height: gutter));
    }

    return Column(children: rows);
  }

  // غلاف الحركة (تلاشي + انزلاق لطيف) لكل بطاقة دواء
  Widget _buildAnimatedRemedyCard(
    SoulRemedy remedy,
    int index,
    bool isAr,
    bool dark,
  ) {
    final delay = (index * 0.06).clamp(0.0, 0.4);
    final animValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: animValue,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animValue),
        child: _buildRemedyCard(context, remedy, isAr, dark),
      ),
    );
  }

  // ── 6. Remedy Grid Card ──
  Widget _buildRemedyCard(
    BuildContext context,
    SoulRemedy remedy,
    bool isAr,
    bool dark,
  ) {
    final feelingName = isAr
        ? ArabicTextUtils.stripTashkeel(remedy.feelingAr)
        : remedy.feelingEn;
    final subtitleName = isAr
        ? ArabicTextUtils.stripTashkeel(
            remedy.subtitleAr.isNotEmpty
                ? remedy.subtitleAr
                : remedy.descriptionAr)
        : remedy.descriptionAr;
    final isFav = _favorites.contains(remedy.id);
    final accent = remedy.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          await _incrementTodayCount();
          if (context.mounted) {
            _navigateToDetail(context, remedy);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF131F19) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark
                  ? accent.withValues(alpha: 0.28)
                  : const Color(0xFFE7DED5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.12 : 0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── المجموعة العليا: الأيقونة + النصوص بمسافات ثابتة ──
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: 'remedy_icon_${remedy.id}',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: dark ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: dark ? 0.35 : 0.22),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              remedy.iconData,
                              size: 20,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _toggleFavorite(remedy.id, isFav);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: isFav
                                ? const Color(0xFFE11D48)
                                : (dark ? DhikrColors.darkMuted : Colors.grey[400]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    feelingName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.3,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
                ],
              ),
              // ── الشارة السفلية: ملتصقة بأسفل البطاقة بمسافة ثابتة (10) ──
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: dark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bookOpen, size: 11, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        isAr
                            ? '${remedy.ayahs.length} آيات • ${remedy.duas.length} أدعية'
                            : '${remedy.ayahs.length} Ayahs • ${remedy.duas.length} Duas',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, SoulRemedy remedy) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, animation, secondaryAnimation) => SoulRemedyDetailScreen(
          remedy: remedy,
          onFavoriteToggle: _toggleFavorite,
          isFavorite: _favorites.contains(remedy.id),
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ── 7. Bottom Spiritual Quote ──
  Widget _buildBottomQuoteCard(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF131E18) : const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? DhikrColors.forestLight.withValues(alpha: 0.2)
              : DhikrColors.forest.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dark
                  ? DhikrColors.forestLight.withValues(alpha: 0.2)
                  : DhikrColors.forest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.quote,
              size: 18,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'نَفَحَاتٌ لِطُمَأْنِينَةِ رُوحِكَ' : 'SPIRITUAL REMINDER',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? _randomQuote : _randomQuoteEn,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.55,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            isAr ? 'لم نجد حالات تطابق بحثك' : 'No remedies matching your search',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isAr, bool dark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF14211B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.heartHandshake, color: DhikrColors.forest, size: 22),
            const SizedBox(width: 8),
            Text(
              isAr ? 'صيدلية الروح' : 'About Soul Sanctuary',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'صيدلية الروح ودواء القلوب مبوبة خصيصاً لمداواة ما يمر به المسلم من مشاعر كالحزن، والقلق، والكرب، والندم، والحيرة.\n\nتجمع لك أصح الآيات القرآنية والأدعية النبوية والخواطر الإيمانية لتكون بلسماً وسكينة لقلبك في كل حين.'
              : 'Soul Sanctuary provides authentic Quranic verses, prophetic supplications, and comforting reminders for every emotional state.',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 13.5,
            height: 1.6,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAr ? 'حسناً' : 'OK',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                color: DhikrColors.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// الشاشة الثانية: صفحة تفاصيل الوصفة الروحية (البلسم القرآني + الدواء النبوي + همسات القلب)
// ─────────────────────────────────────────────────────────────────────────────
class SoulRemedyDetailScreen extends StatefulWidget {
  const SoulRemedyDetailScreen({
    super.key,
    required this.remedy,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  final SoulRemedy remedy;
  final void Function(String id, bool currentState)? onFavoriteToggle;
  final bool isFavorite;

  @override
  State<SoulRemedyDetailScreen> createState() => _SoulRemedyDetailScreenState();
}

class _SoulRemedyDetailScreenState extends State<SoulRemedyDetailScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, int> _duaCounts = {};
  bool _isFavorite = false;
  final double _fontSizeDelta = 0.0;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _incrementDua(String duaKey, int target) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _duaCounts[duaKey] ?? 0;
      final next = current >= target ? target : current + 1;
      _duaCounts[duaKey] = next;

      if (next == target) {
        HapticFeedback.mediumImpact();
        AppToast.show(context, 
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أتممت هذا الذكر المبارك.. تقبل الله وطمأن قلبك',
                    style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                  ),
                ),
              ],
            ),
            backgroundColor: DhikrColors.forest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _resetDua(String duaKey) {
    HapticFeedback.selectionClick();
    setState(() {
      _duaCounts[duaKey] = 0;
    });
  }

  void _shareRemedy(bool isAr) {
    HapticFeedback.selectionClick();
    final r = widget.remedy;

    final buffer = StringBuffer();
    buffer.writeln(isAr
        ? '«صَيْدَلِيَّةُ الرُّوحِ — دَوَاءُ ${r.feelingAr}» 🌿'
        : '«Soul Sanctuary — Remedy for ${r.feelingEn}» 🌿');
    if (r.subtitleAr.isNotEmpty) {
      buffer.writeln(r.subtitleAr);
    }
    buffer.writeln();

    buffer.writeln(isAr ? '📖 البلسم القرآني الشافي:' : '📖 Quranic Solace:');
    for (final a in r.ayahs) {
      buffer.writeln('${a.ayah} [${a.surah}]');
    }
    buffer.writeln();

    buffer.writeln(isAr ? '🤲 الدواء النبوي المأثور:' : '🤲 Prophetic Duas:');
    for (final d in r.duas) {
      buffer.writeln('«${d.dua}»');
      buffer.writeln('المصدر: ${d.source} (يكرر ${d.repeat} مرات)');
    }
    buffer.writeln();

    buffer.writeln(isAr ? '🕊️ همسات لراحة قلبك:' : '🕊️ Heart Solace:');
    for (final p in (isAr ? r.solacePointsAr : r.solacePointsEn)) {
      buffer.writeln('• $p');
    }
    buffer.writeln();
    buffer.writeln('— من تطبيق درة المؤمن');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppToast.show(context, 
      SnackBar(
        content: Text(
          isAr ? 'تم نسخ بطاقة العلاج للمشاركة بنجاح ✓' : 'Remedy card copied to share ✓',
          style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.remedy;
    final accent = r.accentColor;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF101D17) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: isAr ? 'رجوع' : 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'remedy_icon_${r.id}',
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(r.iconData, size: 17, color: accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isAr ? 'دواء ${r.feelingAr}' : 'Remedy for ${r.feelingEn}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: isAr ? (_isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة') : 'Favorite',
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? const Color(0xFFE11D48) : (dark ? Colors.white70 : Colors.grey),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isFavorite = !_isFavorite);
                widget.onFavoriteToggle?.call(r.id, !_isFavorite);
              },
            ),
            IconButton(
              tooltip: isAr ? 'مشاركة الوصفة' : 'Share Remedy',
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: () => _shareRemedy(isAr),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  // ─────────────────────────────────────────────
                  // 1. TOP REMEDY OVERVIEW BANNER
                  // ─────────────────────────────────────────────
                  _buildRemedyOverviewBanner(r, isAr, dark),
                  const SizedBox(height: 18),

                  // ─────────────────────────────────────────────
                  // 2. البلسم القرآني (الآيات الشافية)
                  // ─────────────────────────────────────────────
                  _buildAnimatedSection(
                    index: 0,
                    child: _buildSectionHeader(
                      title: isAr ? 'البلسم القرآني (الآيات الشافية)' : 'Quranic Solace',
                      icon: LucideIcons.bookOpen,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                      countBadge: '${r.ayahs.length}',
                      dark: dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...r.ayahs.asMap().entries.map((entry) {
                    return _buildAnimatedSection(
                      index: entry.key + 1,
                      child: _buildAyahCard(entry.value, isAr, dark, accent),
                    );
                  }),
                  const SizedBox(height: 22),

                  // ─────────────────────────────────────────────
                  // 3. الدواء النبوي (الأدعية المأثورة والسنن)
                  // ─────────────────────────────────────────────
                  _buildAnimatedSection(
                    index: r.ayahs.length + 1,
                    child: _buildSectionHeader(
                      title: isAr ? 'الدواء النبوي (الأدعية المأثورة)' : 'Prophetic Duas',
                      icon: LucideIcons.sparkles,
                      color: const Color(0xFF9E7132),
                      countBadge: '${r.duas.length}',
                      dark: dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...r.duas.asMap().entries.map((entry) {
                    return _buildAnimatedSection(
                      index: r.ayahs.length + entry.key + 2,
                      child: _buildDuaCard(entry.value, isAr, dark, accent),
                    );
                  }),
                  const SizedBox(height: 22),

                  // ─────────────────────────────────────────────
                  // 4. همسات لراحة قلبك
                  // ─────────────────────────────────────────────
                  _buildAnimatedSection(
                    index: r.ayahs.length + r.duas.length + 2,
                    child: _buildSectionHeader(
                      title: isAr ? 'همسات لراحة قلبك وعقلك' : 'Heart Solace & Reminders',
                      icon: LucideIcons.heartHandshake,
                      color: dark ? DhikrColors.sand : const Color(0xFF6B4E71),
                      countBadge: '${r.solacePointsAr.length}',
                      dark: dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSolaceCard(r, isAr, dark),

                  // ─────────────────────────────────────────────
                  // 5. زر مشاركة البطاقة كاملة
                  // ─────────────────────────────────────────────
                  const SizedBox(height: 24),
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _shareRemedy(isAr),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DhikrColors.forest,
                                DhikrColors.forestDeep,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: DhikrColors.forest.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'مشاركة بطاقة صيدلية الروح كاملة' : 'Share Complete Remedy Card',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final delay = (index * 0.05).clamp(0.0, 0.5);
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, _) {
        final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          ),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
    );
  }

  // ── 1. Remedy Overview Banner ──
  Widget _buildRemedyOverviewBanner(SoulRemedy r, bool isAr, bool dark) {
    final accent = r.accentColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14211B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: dark ? 0.35 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.12 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: dark ? 0.25 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Icon(r.iconData, size: 24, color: accent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAr ? r.feelingAr : r.feelingEn,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                    ),
                    if (r.subtitleAr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.subtitleAr,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  r.descriptionAr,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    height: 1.45,
                    color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Section Header ──
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required String countBadge,
    required bool dark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            countBadge,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Ayah Card (Mushaf Parchment Brand Aesthetic) ──
  Widget _buildAyahCard(QuranAyahItem item, bool isAr, bool dark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF131F19) : const Color(0xFFFCFBF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark
              ? DhikrColors.forestLight.withValues(alpha: 0.28)
              : DhikrColors.sandDeep.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dark
                      ? DhikrColors.forestLight.withValues(alpha: 0.2)
                      : DhikrColors.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dark
                        ? DhikrColors.forestLight.withValues(alpha: 0.3)
                        : DhikrColors.forest.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.bookmark,
                      size: 11,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.surah,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: dark ? DhikrColors.sage : DhikrColors.forest,
                tooltip: isAr ? 'نسخ الآية' : 'Copy Ayah',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: '${item.ayah} [${item.surah}]'));
                  AppToast.show(context, 
                    SnackBar(
                      content: Text(
                        isAr ? 'تم نسخ الآية الكريمة ✓' : 'Ayah copied ✓',
                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.ayah,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 18.5 + _fontSizeDelta,
              height: 2.0,
              fontWeight: FontWeight.w700,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          if (item.translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12 + _fontSizeDelta * 0.5,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Dua Card (With Dhikr Counter) ──
  Widget _buildDuaCard(PropheticDuaItem item, bool isAr, bool dark, Color accent) {
    final count = _duaCounts[item.dua] ?? 0;
    final isDone = count >= item.targetRepeat;
    final progress = item.targetRepeat > 0 ? count / item.targetRepeat : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14211B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone
              ? DhikrColors.forest
              : (dark
                  ? const Color(0xFF9E7132).withValues(alpha: 0.3)
                  : const Color(0xFF9E7132).withValues(alpha: 0.2)),
          width: isDone ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9E7132).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.check, size: 11, color: Color(0xFF9E7132)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.source,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: Color(0xFF9E7132),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (count > 0)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: dark ? DhikrColors.darkMuted : Colors.grey[600],
                  tooltip: isAr ? 'إعادة ضبط العداد' : 'Reset Counter',
                  onPressed: () => _resetDua(item.dua),
                ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: dark ? DhikrColors.sage : DhikrColors.forest,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: '«${item.dua}» [${item.source}]'));
                  AppToast.show(context, 
                    SnackBar(
                      content: Text(
                        isAr ? 'تم نسخ الدعاء المبارك ✓' : 'Dua copied ✓',
                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '«${item.dua}»',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 16.5 + _fontSizeDelta,
              height: 1.85,
              fontWeight: FontWeight.w800,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // شريط تقدم العداد بأسلوب براند ذِكْر
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? DhikrColors.forest : const Color(0xFF9E7132),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // زر العداد التفاعلي (Modern Brand Tap Counter)
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _incrementDua(item.dua, item.targetRepeat),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDone
                          ? [DhikrColors.forest, DhikrColors.forestLight]
                          : dark
                              ? [const Color(0xFF28241C), const Color(0xFF1F1C15)]
                              : [const Color(0xFFF9F5EC), const Color(0xFFF2ECE0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone
                          ? DhikrColors.forest
                          : (dark
                              ? const Color(0xFF9E7132).withValues(alpha: 0.3)
                              : const Color(0xFF9E7132).withValues(alpha: 0.25)),
                    ),
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: DhikrColors.forest.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isDone ? Icons.check_circle_rounded : LucideIcons.fingerprint,
                          key: ValueKey(isDone),
                          size: 18,
                          color: isDone ? Colors.white : const Color(0xFF9E7132),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDone
                            ? (isAr ? 'تم الذكر بحمد الله ($count/${item.targetRepeat})' : 'Completed ($count/${item.targetRepeat})')
                            : (isAr
                                ? 'اضغط للذكر: $count من ${item.targetRepeat}'
                                : 'Tap to Count: $count of ${item.targetRepeat}'),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDone ? Colors.white : (dark ? DhikrColors.sand : const Color(0xFF805622)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Solace Card (همسات السكينة وطب القلوب) ──
  Widget _buildSolaceCard(SoulRemedy remedy, bool isAr, bool dark) {
    final points = isAr ? remedy.solacePointsAr : remedy.solacePointsEn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF131E18) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark
              ? DhikrColors.forestLight.withValues(alpha: 0.25)
              : DhikrColors.forest.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: dark
                        ? DhikrColors.forestLight.withValues(alpha: 0.25)
                        : DhikrColors.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dark
                          ? DhikrColors.sage.withValues(alpha: 0.3)
                          : DhikrColors.forestLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13.5,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
