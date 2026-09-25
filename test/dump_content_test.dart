// Dumps app content collections to tools/content_dump.json for admin seeding.
import 'dart:convert';
import 'dart:io';

import 'package:adhkar/data/adhkar.dart';
import 'package:adhkar/data/anime_stories_data.dart';
import 'package:adhkar/data/companions_stories_data.dart';
import 'package:adhkar/data/hadith_data.dart';
import 'package:adhkar/data/quran_surahs.dart';
import 'package:adhkar/data/riyad_hadith_data.dart';
import 'package:adhkar/data/shaarawi_data.dart';
import 'package:adhkar/data/soul_remedies_data.dart';
import 'package:adhkar/types/adhkar.dart';
import 'package:flutter_test/flutter_test.dart';

String catId(DhikrCategory c) {
  switch (c) {
    case DhikrCategory.morning:
      return 'morning';
    case DhikrCategory.evening:
      return 'evening';
    case DhikrCategory.ruqyah:
      return 'ruqyah';
    case DhikrCategory.sleep:
      return 'sleep';
    case DhikrCategory.waking:
      return 'waking';
    case DhikrCategory.afterPrayer:
      return 'afterPrayer';
    case DhikrCategory.tasbeeh:
      return 'tasbeeh';
  }
}

String catNameAr(DhikrCategory c) {
  switch (c) {
    case DhikrCategory.morning:
      return 'أذكار الصباح';
    case DhikrCategory.evening:
      return 'أذكار المساء';
    case DhikrCategory.ruqyah:
      return 'الرقية الشرعية';
    case DhikrCategory.sleep:
      return 'أذكار النوم';
    case DhikrCategory.waking:
      return 'أذكار الاستيقاظ';
    case DhikrCategory.afterPrayer:
      return 'أذكار بعد الصلاة';
    case DhikrCategory.tasbeeh:
      return 'السبحة والتسابيح';
  }
}

