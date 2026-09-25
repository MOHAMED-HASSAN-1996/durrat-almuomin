import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/shaarawi_data.dart';
import '../screens/in_app_player_screen.dart';
import '../services/remote_content_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// شاشة دروس فضيلة الشيخ محمد متولي الشعراوي — موسوعة منظمة ومبوبة
class ShaarawiScreen extends StatefulWidget {
  const ShaarawiScreen({super.key});

  @override
  State<ShaarawiScreen> createState() => _ShaarawiScreenState();
}

class _ShaarawiScreenState extends State<ShaarawiScreen> {
  ShaarawiCategory _selectedCategory = ShaarawiCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    RemoteContentService.instance.initialize();
    RemoteContentService.instance.addListener(_onRemoteContent);
  }

  @override
  void dispose() {
    RemoteContentService.instance.removeListener(_onRemoteContent);
    _searchController.dispose();
    super.dispose();
  }

  void _onRemoteContent() {
    if (mounted) setState(() {});
  }

  List<ShaarawiSeriesGroup> get _filteredSeriesGroups {
    final q = _searchQuery.trim().toLowerCase();
    // Merged local + admin-managed remote lessons (remote first).
    return RemoteContentService.instance.getShaarawiSeriesGroups()
        .map((group) {
          final matchesCategory =
              _selectedCategory == ShaarawiCategory.all ||
              group.category == _selectedCategory;
          if (!matchesCategory) return null;

          final matchedEpisodes = group.episodes.where((lesson) {
            if (q.isEmpty) return true;
            return lesson.titleAr.toLowerCase().contains(q) ||
                lesson.titleEn.toLowerCase().contains(q) ||
                lesson.descriptionAr.toLowerCase().contains(q) ||
                lesson.descriptionEn.toLowerCase().contains(q) ||
                (lesson.badge != null &&
                    lesson.badge!.toLowerCase().contains(q));
          }).toList();

          if (matchedEpisodes.isEmpty) return null;

          return ShaarawiSeriesGroup(
            id: group.id,
            titleAr: group.titleAr,
            titleEn: group.titleEn,
            descriptionAr: group.descriptionAr,
            descriptionEn: group.descriptionEn,
            badge: group.badge,
            category: group.category,
            episodes: matchedEpisodes,
          );
        })
        .whereType<ShaarawiSeriesGroup>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final seriesGroups = _filteredSeriesGroups;
    final isEmpty = seriesGroups.isEmpty;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AppBar(
              title: Text(
                isAr ? 'دروس الشيخ الشعراوي' : "Imam El-Sha'rawi's Lessons",
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _buildSearchBar(isAr, dark),
                const SizedBox(height: 12),
                _buildCategoryChips(isAr, dark),
                const SizedBox(height: 16),
                if (isEmpty)
                  _buildEmptyState(isAr, dark)
                else ...[
                  ...seriesGroups.map(
                    (group) => _buildSeriesGroupCard(group, isAr, dark),
                  ),
                  if (shaarawiPlaylists.isNotEmpty &&
                      _searchQuery.isEmpty &&
                      _selectedCategory == ShaarawiCategory.all) ...[
                    const SizedBox(height: 16),
                    _buildPlaylistsSection(isAr, dark),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }



  /// بطاقة تعريفية بإمام الدعاة
  // ignore: unused_element
  Widget _buildIntroBanner(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF16241E), Color(0xFF0E1713)]
              : const [Color(0xFFF3F8F5), Color(0xFFE3EFE9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DhikrColors.forest.withValues(alpha: dark ? 0.35 : 0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DhikrColors.forest, DhikrColors.forestDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DhikrColors.forest.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.graduationCap,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'موسوعة خواطر إمام الدعاة'
                      : "Imam El-Sha'rawi Encyclopedia",
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'دروس وتفاسير منتقاة ومبوبة حسب الأبواب، تُشغَّل مباشرة داخل التطبيق.'
                      : 'Curated lessons categorized by topic, playable right inside the app.',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12.5,
                    height: 1.45,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط البحث
  Widget _buildSearchBar(bool isAr, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: DhikrColors.forest.withValues(alpha: dark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 14,
          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
        ),
        decoration: InputDecoration(
          hintText: isAr
              ? 'ابحث في خواطر ودروس الشيخ...'
              : "Search Sheikh's lessons...",
          hintStyle: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 13.5,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
          prefixIcon: const Icon(LucideIcons.search,
              size: 19, color: DhikrColors.forest),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// شرائح التصفية حسب الأبواب والتصنيفات
  Widget _buildCategoryChips(bool isAr, bool dark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ShaarawiCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                isAr ? cat.titleAr : cat.titleEn,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                ),
              ),
              selected: isSelected,
              selectedColor: DhikrColors.forest,
              backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
              elevation: 0,
              pressElevation: 0,
              side: BorderSide(
                color: isSelected
                    ? DhikrColors.forest
                    : (dark
                          ? DhikrColors.sageSoft.withValues(alpha: 0.2)
                          : const Color(0xFFE5E7EB)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// بطاقة السلسلة مع كروت الحلقات/الأجزاء تحت بعضها
  Widget _buildSeriesGroupCard(
    ShaarawiSeriesGroup group,
    bool isAr,
    bool dark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : DhikrColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              DhikrColors.forest.withValues(alpha: dark ? 0.32 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس السلسلة / Group Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark
                  ? DhikrColors.darkSurfaceHigh
                  : DhikrColors.ivoryWarm,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              border: Border(
                bottom: BorderSide(
                  color: DhikrColors.forest
                      .withValues(alpha: dark ? 0.22 : 0.15),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DhikrColors.forest, DhikrColors.forestDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: DhikrColors.forest.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.layers,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? group.titleAr : group.titleEn,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: dark
                                    ? DhikrColors.darkText
                                    : DhikrColors.charcoal,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: DhikrColors.forest.withValues(
                                alpha: dark ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: DhikrColors.forest
                                    .withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              group.badge,
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: DhikrColors.forest,
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
          ),

          // كروت الأجزاء والحلقات — شبكة من عمودين
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: List.generate(group.episodes.length, (idx) {
                final episode = group.episodes[idx];
                return _buildEpisodeCard(
                  title: isAr ? episode.titleAr : episode.titleEn,
                  description: isAr
                      ? episode.descriptionAr
                      : episode.descriptionEn,
                  duration: episode.duration,
                  thumbnailUrl: episode.thumbnailUrl,
                  videoUrl: episode.videoUrl,
                  partBadge:
                      episode.partTitleAr ??
                      (isAr
                          ? 'الجزء ${episode.partNumber ?? idx + 1}'
                          : 'Part ${episode.partNumber ?? idx + 1}'),
                  accentColor: DhikrColors.forest,
                  isAr: isAr,
                  dark: dark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// كرت موحد ومميز للحلقة أو الجزء الفردي
  Widget _buildEpisodeCard({
    required String title,
    required String description,
    required String duration,
    required String thumbnailUrl,
    required String videoUrl,
    required String? partBadge,
    required Color accentColor,
    required bool isAr,
    required bool dark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          playYoutubeInFrame(
            context,
            url: videoUrl,
            title: title,
            description: description,
            channelName: isAr
                ? 'فضيلة الشيخ محمد متولي الشعراوي'
                : 'Sheikh Mohamed Metwally El-Shaarawi',
            channelUrl: shaarawiChannelUrl,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: accentColor.withValues(alpha: 0.15),
                        child: Icon(
                          LucideIcons.clapperboard,
                          color: accentColor,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.play,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// حالة عدم وجود نتائج عند البحث
  Widget _buildEmptyState(bool isAr, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 48,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'لم نجد دروساً تطابق بحثك'
                : 'No lessons matching your search',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'جرب البحث بكلمات أخرى أو اختر تصنيفاً مختلفاً'
                : 'Try different keywords or select another category',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 13,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
        ],
      ),
    );
  }

  /// قسم قوائم التشغيل والتفاسير الكبرى
  Widget _buildPlaylistsSection(bool isAr, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: DhikrColors.forest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAr
                  ? 'قوائم التفسير الشاملة للقرآن الكريم'
                  : 'Comprehensive Quran Tafsir Playlists',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...shaarawiPlaylists.map((pl) => _buildPlaylistItemCard(pl, isAr, dark)),
      ],
    );
  }

  Widget _buildPlaylistItemCard(ShaarawiPlaylist pl, bool isAr, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DhikrColors.forest.withValues(alpha: dark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            playYoutubeInFrame(
              context,
              url: pl.playlistUrl,
              title: isAr ? pl.titleAr : pl.titleEn,
              description: isAr ? pl.subtitleAr : pl.subtitleEn,
              channelName: isAr
                  ? 'فضيلة الشيخ محمد متولي الشعراوي'
                  : 'Sheikh Mohamed Metwally El-Shaarawi',
              channelUrl: shaarawiChannelUrl,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DhikrColors.forest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.listVideo,
                            size: 13,
                            color: DhikrColors.forest,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pl.episodesCount,
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: DhikrColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.chevronLeft,
                      size: 18,
                      color: DhikrColors.forest,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isAr ? pl.titleAr : pl.titleEn,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: dark
                        ? DhikrColors.darkText
                        : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.circlePlay,
                      size: 15,
                      color: DhikrColors.forest,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr
                          ? 'فتح وتشغيل السلسلة كاملة'
                          : 'Play Full Series In-App',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: DhikrColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
