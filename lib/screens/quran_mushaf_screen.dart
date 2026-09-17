import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../data/quran_surahs.dart';
import '../services/quran_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

enum MushafThemeMode {
  cream,
  sepia,
  dark,
}

/// شاشة قراءة القرآن الكريم — مصممة لتملأ الشاشة بالكامل
/// بدون أي تجاوز أو خروج عن الحدود، وسكرول أفقي فقط (يمين لليسار)
class QuranMushafScreen extends StatefulWidget {
  const QuranMushafScreen({
    super.key,
    this.initialPage,
  });

  final int? initialPage;

  @override
  State<QuranMushafScreen> createState() => _QuranMushafScreenState();
}

class _QuranMushafScreenState extends State<QuranMushafScreen> {
  late PageController _horizontalPageController;
  late final ValueNotifier<int> _currentPageNotifier;
  bool _isLandscape = false;
  MushafThemeMode _themeMode = MushafThemeMode.cream;
  bool _isReady = false;
  int? _savedBookmarkPage;
  bool _barsVisible = true;

  @override
  void initState() {
    super.initState();
    final startPage = (widget.initialPage ?? 1).clamp(1, 604);
    _currentPageNotifier = ValueNotifier<int>(startPage);
    _horizontalPageController = PageController(initialPage: startPage - 1);

    _initStartingPage();
  }

  Future<void> _initStartingPage() async {
    _savedBookmarkPage = await QuranService.instance.getBookmark();

    if (widget.initialPage == null) {
      final lastRead = await QuranService.instance.getLastRead();
      if (lastRead != null && mounted) {
        final p = (lastRead['page'] as int? ?? 1).clamp(1, 604);
        _currentPageNotifier.value = p;
        _horizontalPageController.dispose();
        _horizontalPageController = PageController(initialPage: p - 1);
      }
    }
    _saveProgress(_currentPageNotifier.value);
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    _horizontalPageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  void _saveProgress(int page) {
    final sMeta = getSurahForPage(page);
    QuranService.instance.saveLastRead(
      surahNumber: sMeta.number,
      page: page,
      surahName: sMeta.name,
    );
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, 604);
    _currentPageNotifier.value = clamped;
    if (_horizontalPageController.hasClients) {
      _horizontalPageController.jumpToPage(clamped - 1);
    }
    _saveProgress(clamped);
  }

  void _toggleLandscape() {
    HapticFeedback.selectionClick();
    setState(() => _isLandscape = !_isLandscape);
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _setTheme(MushafThemeMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _themeMode = mode);
  }

