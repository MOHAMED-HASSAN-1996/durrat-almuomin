import 'dart:convert';

import 'package:qcf_quran/qcf_quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';

/// A single saved Quran reference memory (مرجعية).
///
/// A reference can point at a page, at a specific ayah, or at a free-text
/// «word» the reader wants to come back to. Multiple references can coexist,
/// so the reader is no longer limited to one bookmark.
class QuranBookmark {
  const QuranBookmark({
    required this.id,
    required this.page,
    required this.surahName,
    required this.createdAtMs,
    this.surahNumber = 0,
    this.ayahNumber = 0,
    this.label = '',
  });

  /// Unique id (milliseconds-since-epoch string).
  final String id;

  /// Mushaf page (1..604) this reference opens.
  final int page;

  /// Arabic surah name captured when the reference was created.
  final String surahName;

  /// Surah number (1..114), or 0 when the reference is page-only.
  final int surahNumber;

  /// Ayah number when the reference was created from a search result, else 0.
  final int ayahNumber;

  /// Optional user-facing note, e.g. the matched word or a custom title.
  final String label;

  /// Creation timestamp in milliseconds since epoch.
  final int createdAtMs;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  QuranBookmark copyWith({String? label}) => QuranBookmark(
    id: id,
    page: page,
    surahName: surahName,
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
    label: label ?? this.label,
    createdAtMs: createdAtMs,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'page': page,
    'surahName': surahName,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'label': label,
    'createdAt': createdAtMs,
  };

  static QuranBookmark? fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    if (page < 1 || page > 604) return null;
    final createdAt =
        (json['createdAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return QuranBookmark(
      id: json['id']?.toString() ?? createdAt.toString(),
      page: page,
      surahName: json['surahName']?.toString() ?? '',
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '',
      createdAtMs: createdAt,
    );
  }
}

