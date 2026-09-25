import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/playable_content.dart';
import '../services/youtube_feed.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../screens/in_app_player_screen.dart';

/// عنصر مصنّف يدويًا يظهر كقسم إضافي/بديل عندما يتعذر جلب الخلاصة.
class CuratedChannelItem {
  final String title;
  final String titleEn;
  final String subtitle;
  final String subtitleEn;
  final String url;

  const CuratedChannelItem({
    required this.title,
    required this.titleEn,
    required this.subtitle,
    required this.subtitleEn,
    required this.url,
  });
}

/// قائمة مقاطع قناة يوتيوب تُجلب تلقائيًا من خلاصة RSS وتُشغَّل داخل التطبيق.
///
/// - أندرويد/iOS: جلب مباشر للخلاصة وعرض الأغلفة والعناوين.
/// - الويب (يمنع CORS الجلب): يُعرض مشغّل القناة المدمج داخل التطبيق كبديل،
///   مع أزرار إعادة المحاولة والأقسام المختارة.
class ChannelVideoList extends StatefulWidget {
  final String channelId;
  final String channelName;
  final Color accent;
  final Color accentDeep;
  final List<CuratedChannelItem> curatedFallback;

  const ChannelVideoList({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.accent,
    required this.accentDeep,
    this.curatedFallback = const [],
  });

  @override
  State<ChannelVideoList> createState() => _ChannelVideoListState();
}

class _ChannelVideoListState extends State<ChannelVideoList> {
  bool _loading = true;
  bool _failed = false;
  String _channelTitle = '';
  List<YoutubeVideoInfo> _videos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final feed = await fetchChannelFeed(widget.channelId);
      if (!mounted) return;
      setState(() {
        _channelTitle = feed.channelTitle.isEmpty
            ? widget.channelName
            : feed.channelTitle;
        _videos = feed.videos;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  String get _displayTitle =>
      _channelTitle.isEmpty ? widget.channelName : _channelTitle;

  bool get _hasVideos => !_failed && _loading == false && _videos.isNotEmpty;

  String get _uploadsPlaylistUrl =>
      'https://www.youtube.com/playlist?list=${uploadsPlaylistIdFor(widget.channelId)}';

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return _buildLoadingPanel(isAr, dark);
    }

    if (_hasVideos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideosHeader(isAr, dark, _videos.length),
          const SizedBox(height: 10),
          ..._videos.map((v) => _buildVideoTile(isAr, dark, v)),
          const SizedBox(height: 12),
          _buildBrowseChannelButton(isAr, dark, compact: true),
          if (widget.curatedFallback.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildCuratedHeader(isAr, dark),
            const SizedBox(height: 10),
            ...widget.curatedFallback.map(
              (c) => _buildCuratedTile(isAr, dark, c),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        _buildUnavailablePanel(isAr, dark),
        const SizedBox(height: 12),
        _buildBrowseChannelButton(isAr, dark, compact: false),
        if (widget.curatedFallback.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildCuratedHeader(isAr, dark),
          const SizedBox(height: 10),
          ...widget.curatedFallback.map(
            (c) => _buildCuratedTile(isAr, dark, c),
          ),
        ],
      ],
    );
  }

  // ── عناوين الأقسام ────────────────────────────────────────────────

  Widget _buildVideosHeader(bool isAr, bool dark, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isAr ? 'أحدث مقاطع القناة' : 'Latest from the channel',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: dark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isAr ? '$count مقطع' : '$count videos',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: widget.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuratedHeader(bool isAr, bool dark) {
    return Text(
      isAr ? 'أقسام مختارة' : 'Curated sections',
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
      ),
    );
  }

  // ── حالات التحميل/الفشل ───────────────────────────────────────────

  Widget _buildLoadingPanel(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: dark ? const Color(0xFF17130F) : Colors.white,
        border: Border.all(
          color: widget.accent.withValues(alpha: dark ? 0.25 : 0.12),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAr ? 'جارٍ جلب مقاطع القناة…' : 'Loading channel videos…',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13.5,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailablePanel(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: dark ? const Color(0xFF17130F) : Colors.white,
        border: Border.all(
          color: widget.accent.withValues(alpha: dark ? 0.25 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: widget.accent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'تعذّر جلب المقاطع الآن' : 'Could not load videos',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'تحقّق من الاتصال وأعد المحاولة، أو استعرض القناة من المشغّل المدمج أسفله.'
                      : 'Check your connection and retry, or browse the channel with the built-in player below.',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12.5,
                    height: 1.5,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            tooltip: isAr ? 'إعادة المحاولة' : 'Retry',
            icon: const Icon(Icons.refresh_rounded),
            color: widget.accent,
          ),
        ],
      ),
    );
  }

  // ── زر استعراض القناة (مشغّل مدمج) ────────────────────────────────

  Widget _buildBrowseChannelButton(
    bool isAr,
    bool dark, {
    required bool compact,
  }) {
    final title = isAr
        ? 'استعراض مقاطع القناة كاملة داخل التطبيق'
        : 'Browse the full channel in-app';
    final sub = isAr
        ? 'مشغّل يوتيوب مدمج يعرض كل حلقات $_displayTitle'
        : 'A built-in player showing all of $_displayTitle\'s videos';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => playYoutubeInFrame(
          context,
          url: _uploadsPlaylistUrl,
          title: compact ? title : sub,
          channelName: _displayTitle,
          channelUrl: 'https://www.youtube.com/channel/${widget.channelId}',
        ),
        borderRadius: BorderRadius.circular(20),
        splashColor: widget.accent.withValues(alpha: 0.12),
        highlightColor: widget.accent.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: dark ? const Color(0xFF17130F) : Colors.white,
            border: Border.all(
              color: widget.accent.withValues(alpha: dark ? 0.3 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.accent, widget.accentDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.tvMinimalPlay,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: dark
                            ? DhikrColors.darkText
                            : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11.5,
                        height: 1.4,
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
        ),
      ),
    );
  }