  void _showQuranSearchSheet(BuildContext context, bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _barBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _QuranSearchBottomSheet(
          themeMode: _themeMode,
          isAr: isAr,
          onSelectPage: (p) {
            Navigator.pop(ctx);
            _jumpToPage(p);
          },
        );
      },
    );
  }

  Future<void> _toggleBookmark(int page) async {
    HapticFeedback.mediumImpact();
    await QuranService.instance.saveBookmark(page);
    if (mounted) {
      setState(() => _savedBookmarkPage = page);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ صفحة ${_toArabicNum(page)} كعلامة مرجعية',
            style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  QcfThemeData _buildQcfTheme({
    required bool isPortrait,
    required double headerWidth,
  }) {
    final double hPadding = isPortrait ? 12.0 : 20.0;
    final double vPadding = isPortrait ? 10.0 : 6.0;
    final double vHeight = isPortrait ? 2.2 : 4.0;
    final double vNumHeight = isPortrait ? 1.35 : 1.35;
    const double basmalaSize = 24.0;
    const double headerSize = 29.0;

    switch (_themeMode) {
      case MushafThemeMode.cream:
        return QcfThemeData(
          pageBackgroundColor: const Color(0xFFFCFAF5),
          verseTextColor: const Color(0xFF1B241E),
          verseNumberColor: const Color(0xFF8B4513),
          headerTextColor: const Color(0xFF1B241E),
          basmalaColor: const Color(0xFF1B241E),
          verseHeight: vHeight,
          verseNumberHeight: vNumHeight,
          horizontalPadding: hPadding,
          verticalPadding: vPadding,
          basmalaFontSizeSmall: basmalaSize,
          headerFontSizeSmall: headerSize,
          headerWidthSmall: headerWidth,
        );
      case MushafThemeMode.sepia:
        return QcfThemeData(
          pageBackgroundColor: const Color(0xFFF5E6D3),
          verseTextColor: const Color(0xFF3E2723),
          verseNumberColor: const Color(0xFF6D4C41),
          headerTextColor: const Color(0xFF3E2723),
          basmalaColor: const Color(0xFF3E2723),
          verseHeight: vHeight,
          verseNumberHeight: vNumHeight,
          horizontalPadding: hPadding,
          verticalPadding: vPadding,
          basmalaFontSizeSmall: basmalaSize,
          headerFontSizeSmall: headerSize,
          headerWidthSmall: headerWidth,
        );
      case MushafThemeMode.dark:
        return QcfThemeData(
          pageBackgroundColor: const Color(0xFF141715),
          verseTextColor: const Color(0xFFEDEAE4),
          verseNumberColor: const Color(0xFFFBBF24),
          headerTextColor: const Color(0xFFFBBF24),
          headerImageFilter: const ColorFilter.matrix(<double>[
            -1.0, 0.0, 0.0, 0.0, 255.0,
            0.0, -0.9, 0.0, 0.0, 230.0,
            0.0, 0.0, -0.7, 0.0, 185.0,
            0.0, 0.0, 0.0, 1.0, 0.0,
          ]),
          basmalaColor: const Color(0xFFEDEAE4),
          verseHeight: vHeight,
          verseNumberHeight: vNumHeight,
          horizontalPadding: hPadding,
          verticalPadding: vPadding,
          basmalaFontSizeSmall: basmalaSize,
          headerFontSizeSmall: headerSize,
          headerWidthSmall: headerWidth,
        );
    }
  }

  Color get _pageBgColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFFFCFAF5),
        MushafThemeMode.sepia => const Color(0xFFF5E6D3),
        MushafThemeMode.dark => const Color(0xFF141715),
      };

  Color get _barBgColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFFF6F3EB),
        MushafThemeMode.sepia => const Color(0xFFEDE0CB),
        MushafThemeMode.dark => const Color(0xFF1C211E),
      };

  Color get _dividerColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFFE5DECF),
        MushafThemeMode.sepia => const Color(0xFFDECFB8),
        MushafThemeMode.dark => const Color(0xFF2C342F),
      };

  Color get _textColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFF1B241E),
        MushafThemeMode.sepia => const Color(0xFF3E2723),
        MushafThemeMode.dark => const Color(0xFFEDEAE4),
      };

  Color get _mutedTextColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFF5A665E),
        MushafThemeMode.sepia => const Color(0xFF6D4C41),
        MushafThemeMode.dark => const Color(0xFF9EABA2),
      };

  Color get _accentColor => switch (_themeMode) {
        MushafThemeMode.cream => const Color(0xFF0F766E),
        MushafThemeMode.sepia => const Color(0xFF8D6E63),
        MushafThemeMode.dark => const Color(0xFF34D399),
      };

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  void _showSurahIndexSheet(BuildContext context, bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _barBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _QuranIndexBottomSheet(
          currentPage: _currentPageNotifier.value,
          bookmarkPage: _savedBookmarkPage,
          themeMode: _themeMode,
          isAr: isAr,
          onSelectPage: (p) {
            Navigator.pop(ctx);
            _jumpToPage(p);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final isDarkTheme = _themeMode == MushafThemeMode.dark;

    if (!_isReady) {
      return Scaffold(
        backgroundColor: _pageBgColor,
        body: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _pageBgColor,
        body: Stack(
          children: [
            // ──── Fullscreen Mushaf Page (Edge-to-edge, zero inner padding) ────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _barsVisible = !_barsVisible),
                child: SafeArea(
                  child: Container(
                    color: _pageBgColor,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double availableW = constraints.maxWidth;
                        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                        final double spScale = isPortrait
                            ? (availableW / 390.0).clamp(0.92, 1.15)
                            : 1.0;
                        final double headerWidth = (availableW - 24.0).clamp(280.0, 372.0);
                        final qcfTheme = _buildQcfTheme(
                          isPortrait: isPortrait,
                          headerWidth: headerWidth,
                        );

                        return ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(
                            physics: const ClampingScrollPhysics(),
                            scrollbars: false,
                          ),
                          child: PageviewQuran(
                            controller: _horizontalPageController,
                            initialPageNumber: _currentPageNotifier.value,
                            physics: const BouncingScrollPhysics(),
                            sp: spScale,
                            h: 1.0,
                            theme: qcfTheme,
                            onPageChanged: (page) {
                              _currentPageNotifier.value = page;
                              _saveProgress(page);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ──── Floating Top Bar (Overlaid on top of the text) ────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              top: _barsVisible ? 0 : -180,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _barsVisible ? 1.0 : 0.0,
                child: SafeArea(
                  bottom: false,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, page, _) {
                      final currentSurah = getSurahForPage(page);
                      final isBookmarked = _savedBookmarkPage == page;

                      return Container(
                        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _barBgColor.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _dividerColor.withValues(alpha: 0.8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkTheme ? 0.45 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1: Back, Surah Info, Search, Bookmark
                            Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _dividerColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showSurahIndexSheet(context, isAr),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'سُورَةُ ${currentSurah.name}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: DhikrTheme.arabicFont,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16.5,
                                                    color: _textColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _mutedTextColor),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'صفحة ${_toArabicNum(page)} / ٦٠٤',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: DhikrTheme.arabicFont,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: _mutedTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showQuranSearchSheet(context, isAr),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _dividerColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.search_rounded, size: 20, color: _textColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _toggleBookmark(page),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isBookmarked
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                            : _dividerColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                        border: isBookmarked
                                            ? Border.all(color: const Color(0xFFF59E0B), width: 1.2)
                                            : null,
                                      ),
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        size: 20,
                                        color: isBookmarked ? const Color(0xFFD97706) : _textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Divider(height: 1, color: _dividerColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),

                            // Row 2: Theme Swatches & Display Mode Label + Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Theme swatches (مظهر المصحف)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildThemeCircle(
                                      mode: MushafThemeMode.cream,
                                      color: const Color(0xFFFCFAF5),
                                      borderColor: const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildThemeCircle(
                                      mode: MushafThemeMode.sepia,
                                      color: const Color(0xFFF5E6D3),
                                      borderColor: const Color(0xFF8D6E63),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildThemeCircle(
                                      mode: MushafThemeMode.dark,
                                      color: const Color(0xFF141715),
                                      borderColor: const Color(0xFF34D399),
                                    ),
                                  ],
                                ),

                                // Display Mode (طريقة العرض : [ أفقي / رأسي ])
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAr ? 'طريقة العرض :' : 'Display Mode:',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _mutedTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _toggleLandscape,
                                        borderRadius: BorderRadius.circular(10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _accentColor.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: _accentColor.withValues(alpha: 0.4), width: 1.0),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isLandscape
                                                    ? Icons.stay_current_portrait_rounded
                                                    : Icons.stay_current_landscape_rounded,
                                                size: 16,
                                                color: _accentColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                isAr
                                                    ? (_isLandscape ? 'رأسي' : 'أفقي')
                                                    : (_isLandscape ? 'Portrait' : 'Landscape'),
                                                style: TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: _accentColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ──── Floating Bottom Bar (Overlaid at bottom) ────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              bottom: _barsVisible ? 0 : -120,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _barsVisible ? 1.0 : 0.0,
                child: SafeArea(
                  top: false,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, page, _) {
                      return Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        height: 52,
                        decoration: BoxDecoration(
                          color: _barBgColor.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _dividerColor.withValues(alpha: 0.8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkTheme ? 0.45 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Text(
                              '${_toArabicNum(page)} / ٦٠٤',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _accentColor,
                                  inactiveTrackColor: _dividerColor,
                                  thumbColor: _accentColor,
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: page.toDouble(),
                                  min: 1,
                                  max: 604,
                                  divisions: 603,
                                  onChanged: (val) => _jumpToPage(val.round()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showSurahIndexSheet(context, isAr),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _dividerColor.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.list_alt_rounded, color: _textColor, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3 أزرار مباشرة لاختيار مظهر المصحف (عادي، بيج، ليلي)
  Widget _buildThemeCircle({
    required MushafThemeMode mode,
    required Color color,
    required Color borderColor,
  }) {
    final isSelected = _themeMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _setTheme(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? borderColor : _dividerColor,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

}

/// نافذة الفهرس الشاملة بألوان متطابقة مع مظهر المصحف النشط
class _QuranIndexBottomSheet extends StatefulWidget {
  const _QuranIndexBottomSheet({
    required this.currentPage,
    required this.bookmarkPage,
    required this.themeMode,
    required this.isAr,
    required this.onSelectPage,
  });

  final int currentPage;
  final int? bookmarkPage;
  final MushafThemeMode themeMode;
  final bool isAr;
  final ValueChanged<int> onSelectPage;

  @override
  State<_QuranIndexBottomSheet> createState() => _QuranIndexBottomSheetState();
}

class _QuranIndexBottomSheetState extends State<_QuranIndexBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  Color get _textColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF1B241E),
        MushafThemeMode.sepia => const Color(0xFF3E2723),
        MushafThemeMode.dark => const Color(0xFFEDEAE4),
      };

  Color get _mutedTextColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF5A665E),
        MushafThemeMode.sepia => const Color(0xFF6D4C41),
        MushafThemeMode.dark => const Color(0xFF9EABA2),
      };

  Color get _accentColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF0F766E),
        MushafThemeMode.sepia => const Color(0xFF8D6E63),
        MushafThemeMode.dark => const Color(0xFF34D399),
      };

  Color get _fieldBg => switch (widget.themeMode) {
        MushafThemeMode.cream => Colors.black.withValues(alpha: 0.05),
        MushafThemeMode.sepia => Colors.black.withValues(alpha: 0.05),
        MushafThemeMode.dark => Colors.white.withValues(alpha: 0.07),
      };

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = quranSurahs.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final numMatch = s.number.toString() == q;
      final nameMatch = s.name.toLowerCase().contains(q) ||
          s.englishName.toLowerCase().contains(q) ||
          s.englishTranslation.toLowerCase().contains(q);
      return numMatch || nameMatch;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _mutedTextColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            if (widget.bookmarkPage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Material(
                  color: const Color(0xFFD97706).withValues(alpha: widget.themeMode == MushafThemeMode.dark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => widget.onSelectPage(widget.bookmarkPage!),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_rounded, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            widget.isAr
                                ? 'الانتقال إلى العلامة المرجعية (صفحة ${_toArabicNum(widget.bookmarkPage!)})'
                                : 'Go to Bookmark (Page ${widget.bookmarkPage})',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD97706)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            TabBar(
              controller: _tabController,
              labelColor: _accentColor,
              unselectedLabelColor: _mutedTextColor,
              indicatorColor: _accentColor,
              tabs: [
                Tab(text: widget.isAr ? 'السور (١١٤)' : 'Surahs (114)'),
                Tab(text: widget.isAr ? 'الأجزاء (٣٠)' : 'Juz (30)'),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  hintText: widget.isAr ? 'ابحث عن سورة أو رقمها...' : 'Search surah...',
                  hintStyle: TextStyle(color: _mutedTextColor),
                  prefixIcon: Icon(Icons.search_rounded, color: _mutedTextColor),
                  isDense: true,
                  filled: true,
                  fillColor: _fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, idx) {
                      final s = filteredSurahs[idx];
                      final isCurrent = s.page == widget.currentPage;
                      final isBookmarked = s.page == widget.bookmarkPage;

                      return ListTile(
                        onTap: () => widget.onSelectPage(s.page),
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent ? _accentColor : _accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _toArabicNum(s.number),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isCurrent ? Colors.white : _accentColor,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'سُورَةُ ${s.name}',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                color: isCurrent ? _accentColor : _textColor,
                              ),
                            ),
                            if (isBookmarked) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.bookmark_rounded, size: 16, color: Color(0xFFD97706)),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${s.isMeccan ? 'مكية' : 'مدنية'} • ${_toArabicNum(s.numberOfAyahs)} آيات',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: _mutedTextColor,
                          ),
                        ),
                        trailing: Text(
                          'صفحة ${_toArabicNum(s.page)}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mutedTextColor,
                          ),
                        ),
                      );
                    },
                  ),

                  ListView.builder(
                    controller: scrollCtrl,
                    itemCount: 30,
                    itemBuilder: (context, idx) {
                      final juzNum = idx + 1;
                      final page = juzNum == 1 ? 1 : ((juzNum - 1) * 20) + 2;
                      final surahAtJuz = getSurahForPage(page);

                      return ListTile(
                        onTap: () => widget.onSelectPage(page),
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _toArabicNum(juzNum),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _accentColor,
                            ),
                          ),
                        ),
                        title: Text(
                          getJuzNameAr(juzNum),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'يبدأ من سورة ${surahAtJuz.name}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: _mutedTextColor,
                          ),
                        ),
                        trailing: Text(
                          'صفحة ${_toArabicNum(page)}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mutedTextColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// شريط ونافذة البحث الشاملة في القرآن الكريم (الآيات، السور، والصفحات)
class _QuranSearchBottomSheet extends StatefulWidget {
  const _QuranSearchBottomSheet({
    required this.themeMode,
    required this.isAr,
    required this.onSelectPage,
  });

  final MushafThemeMode themeMode;
  final bool isAr;
  final ValueChanged<int> onSelectPage;

  @override
  State<_QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<_QuranSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  Color get _textColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF1B241E),
        MushafThemeMode.sepia => const Color(0xFF3E2723),
        MushafThemeMode.dark => const Color(0xFFEDEAE4),
      };

  Color get _mutedTextColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF5A665E),
        MushafThemeMode.sepia => const Color(0xFF6D4C41),
        MushafThemeMode.dark => const Color(0xFF9EABA2),
      };

  Color get _accentColor => switch (widget.themeMode) {
        MushafThemeMode.cream => const Color(0xFF0F766E),
        MushafThemeMode.sepia => const Color(0xFF8D6E63),
        MushafThemeMode.dark => const Color(0xFF34D399),
      };

  Color get _fieldBg => switch (widget.themeMode) {
        MushafThemeMode.cream => Colors.black.withValues(alpha: 0.05),
        MushafThemeMode.sepia => Colors.black.withValues(alpha: 0.05),
        MushafThemeMode.dark => Colors.white.withValues(alpha: 0.07),
      };

  static const List<Map<String, dynamic>> _famousAyahs = [
    {
      'title': 'آية الكرسي',
      'surah': 'سورة البقرة',
      'ayah': '٢٥٥',
      'text': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...',
      'page': 42,
    },
    {
      'title': 'خواتيم سورة البقرة',
      'surah': 'سورة البقرة',
      'ayah': '٢٨٥ - ٢٨٦',
      'text': 'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ...',
      'page': 49,
    },
    {
      'title': 'آية الدين (أطول آية في القرآن)',
      'surah': 'سورة البقرة',
      'ayah': '٢٨٢',
      'text': 'يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا تَدَايَنتُم بِدَيْنٍ إِلَىٰ أَجَلٍ مُّسَمًّى فَاكْتُبُوهُ...',
      'page': 48,
    },
    {
      'title': 'أواخر سورة آل عمران',
      'surah': 'سورة آل عمران',
      'ayah': '١٩٠ - ١٩٤',
      'text': 'إِنَّ فِي خَلْقِ السَّمَاوَاتِ وَالْأَرْضِ وَاخْتِلَافِ اللَّيْلِ وَالنَّهَارِ لَآيَاتٍ لِّأُولِي الْأَلْبَابِ...',
      'page': 75,
    },
    {
      'title': 'آية النور',
      'surah': 'سورة النور',
      'ayah': '٣٥',
      'text': 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ ۚ مَثَلُ نُورِهِ كَمِشْكَاةٍ فِيهَا مِصْبَاحٌ...',
      'page': 354,
    },
    {
      'title': 'أواخر سورة الحشر',
      'surah': 'سورة الحشر',
      'ayah': '٢١ - ٢٤',
      'text': 'لَوْ أَنزَلْنَا هَٰذَا الْقُرْآنَ عَلَىٰ جَبَلٍ لَّرَأَيْتَهُ خَاشِعًا مُّتَصَدِّعًا مِّنْ خَشْيَةِ اللَّهِ...',
      'page': 548,
    },
    {
      'title': 'آية الطمأنينة والذكر',
      'surah': 'سورة الرعد',
      'ayah': '٢٨',
      'text': 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'page': 252,
    },
    {
      'title': 'دعاء ذي النون في بطن الحوت',
      'surah': 'سورة الأنبياء',
      'ayah': '٨٧',
      'text': 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      'page': 329,
    },
    {
      'title': 'آية الفرج والمخرج والرزق',
      'surah': 'سورة الطلاق',
      'ayah': '٢ - ٣',
      'text': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا * وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ...',
      'page': 558,
    },
    {
      'title': 'سورة الكهف (نور ما بين الجمعتين)',
      'surah': 'سورة الكهف',
      'ayah': '١ - ١١٠',
      'text': 'الْحَمْدُ لِلَّهِ الَّذِي أَنزَلَ عَلَىٰ عَبْدِهِ الْكِتَابَ وَلَمْ يَجْعَل لَّهُ عِوَجًا',
      'page': 293,
    },
    {
      'title': 'سورة يس (قلب القرآن الكريم)',
      'surah': 'سورة يس',
      'ayah': '١ - ٨٣',
      'text': 'يس * وَالْقُرْآنِ الْحَكِيمِ * إِنَّكَ لَمِنَ الْمُرْسَلِينَ',
      'page': 440,
    },
    {
      'title': 'سورة الرحمن (عروس القرآن)',
      'surah': 'سورة الرحمن',
      'ayah': '١ - ٧٨',
      'text': 'الرَّحْمَٰنُ * عَلَّمَ الْقُرْآنَ * خَلَقَ الْإِنسَانَ * عَلَّمَهُ الْبَيَانَ',
      'page': 531,
    },
    {
      'title': 'سورة الواقعة',
      'surah': 'سورة الواقعة',
      'ayah': '١ - ٩٦',
      'text': 'إِذَا وَقَعَتِ الْوَاقِعَةُ * لَيْسَ لِوَقْعَتِهَا كَاذِبَةٌ',
      'page': 534,
    },
    {
      'title': 'سورة الملك (المنجية من عذاب القبر)',
      'surah': 'سورة الملك',
      'ayah': '١ - ٣٠',
      'text': 'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      'page': 562,
    },
    {
      'title': 'سورة الإخلاص (تعدل ثلث القرآن)',
      'surah': 'سورة الإخلاص',
      'ayah': '١ - ٤',
      'text': 'قُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ',
      'page': 604,
    },
    {
      'title': 'المعوذتان (الفلق والناس)',
      'surah': 'سورة الفلق والناس',
      'ayah': '١ - ٥',
      'text': 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ * قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      'page': 604,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cleanQ = _query.trim().toLowerCase();
    final parsedPage = int.tryParse(cleanQ);

    final filteredAyahs = _famousAyahs.where((item) {
      if (cleanQ.isEmpty) return true;
      final t = (item['title'] as String).toLowerCase();
      final s = (item['surah'] as String).toLowerCase();
      final txt = (item['text'] as String).toLowerCase();
      final p = (item['page'] as int).toString();
      return t.contains(cleanQ) || s.contains(cleanQ) || txt.contains(cleanQ) || p == cleanQ;
    }).toList();

    final filteredSurahs = quranSurahs.where((s) {
      if (cleanQ.isEmpty) return false;
      final name = s.name.toLowerCase();
      final num = s.number.toString();
      return name.contains(cleanQ) || num == cleanQ;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _mutedTextColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: _accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    widget.isAr ? 'البحث في آيات وسور القرآن الكريم' : 'Search Quran Ayahs & Surahs',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  hintText: widget.isAr
                      ? 'ابحث عن آية (الكرسي، النور)، سورة، أو رقم صفحة...'
                      : 'Search ayah, surah or page number...',
                  hintStyle: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    color: _mutedTextColor.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: _mutedTextColor,
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _fieldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (parsedPage != null && parsedPage >= 1 && parsedPage <= 604) ...[
                    Material(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        onTap: () => widget.onSelectPage(parsedPage),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Icon(Icons.auto_stories_rounded, color: _accentColor),
                        title: Text(
                          widget.isAr
                              ? 'الانتقال مباشرة إلى صفحة ${_toArabicNum(parsedPage)}'
                              : 'Jump to Page $parsedPage',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            color: _accentColor,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (filteredSurahs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        widget.isAr ? 'السور المطابقة' : 'Matching Surahs',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                    ...filteredSurahs.map((s) {
                      return ListTile(
                        onTap: () => widget.onSelectPage(s.page),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        leading: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _toArabicNum(s.number),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _accentColor,
                            ),
                          ),
                        ),
                        title: Text(
                          'سورة ${s.name}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          '${s.typeAr} • ${s.numberOfAyahs} آية',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: _mutedTextColor,
                          ),
                        ),
                        trailing: Text(
                          'صفحة ${_toArabicNum(s.page)}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 24),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      widget.isAr ? 'الآيات والمواضع القرآنية المشهورة' : 'Famous Quranic Ayahs',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                      ),
                    ),
                  ),

                  ...filteredAyahs.map((item) {
                    final p = item['page'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _fieldBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onTap: () => widget.onSelectPage(p),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        title: Row(
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _textColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ص ${_toArabicNum(p)}',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['surah']} • آية ${item['ayah']}',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['text'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: _mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