/// Quran Service for managing user reading position, bookmarks,
/// and metadata using qcf_quran.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const _lastReadSurahKey = 'adhkar.quran.last_read_surah';
  static const _lastReadPageKey = 'adhkar.quran.last_read_page';
  static const _lastReadNameKey = 'adhkar.quran.last_read_name';
  static const _bookmarkPageKey = 'adhkar.quran.bookmark_page';
  static const _bookmarksListKey = 'adhkar.quran.bookmarks_v2';

  /// Save last read position (page and surah)
  Future<void> saveLastRead({
    required int surahNumber,
    required int page,
    required String surahName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadSurahKey, surahNumber);
      await prefs.setInt(_lastReadPageKey, page);
      await prefs.setString(_lastReadNameKey, surahName);
    } catch (_) {}
  }

  /// Get last read position
  Future<Map<String, dynamic>?> getLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surah = prefs.getInt(_lastReadSurahKey);
      final page = prefs.getInt(_lastReadPageKey);
      if (page != null && page >= 1 && page <= 604) {
        final meta = getSurahForPage(page);
        return {
          'surahNumber': surah ?? meta.number,
          'page': page,
          'surahName': prefs.getString(_lastReadNameKey) ?? meta.name,
        };
      } else if (surah != null && surah >= 1 && surah <= 114) {
        final meta = quranSurahs[surah - 1];
        return {
          'surahNumber': surah,
          'page': meta.page,
          'surahName': prefs.getString(_lastReadNameKey) ?? meta.name,
        };
      }
    } catch (_) {}
    return null;
  }

  /// Maximum number of reference memories kept on the device.
  static const int maxBookmarks = 60;

  /// Saves a new reference memory (مرجعية) and returns the updated list.
  ///
  /// When a reference for the same [page] already exists it is refreshed
  /// (moved to the top) instead of being duplicated.
  Future<List<QuranBookmark>> addBookmark(
    int page, {
    String? label,
    int surahNumber = 0,
    int ayahNumber = 0,
  }) async {
    final safePage = page.clamp(1, 604);
    final meta = getSurahForPage(safePage);
    final bookmarks = await getBookmarks();

    bookmarks.removeWhere((b) => b.page == safePage);

    final now = DateTime.now();
    bookmarks.insert(
      0,
      QuranBookmark(
        id: now.microsecondsSinceEpoch.toString(),
        page: safePage,
        surahName: meta.name,
        surahNumber: surahNumber > 0 ? surahNumber : meta.number,
        ayahNumber: ayahNumber,
        label: label?.trim() ?? '',
        createdAtMs: now.millisecondsSinceEpoch,
      ),
    );

    final trimmed = bookmarks.take(maxBookmarks).toList();
    await _saveBookmarks(trimmed);
    return trimmed;
  }

  /// Removes the reference memory pointing at [page] and returns the rest.
  Future<List<QuranBookmark>> removeBookmark(int page) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.page == page);
    await _saveBookmarks(bookmarks);
    return bookmarks;
  }

  /// Removes every saved reference memory.
  Future<void> clearBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksListKey);
      await prefs.remove(_bookmarkPageKey);
    } catch (_) {}
  }

  /// Reads every saved reference memory, newest first.
  Future<List<QuranBookmark>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_bookmarksListKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = <QuranBookmark>[];
          for (final item in decoded) {
            if (item is Map) {
              final bookmark = QuranBookmark.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (bookmark != null) parsed.add(bookmark);
            }
          }
          parsed.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
          return parsed;
        }
      }

      // ── Migration: expose the legacy single bookmark as a reference ──
      final legacyPage = prefs.getInt(_bookmarkPageKey);
      if (legacyPage != null && legacyPage >= 1 && legacyPage <= 604) {
        final meta = getSurahForPage(legacyPage);
        return [
          QuranBookmark(
            id: legacyPage.toString(),
            page: legacyPage,
            surahName: meta.name,
            surahNumber: meta.number,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
      }
    } catch (_) {}
    return <QuranBookmark>[];
  }

  /// Saves a reference memory for [page] (kept for callers that only have a
  /// page number to offer).
  Future<void> saveBookmark(int page) async {
    await addBookmark(page);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bookmarkPageKey, page.clamp(1, 604));
    } catch (_) {}
  }

  /// Returns the most recent reference memory page, or null when none exists.
  Future<int?> getBookmark() async {
    final bookmarks = await getBookmarks();
    return bookmarks.isEmpty ? null : bookmarks.first.page;
  }

  /// Searches the Quran text for [query] and returns the matching verses with
  /// their surah name and mushaf page, so the reader can jump straight to them.
  Future<List<QuranWordMatch>> searchWord(
    String query, {
    int limit = 60,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <QuranWordMatch>[];
    final raw = searchVerses(q, limit: limit);
    return raw
        .map(
          (m) => QuranWordMatch(
            surahNumber: (m['surahNumber'] as num?)?.toInt() ?? 0,
            surahName: m['surahName']?.toString() ?? '',
            verseNumber: (m['verseNumber'] as num?)?.toInt() ?? 0,
            page: (m['page'] as num?)?.toInt() ?? 1,
            text: m['text']?.toString() ?? '',
            matchStart: (m['matchStart'] as num?)?.toInt() ?? 0,
            matchEnd: (m['matchEnd'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<void> _saveBookmarks(List<QuranBookmark> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _bookmarksListKey,
        jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
      );
    } catch (_) {}
  }
}

/// A single Quran word-search hit: the verse, its surah name and mushaf page,
/// plus the offsets of the matched word inside [text].
class QuranWordMatch {
  const QuranWordMatch({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.page,
    required this.text,
    required this.matchStart,
    required this.matchEnd,
  });

  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final int page;
  final String text;
  final int matchStart;
  final int matchEnd;

  /// The matched word itself (as it appeared inside the normalized verse text).
  String get matchedWord {
    if (matchStart < 0 || matchEnd > text.length || matchStart >= matchEnd) {
      return '';
    }
    return text.substring(matchStart, matchEnd);
  }
}
