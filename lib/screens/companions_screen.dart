import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/companions_stories_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// شاشة قصص رجال ونساء حول رسول الله ﷺ
class CompanionsScreen extends StatefulWidget {
  const CompanionsScreen({super.key});

  @override
  State<CompanionsScreen> createState() => _CompanionsScreenState();
}

class _CompanionsScreenState extends State<CompanionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CompanionStory> _filterStories(List<CompanionStory> list, bool isAr) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((s) {
      final name = isAr ? s.nameAr.toLowerCase() : s.nameEn.toLowerCase();
      final title = isAr ? s.titleAr.toLowerCase() : s.titleEn.toLowerCase();
      final summary = isAr
          ? s.summaryAr.toLowerCase()
          : s.summaryEn.toLowerCase();
      return name.contains(q) || title.contains(q) || summary.contains(q);
    }).toList();
  }

  void _openStoryDetail(BuildContext context, CompanionStory story, bool isAr) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CompanionDetailScreen(story: story, isAr: isAr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final filteredMen = _filterStories(menCompanionsList, isAr);
    final filteredWomen = _filterStories(womenCompanionsList, isAr);

    return Scaffold(
      backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
      appBar: AppBar(
        title: Text(
          isAr ? 'رجال ونساء حول رسول الله' : 'Men & Women Around the Prophet',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : Colors.black).withValues(
                alpha: 0.05,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: DhikrColors.forest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: DhikrColors.forest.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: dark ? Colors.white70 : Colors.black87,
              labelStyle: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        isAr
                            ? 'رجال حول الرسول (${filteredMen.length})'
                            : 'Men (${filteredMen.length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌸', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        isAr
                            ? 'نساء حول الرسول (${filteredWomen.length})'
                            : 'Women (${filteredWomen.length})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 14,
                  color: dark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث باسم الصحابي أو لقبه...'
                      : 'Search companion name or title...',
                  hintStyle: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    color: dark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: dark ? Colors.white38 : Colors.black38,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: (dark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStoriesList(filteredMen, isAr, dark),
                  _buildStoriesList(filteredWomen, isAr, dark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList(List<CompanionStory> list, bool isAr, bool dark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'لم يتم العثور على قصص مطابقة'
                  : 'No matching stories found',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 15,
                color: dark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final story = list[index];
        return _buildStoryCard(story, isAr, dark);
      },
    );
  }

  Widget _buildStoryCard(CompanionStory story, bool isAr, bool dark) {
    final isMen = story.category == CompanionCategory.men;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openStoryDetail(context, story, isAr),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DhikrColors.forest.withValues(alpha: dark ? 0.25 : 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            DhikrColors.forest.withValues(alpha: 0.45),
                            DhikrColors.forestDeep.withValues(alpha: 0.6),
                          ]
                        : [
                            DhikrColors.sageSoft,
                            DhikrColors.sageSoft.withValues(alpha: 0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: DhikrColors.forest
                        .withValues(alpha: dark ? 0.4 : 0.22),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DhikrColors.forest
                          .withValues(alpha: dark ? 0.25 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isMen ? LucideIcons.userCheck : LucideIcons.heartHandshake,
                    size: 22,
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                  ),
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
                            isAr ? story.nameAr : story.nameEn,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: dark
                                  ? Colors.white
                                  : DhikrColors.charcoal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? DhikrColors.forest.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: DhikrColors.forest
                                  .withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: DhikrColors.forest,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr
                                    ? '${story.readTimeMinutes} دقائق'
                                    : '${story.readTimeMinutes} min',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DhikrColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? story.titleAr : story.titleEn,
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: DhikrColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الشاشة التفصيلية لقراءة قصة الصحابي مع الدروس المستفادة ومشاركة القصة
class _CompanionDetailScreen extends StatefulWidget {
  const _CompanionDetailScreen({required this.story, required this.isAr});

  final CompanionStory story;
  final bool isAr;

  @override
  State<_CompanionDetailScreen> createState() => _CompanionDetailScreenState();
}

class _CompanionDetailScreenState extends State<_CompanionDetailScreen> {
  double _fontSizeScale = 1.0;

  void _shareStory() {
    HapticFeedback.selectionClick();
    final s = widget.story;
    final milestones = widget.isAr ? s.milestonesAr : s.milestonesEn;
    final virtues = widget.isAr ? s.virtuesAr : s.virtuesEn;

    final StringBuffer buffer = StringBuffer();
    if (widget.isAr) {
      buffer.writeln('«${s.nameAr} — ${s.titleAr}» 🌟\n');
      buffer.writeln('${s.summaryAr}\n');
      buffer.writeln('مقولة خالدة:\n${s.famousQuoteAr}\n');
      if (virtues.isNotEmpty) {
        buffer.writeln('من المناقب والفضائل النبوية:');
        for (final v in virtues) {
          buffer.writeln('⭐ $v');
        }
        buffer.writeln();
      }
      if (milestones.isNotEmpty) {
        buffer.writeln('أبرز المحطات الفاصلة:');
        for (var i = 0; i < milestones.length; i++) {
          buffer.writeln('${i + 1}. ${milestones[i]}');
        }
        buffer.writeln();
      }
      buffer.writeln('من الدروس والعبر المستفادة:');
      for (final l in s.lessonsAr) {
        buffer.writeln('• $l');
      }
      buffer.writeln('\n— تم المشاركة من تطبيق ذكر');
    } else {
      buffer.writeln('«${s.nameEn} — ${s.titleEn}» 🌟\n');
      buffer.writeln('${s.summaryEn}\n');
      buffer.writeln('Notable Quote:\n${s.famousQuoteEn}\n');
      if (virtues.isNotEmpty) {
        buffer.writeln('Prophetic Virtues:');
        for (final v in virtues) {
          buffer.writeln('⭐ $v');
        }
        buffer.writeln();
      }
      if (milestones.isNotEmpty) {
        buffer.writeln('Key Milestones:');
        for (var i = 0; i < milestones.length; i++) {
          buffer.writeln('${i + 1}. ${milestones[i]}');
        }
        buffer.writeln();
      }
      buffer.writeln('Key Lessons:');
      for (final l in s.lessonsEn) {
        buffer.writeln('• $l');
      }
      buffer.writeln('\n— Shared from Dhikr App');
    }

    final text = buffer.toString();

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isAr
              ? 'تم نسخ القصة للمشاركة بنجاح ✓'
              : 'Story copied to share ✓',
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.story;
    final isMen = s.category == CompanionCategory.men;
    final cardAccent = isMen ? DhikrColors.forest : DhikrColors.forestLight;

    return Scaffold(
      backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
      appBar: AppBar(
        title: Text(
          widget.isAr ? s.nameAr : s.nameEn,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: widget.isAr ? 'تعديل حجم الخط' : 'Font Size',
            icon: const Icon(Icons.format_size_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (_fontSizeScale >= 1.3) {
                  _fontSizeScale = 1.0;
                } else {
                  _fontSizeScale += 0.15;
                }
              });
            },
          ),
          IconButton(
            tooltip: widget.isAr ? 'مشاركة القصة' : 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareStory,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [DhikrColors.darkSurface, DhikrColors.darkBg]
                      : [DhikrColors.sageSoft, DhikrColors.sageSoft.withValues(alpha: 0.7)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cardAccent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 8),
                  Text(
                    widget.isAr ? s.nameAr : s.nameEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : DhikrColors.forestDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isAr ? s.titleAr : s.titleEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cardAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: (dark ? Colors.black : Colors.white).withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cardAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      widget.isAr ? s.famousQuoteAr : s.famousQuoteEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white70 : DhikrColors.forestDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? DhikrColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (dark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 20,
                        color: cardAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isAr
                            ? 'القصة والسيرة العطرة'
                            : 'Biography & Story',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cardAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.isAr ? s.storyAr : s.storyEn,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 16 * _fontSizeScale,
                      height: 1.9,
                      color: dark
                          ? const Color(0xFFEDEAE4)
                          : DhikrColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if ((widget.isAr ? s.milestonesAr : s.milestonesEn).isNotEmpty) ...[
              _buildMilestonesCard(s, widget.isAr, dark, cardAccent),
              const SizedBox(height: 20),
            ],

            if ((widget.isAr ? s.virtuesAr : s.virtuesEn).isNotEmpty) ...[
              _buildVirtuesCard(s, widget.isAr, dark),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark
                    ? DhikrColors.darkSurfaceHigh
                    : DhikrColors.sageSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: DhikrColors.forest.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        widget.isAr
                            ? 'دروس وعِبر مضيئة لحياتنا'
                            : 'Illuminating Life Lessons',
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: DhikrColors.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...((widget.isAr ? s.lessonsAr : s.lessonsEn).map(
                    (lesson) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: DhikrColors.forest,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lesson,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 14 * _fontSizeScale,
                                height: 1.6,
                                color: dark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(
    CompanionStory s,
    bool isAr,
    bool dark,
    Color cardAccent,
  ) {
    final milestones = isAr ? s.milestonesAr : s.milestonesEn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardAccent.withValues(alpha: dark ? 0.25 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: cardAccent.withValues(alpha: dark ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cardAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  size: 18,
                  color: cardAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isAr
                    ? 'أبرز المحطات الفاصلة والمنعطفات'
                    : 'Key Historical Milestones',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: cardAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...milestones.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cardAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: cardAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 14 * _fontSizeScale,
                        height: 1.65,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.88)
                            : DhikrColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVirtuesCard(CompanionStory s, bool isAr, bool dark) {
    const goldColor = Color(0xFFD97706);
    final virtues = isAr ? s.virtuesAr : s.virtuesEn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark
            ? DhikrColors.darkSurface
            : DhikrColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: goldColor.withValues(alpha: dark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: dark ? 0.10 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: goldColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isAr
                    ? 'المناقب والفضائل النبوية'
                    : 'Prophetic Praises & Virtues',
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...virtues.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('⭐', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      v,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13.5 * _fontSizeScale,
                        height: 1.65,
                        fontStyle: FontStyle.italic,
                        color: dark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
