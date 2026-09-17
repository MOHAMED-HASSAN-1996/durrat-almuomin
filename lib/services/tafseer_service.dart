import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AyahTafseerResult {
  final int surah;
  final int ayah;
  final String ayahText;
  final String tafseerText;
  final String tafseerSource;
  final List<AyahWordMeaning> wordMeanings;

  const AyahTafseerResult({
    required this.surah,
    required this.ayah,
    required this.ayahText,
    required this.tafseerText,
    required this.tafseerSource,
    required this.wordMeanings,
  });
}

class AyahWordMeaning {
  final String word;
  final String meaning;

  const AyahWordMeaning({
    required this.word,
    required this.meaning,
  });
}

class TafseerService {
  TafseerService._();
  static final TafseerService instance = TafseerService._();

  final Map<String, AyahTafseerResult> _memoryCache = {};

  /// تنظيف النصوص من أي وسوم HTML أو فراغات زائدة
  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// تنظيف نص الآية من أي علامات عثمانية دقيقة غير مدعومة في الخطوط العادية
  static String cleanQuranText(String text) {
    return text
        .replaceAll('\u06df', '') // Quranic small high rounded zero
        .replaceAll('\u06e0', '') // Quranic small high up-pointing dried seen
        .replaceAll('\u06e2', '') // Quranic small high meem isolated
        .replaceAll('\u06e3', '') // Quranic small low seen
        .replaceAll('\u06e4', '') // Quranic small high mad da
        .replaceAll('\u06e5', '') // Quranic small waw
        .replaceAll('\u06e6', '') // Quranic small ya
        .replaceAll('\u06e8', '') // Quranic small high noon
        .replaceAll('\u06ea', '') // Quranic empty center low stop
        .replaceAll('\u06eb', '') // Quranic empty center high stop
        .replaceAll('\u06ec', '') // Quranic rounded high stop
        .replaceAll('\u06ed', '') // Quranic low meem
        .replaceAll('\u200c', '') // ZWNJ
        .replaceAll('\u200d', '') // ZWJ
        .replaceAll('ۖ', ' ')
        .replaceAll('ۗ', ' ')
        .replaceAll('ۚ', ' ')
        .replaceAll('ۛ', ' ')
        .replaceAll('ۜ', ' ')
        .replaceAll('۩', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// جلب التفسير ومعاني الكلمات للآية المحددة من APIs معتمدة وسريعة
  Future<AyahTafseerResult> getAyahTafseerAndWords({
    required int surah,
    required int ayah,
    String? fallbackAyahText,
  }) async {
    final key = '$surah:$ayah';
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('tafseer_v3_$key');
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final words = (decoded['words'] as List<dynamic>? ?? [])
            .map((w) => AyahWordMeaning(
                  word: w['word']?.toString() ?? '',
                  meaning: w['meaning']?.toString() ?? '',
                ))
            .toList();

        final res = AyahTafseerResult(
          surah: surah,
          ayah: ayah,
          ayahText: decoded['ayahText']?.toString() ?? fallbackAyahText ?? '',
          tafseerText: decoded['tafseer']?.toString() ?? '',
          tafseerSource: decoded['source']?.toString() ?? 'التفسير الميسر',
          wordMeanings: words,
        );
        _memoryCache[key] = res;
        return res;
      } catch (_) {}
    }

    String tafseer = '';
    String tafseerSource = 'التفسير الميسر (مجمع الملك فهد)';
    String quranText = fallbackAyahText != null ? cleanQuranText(fallbackAyahText) : '';
    final List<AyahWordMeaning> wordMeanings = [];

    // ── 1. المصدر الأساسي: AlQuran Cloud API (quran-simple, ar.muyassar, ar.jalalayn) ──
    try {
      final url = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/$surah:$ayah/editions/quran-simple,ar.muyassar,ar.jalalayn',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];
        for (final item in dataList) {
          final id = item['edition']?['identifier']?.toString();
          final text = item['text']?.toString() ?? '';

          if (id == 'quran-simple' && text.isNotEmpty) {
            quranText = cleanQuranText(text);
          } else if (id == 'ar.muyassar' && text.isNotEmpty) {
            tafseer = _cleanHtml(text);
          } else if (id == 'ar.jalalayn' && text.isNotEmpty) {
            // استخراج المفردات وغريب الكلمات والمصطلحات العربية المحددة بين أقواس « »
            final matches = RegExp(r'«([^»]+)»\s*([^«]+)').allMatches(text);
            for (final m in matches) {
              final w = m.group(1)?.trim() ?? '';
              final mean = m.group(2)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
              if (w.isNotEmpty && mean.isNotEmpty) {
                wordMeanings.add(
                  AyahWordMeaning(
                    word: w,
                    meaning: mean,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AlQuran Cloud API error: $e');
    }

    // ── 2. البديل الاحتياطي الأول: مجمع الملك فهد (QuranEnc API) ──
    if (tafseer.isEmpty) {
      try {
        final url = Uri.parse(
          'https://quranenc.com/api/v1/translation/aya/arabic_moyassar/$surah/$ayah',
        );
        final response = await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final result = data['result'] as Map<String, dynamic>?;
          if (result != null) {
            tafseer = _cleanHtml(result['translation']?.toString() ?? '');
            final arText = result['arabic_text']?.toString();
            if (arText != null && arText.isNotEmpty && quranText.isEmpty) {
              quranText = cleanQuranText(arText);
            }
          }
        }
      } catch (e) {
        debugPrint('QuranEnc Tafseer error: $e');
      }
    }

    // ── 3. بديل لمعاني الكلمات إذا لم تتوفر من الجلالين ──
    if (wordMeanings.isEmpty) {
      try {
        final mokhtasarUrl = Uri.parse(
          'https://quranenc.com/api/v1/translation/aya/arabic_mokhtasar/$surah/$ayah',
        );
        final mRes = await http.get(mokhtasarUrl).timeout(const Duration(seconds: 6));
        if (mRes.statusCode == 200) {
          final data = jsonDecode(utf8.decode(mRes.bodyBytes)) as Map<String, dynamic>;
          final trans = data['result']?['translation']?.toString() ?? '';
          if (trans.isNotEmpty) {
            wordMeanings.add(
              AyahWordMeaning(
                word: 'المختصر في التفسير والبيان',
                meaning: _cleanHtml(trans),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Mokhtasar fallback error: $e');
      }
    }

    if (tafseer.isEmpty) {
      tafseer = 'يتطلب عرض التفسير الاتصال بالإنترنت لأول مرة، يرجى التأكد من اتصالك وإعادة المحاولة.';
    }

    final resultObj = AyahTafseerResult(
      surah: surah,
      ayah: ayah,
      ayahText: quranText.isNotEmpty ? quranText : (fallbackAyahText ?? ''),
      tafseerText: tafseer,
      tafseerSource: tafseerSource,
      wordMeanings: wordMeanings,
    );

    _memoryCache[key] = resultObj;

    // حفظ في الكاش
    try {
      final saveMap = {
        'ayahText': resultObj.ayahText,
        'tafseer': resultObj.tafseerText,
        'source': resultObj.tafseerSource,
        'words': resultObj.wordMeanings
            .map((w) => {'word': w.word, 'meaning': w.meaning})
            .toList(),
      };
      await prefs.setString('tafseer_v3_$key', jsonEncode(saveMap));
    } catch (_) {}

    return resultObj;
  }
}
