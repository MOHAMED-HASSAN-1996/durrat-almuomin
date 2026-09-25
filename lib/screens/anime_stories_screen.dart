import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/anime_stories_data.dart';
import '../screens/in_app_player_screen.dart';
import '../services/remote_content_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// شاشة «قصص دينية أنمي والرسوم المتحركة» — سلاسل وحكايات كرتونية
/// إسلامية مشوقة تُشغَّل داخل التطبيق.
class AnimeStoriesScreen extends StatefulWidget {
  const AnimeStoriesScreen({super.key});

  @override
  State<AnimeStoriesScreen> createState() => _AnimeStoriesScreenState();
}

class _AnimeStoriesScreenState extends State<AnimeStoriesScreen> {
  AnimeCategory _selectedCategory = AnimeCategory.all;
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

  List<AnimeSeriesGroup> get _filteredSeriesGroups {
    final q = _searchQuery.trim().toLowerCase();
    // Merged local + admin-managed remote stories (remote first).
    return RemoteContentService.instance.getAnimeSeriesGroups()
        .map((group) {
          final matchesCategory =
              _selectedCategory == AnimeCategory.all ||
              group.category == _selectedCategory;
          if (!matchesCategory) return null;

          final matchedEpisodes = group.episodes.where((story) {
            if (q.isEmpty) return true;
            return story.titleAr.toLowerCase().contains(q) ||
                story.titleEn.toLowerCase().contains(q) ||
                story.prophetNameAr.toLowerCase().contains(q) ||
                story.prophetNameEn.toLowerCase().contains(q) ||
                story.descriptionAr.toLowerCase().contains(q) ||
                story.descriptionEn.toLowerCase().contains(q) ||
                (story.tag != null && story.tag!.toLowerCase().contains(q));
          }).toList();

          if (matchedEpisodes.isEmpty) return null;

          return AnimeSeriesGroup(
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
        .whereType<AnimeSeriesGroup>()
        .toList();
  }

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
                isAr ? 'قصص دينية أنمي' : 'Animated Islamic Stories',
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
            child: _buildStoriesListView(isAr, dark),
          ),
        ),
      ),
    );
  }

  /// قائمة الحكايات والقصص بالرسوم المتحركة مع دعم السلاسل والأجزاء
  Widget _buildStoriesListView(bool isAr, bool dark) {
    final seriesGroups = _filteredSeriesGroups;
    final isEmpty = seriesGroups.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _buildSearchBar(isAr, dark),
        const SizedBox(height: 12),
        _buildCategoryChips(isAr, dark),
        const SizedBox(height: 14),
        if (isEmpty)
          _buildEmptyState(isAr, dark)
        else
          ...seriesGroups.map(
            (group) => _buildSeriesGroupCard(group, isAr, dark),
          ),
      ],
    );
  }

  /// بطاقة الترحيب والتعريف بقسم قصص دينية أنمي
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
                  color: DhikrColors.forest.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.clapperboard,
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
                      ? 'قصص دينية إسلامية بالرسوم المتحركة'
                      : 'Animated Islamic Stories',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'حكايات إيمانية مشوقة بأسلوب كرتوني باهر، تُشغَّل الحلقات مباشرة داخل التطبيق.'
                      : 'Faith-filled animated stories for all ages, playing right inside the app.',
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
              ? 'ابحث عن اسم نبي أو قصة كرتونية...'
              : 'Search prophet or story name...',
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

  /// شرائح التصفية للتصنيفات
  Widget _buildCategoryChips(bool isAr, bool dark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AnimeCategory.values.map((cat) {
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

  /// بطاقة السلسلة الكرتونية مع كروت الحلقات تحت بعضها
  Widget _buildSeriesGroupCard(AnimeSeriesGroup group, bool isAr, bool dark) {
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
                      LucideIcons.clapperboard,
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
                final queue = group.episodes
                    .map(
                      (e) => PlayerQueueItem(
                        url: e.videoUrl,
                        title: isAr ? e.titleAr : e.titleEn,
                      ),
                    )
                    .toList();
                return _buildEpisodeCard(
                  title: isAr ? episode.titleAr : episode.titleEn,
                  description: isAr
                      ? episode.descriptionAr
                      : episode.descriptionEn,
                  duration: episode.durationOrEpisodes,
                  thumbnailUrl: episode.thumbnailUrl,
                  videoUrl: episode.videoUrl,
                  playlist: queue,
                  playlistIndex: idx,
                  partBadge:
                      episode.episodeTitleAr ??
                      (isAr
                          ? 'الحلقة ${episode.episodeNumber ?? idx + 1}'
                          : 'Episode ${episode.episodeNumber ?? idx + 1}'),
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

  /// كرت موحد ومميز للحلقة الكرتونية
  Widget _buildEpisodeCard({
    required String title,
    required String description,
    required String duration,
    required String thumbnailUrl,
    required String videoUrl,
    List<PlayerQueueItem>? playlist,
    int playlistIndex = 0,
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
                ? 'بتاع أنمي (قصص القرآن والتاريخ)'
                : 'Betaa Anime (Quran & History)',
            channelUrl: animeChannelUrl,
            playlist: playlist,
            initialIndex: playlistIndex,
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
                      cacheWidth: 480,
                      filterQuality: FilterQuality.low,
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


  /// حالة عدم العثور على نتائج
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
                ? 'لم نجد قصصاً تطابق بحثك'
                : 'No stories matching your search',
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
                ? 'جرب البحث باسم نبي آخر مثل "يوسف" أو "موسى"'
                : 'Try searching for another prophet name',
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
}
