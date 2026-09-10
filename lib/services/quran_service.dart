import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs.dart';

/// Quran Service for managing user reading position, bookmarks,
/// and metadata using qcf_quran.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const _lastReadSurahKey = 'adhkar.quran.last_read_surah';
  static const _lastReadPageKey = 'adhkar.quran.last_read_page';
  static const _lastReadNameKey = 'adhkar.quran.last_read_name';
  static const _bookmarkPageKey = 'adhkar.quran.bookmark_page';

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

  /// Save dedicated bookmark (نقطة المرجع)
  Future<void> saveBookmark(int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bookmarkPageKey, page);
    } catch (_) {}
  }

  /// Get dedicated bookmark
  Future<int?> getBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bookmarkPageKey);
    } catch (_) {}
    return null;
  }
}
