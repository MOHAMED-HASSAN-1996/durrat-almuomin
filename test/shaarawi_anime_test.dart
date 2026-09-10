import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:adhkar/data/shaarawi_data.dart';
import 'package:adhkar/data/anime_stories_data.dart';
import 'package:adhkar/screens/shaarawi_screen.dart';
import 'package:adhkar/screens/anime_stories_screen.dart';
import 'package:adhkar/state/app_state.dart';

void main() {
  test('Shaarawi data is organized with categories and lessons', () {
    expect(organizedShaarawiLessons.isNotEmpty, true);
    expect(shaarawiPlaylists.isNotEmpty, true);

    // Verify all categories have lessons
    final tafsirLessons = organizedShaarawiLessons
        .where((l) => l.category == ShaarawiCategory.tafsir);
    expect(tafsirLessons.isNotEmpty, true);

    final faithLessons = organizedShaarawiLessons
        .where((l) => l.category == ShaarawiCategory.faith);
    expect(faithLessons.isNotEmpty, true);

    final lifeLessons = organizedShaarawiLessons
        .where((l) => l.category == ShaarawiCategory.life);
    expect(lifeLessons.isNotEmpty, true);

    final seerahLessons = organizedShaarawiLessons
        .where((l) => l.category == ShaarawiCategory.seerah);
    expect(seerahLessons.isNotEmpty, true);

    final gemsLessons = organizedShaarawiLessons
        .where((l) => l.category == ShaarawiCategory.gems);
    expect(gemsLessons.isNotEmpty, true);
  });

  test('Anime Prophet Stories data is structured with prophets and series', () {
    expect(animatedProphetStories.isNotEmpty, true);

    final khalidStories = animatedProphetStories
        .where((s) => s.category == AnimeCategory.khalid);
    expect(khalidStories.isNotEmpty, true);

    final quranSeries = animatedProphetStories
        .where((s) => s.category == AnimeCategory.quranSeries);
    expect(quranSeries.isNotEmpty, true);
  });

  testWidgets('ShaarawiScreen renders search and series', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(
          home: ShaarawiScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('دروس الشيخ الشعراوي'), findsOneWidget);
  });

  testWidgets('AnimeStoriesScreen renders search and stories', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(
          home: AnimeStoriesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('قصص دينية أنمي'), findsOneWidget);
  });
}