Map<String, dynamic> dhikrJson(Dhikr d, int order) => {
      'id': d.id,
      'category': catId(d.category),
      'categoryNameAr': catNameAr(d.category),
      'arabic': d.arabic,
      'english': d.english,
      'repeat': d.repeat,
      'source': d.source,
      'virtue': d.virtue ?? '',
      'virtueEn': d.virtueEn ?? '',
      'isAudio': (d.quranAudio != null && d.quranAudio!.isNotEmpty),
      'audioUrl': (d.quranAudio != null && d.quranAudio!.isNotEmpty)
          ? d.quranAudio!.first
          : '',
      'audio': '',
      'quranAudio': d.quranAudio ?? <String>[],
      'order': order,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

void main() {
  test('dump content', () {
    final adhkar = <Map<String, dynamic>>[];
    var i = 0;
    for (final d in [
      ...morningAdhkar,
      ...eveningAdhkar,
      ...ruqyahAdhkar,
      ...sleepAdhkar,
      ...wakingAdhkar,
      ...afterPrayerAdhkar,
      ...tasbeehAdhkar,
    ]) {
      adhkar.add(dhikrJson(d, ++i));
    }

    final anime = animatedProphetStories
        .map((s) => {
              'id': s.id,
              'titleAr': s.titleAr,
              'titleEn': s.titleEn,
              'prophetNameAr': s.prophetNameAr,
              'prophetNameEn': s.prophetNameEn,
              'descriptionAr': s.descriptionAr,
              'descriptionEn': s.descriptionEn,
              'category': s.category.name,
              'videoUrl': s.videoUrl,
              'duration': s.durationOrEpisodes,
              'durationOrEpisodes': s.durationOrEpisodes,
              'customThumbnail': s.customThumbnail,
              'isFeatured': s.isFeatured,
              'tag': s.tag,
              'isActive': s.isActive,
              'seriesId': s.seriesId,
              'seriesTitleAr': s.seriesTitleAr,
              'seriesTitleEn': s.seriesTitleEn,
              'episodeNumber': s.episodeNumber,
              'episodeTitleAr': s.episodeTitleAr,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();

    final shaarawi = organizedShaarawiLessons
        .map((l) => {
              'id': l.id,
              'titleAr': l.titleAr,
              'titleEn': l.titleEn,
              'descriptionAr': l.descriptionAr,
              'descriptionEn': l.descriptionEn,
              'category': l.category.name,
              'videoUrl': l.videoUrl,
              'duration': l.duration,
              'customThumbnail': l.customThumbnail,
              'isFeatured': l.isFeatured,
              'badge': l.badge,
              'seriesId': l.seriesId,
              'seriesTitleAr': l.seriesTitleAr,
              'seriesTitleEn': l.seriesTitleEn,
              'partNumber': l.partNumber,
              'partTitleAr': l.partTitleAr,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();

    final hadith = authenticHadiths
        .map((h) => {
              'id': h.id,
              'title': h.title,
              'arabic': h.arabic,
              'narrator': h.narrator,
              'source': h.source,
              'explanation': h.explanation,
              'category': h.category,
            })
        .toList();

    final riyad = riyadHadiths
        .map((h) => {
              'id': h.id,
              'title': h.title,
              'arabic': h.arabic,
              'narrator': h.narrator,
              'source': h.source,
              'explanation': h.explanation,
              'category': h.category,
            })
        .toList();

    final companions = [
      ...menCompanionsList,
      ...womenCompanionsList,
    ]
        .map((c) => {
              'id': c.id,
              'category': c.category.name,
              'nameAr': c.nameAr,
              'nameEn': c.nameEn,
              'titleAr': c.titleAr,
              'titleEn': c.titleEn,
              'emoji': c.emoji,
              'summaryAr': c.summaryAr,
              'summaryEn': c.summaryEn,
              'storyAr': c.storyAr,
              'storyEn': c.storyEn,
              'lessonsAr': c.lessonsAr,
              'lessonsEn': c.lessonsEn,
              'famousQuoteAr': c.famousQuoteAr,
              'famousQuoteEn': c.famousQuoteEn,
              'readTimeMinutes': c.readTimeMinutes,
              'milestonesAr': c.milestonesAr,
              'milestonesEn': c.milestonesEn,
              'virtuesAr': c.virtuesAr,
              'virtuesEn': c.virtuesEn,
            })
        .toList();

    final soul = soulRemediesList
        .map((s) => {
              'id': s.id,
              'feelingAr': s.feelingAr,
              'feelingEn': s.feelingEn,
              'emoji': s.emoji,
              'descriptionAr': s.descriptionAr,
              'subtitleAr': s.subtitleAr,
              'categoryKey': s.categoryKey,
              'accentColor': s.accentColor.value,
              'gradientColors':
                  s.gradientColors.map((c) => c.value).toList(),
              'ayahs': s.ayahs
                  .map((a) => {
                        'ayah': a.ayah,
                        'surah': a.surah,
                        'translation': a.translation,
                      })
                  .toList(),
              'duas': s.duas
                  .map((d) => {
                        'dua': d.dua,
                        'source': d.source,
                        'repeat': d.repeat,
                        'note': d.note,
                      })
                  .toList(),
              'solacePointsAr': s.solacePointsAr,
              'solacePointsEn': s.solacePointsEn,
            })
        .toList();

    final quran = quranSurahs
        .map((s) => {
              'number': s.number,
              'name': s.name,
              'englishName': s.englishName,
              'englishTranslation': s.englishTranslation,
              'numberOfAyahs': s.numberOfAyahs,
              'revelationType': s.revelationType,
              'page': s.page,
            })
        .toList();

    final out = {
      'adhkar': adhkar,
      'anime_stories': anime,
      'shaarawi_lessons': shaarawi,
      'hadith': hadith,
      'riyad_hadith': riyad,
      'companions': companions,
      'soul_remedies': soul,
      'quran_surahs': quran,
      'counts': {
        'adhkar': adhkar.length,
        'anime': anime.length,
        'shaarawi': shaarawi.length,
        'hadith': hadith.length,
        'riyad': riyad.length,
        'companions': companions.length,
        'soul': soul.length,
        'quran': quran.length,
      },
    };

    final dir = Directory('tools');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('tools/content_dump.json');
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
    // ignore: avoid_print
    print('Wrote ${file.path} counts=${out['counts']}');
    expect(adhkar.length, greaterThan(50));
    expect(anime.length, greaterThan(5));
    expect(shaarawi.length, greaterThan(5));
    expect(riyad.length, greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