  // ── مقطع واحد من الخلاصة ──────────────────────────────────────────

  Widget _buildVideoTile(bool isAr, bool dark, YoutubeVideoInfo video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => playYoutubeInFrame(
            context,
            url: video.watchUrl,
            title: video.title,
            channelName: _displayTitle,
            channelUrl: 'https://www.youtube.com/channel/${widget.channelId}',
          ),
          borderRadius: BorderRadius.circular(20),
          splashColor: widget.accent.withValues(alpha: 0.12),
          highlightColor: widget.accent.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: dark ? const Color(0xFF151512) : Colors.white,
              border: Border.all(
                color: widget.accent.withValues(alpha: dark ? 0.3 : 0.14),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 132,
                    height: 74,
                    child: Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 320,
                      filterQuality: FilterQuality.low,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: widget.accent.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.accent,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) => Container(
                        color: dark
                            ? const Color(0xFF1E1E1C)
                            : const Color(0xFFF1F0EC),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.film,
                          color: widget.accent.withValues(alpha: 0.6),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.35,
                          color: dark
                              ? DhikrColors.darkText
                              : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _relativeDate(video.publishedAt, isAr),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11.5,
                              color: dark
                                  ? DhikrColors.darkMuted
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.accent, widget.accentDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── عنصر مصنّف ────────────────────────────────────────────────────

  Widget _buildCuratedTile(bool isAr, bool dark, CuratedChannelItem item) {
    final embeddable = parseYoutubeTarget(item.url) != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => playYoutubeInFrame(
            context,
            url: item.url,
            title: (isAr ? item.title : item.titleEn),
            channelName: _displayTitle,
            channelUrl: 'https://www.youtube.com/channel/${widget.channelId}',
          ),
          borderRadius: BorderRadius.circular(20),
          splashColor: widget.accent.withValues(alpha: 0.12),
          highlightColor: widget.accent.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: dark ? const Color(0xFF151512) : Colors.white,
              border: Border.all(
                color: widget.accent.withValues(alpha: dark ? 0.3 : 0.14),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: dark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.clapperboard,
                    size: 24,
                    color: widget.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? item.title : item.titleEn,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: dark
                              ? DhikrColors.darkText
                              : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr ? item.subtitle : item.subtitleEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12.5,
                          height: 1.4,
                          color: dark
                              ? DhikrColors.darkMuted
                              : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  embeddable
                      ? LucideIcons.monitorPlay
                      : LucideIcons.externalLink,
                  size: 20,
                  color: embeddable
                      ? widget.accent
                      : (dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime? dt, bool isAr) {
    if (dt == null) return '';
    final days = DateTime.now().difference(dt.toLocal()).inDays;
    if (days <= 0) return isAr ? 'اليوم' : 'Today';
    if (days == 1) return isAr ? 'أمس' : 'Yesterday';
    if (days < 30) return isAr ? 'قبل $days أيام' : '$days days ago';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}/$m/$d';
  }
}
