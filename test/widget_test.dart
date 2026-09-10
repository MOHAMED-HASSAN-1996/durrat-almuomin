import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adhkar/app.dart';
import 'package:adhkar/services/storage.dart';
import 'package:adhkar/state/app_state.dart';
import 'package:adhkar/types/adhkar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<(AppState, DhikrStorage)> buildApp() async {
    final storage = DhikrStorage();
    final state = AppState(storage: storage);
    await state.load();
    // The UI strings asserted below are the English ones; mark language as chosen
    // so the _Gate does not show the first-launch picker in tests.
    await state.setLanguageWithChoice(AppLanguage.english);
    // Save location so _Gate does not stop on SetupPermissionsScreen
    await storage.saveLocation(
      lat: 30.0444,
      lng: 31.2357,
      cityAr: 'القاهرة',
      cityEn: 'Cairo',
    );
    return (state, storage);
  }

  testWidgets('app boots to home with both category cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (state, _) = await buildApp();
    await tester.pumpWidget(DhikrApp(appState: state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sakinah'), findsOneWidget);
    expect(find.text('Morning Adhkar'), findsOneWidget);
    expect(find.text('Evening Adhkar'), findsOneWidget);
  });

  testWidgets('bottom navigation opens Radio and Settings with History inside', (tester) async {
    final (state, _) = await buildApp();
    await tester.pumpWidget(DhikrApp(appState: state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Radio is in bottom nav
    await tester.tap(find.text('Radio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Quran Radio'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('home screen displays all paired cards and full-width radio', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (state, _) = await buildApp();
    await tester.pumpWidget(DhikrApp(appState: state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // High impact and service cards
    expect(find.text('Holy Quran'), findsOneWidget);
    expect(find.text('Cairo Quran Radio'), findsOneWidget);
    expect(find.text('Companions'), findsOneWidget);
    expect(find.text('Soul Remedy'), findsOneWidget);
    expect(find.text("Jawami' Dhikr"), findsOneWidget);
    expect(find.text('Prayer Commitment'), findsOneWidget);
    expect(find.text('Prophetic Hadiths'), findsOneWidget);
    expect(find.text('Shaarawi Lessons'), findsOneWidget);
    expect(find.text('Religious Stories'), findsOneWidget);

    // Sleep adhkar and tasbih cards must NOT be on Home screen
    expect(find.text('Sleep Adhkar'), findsNothing);
  });

  testWidgets('prayer screen displays streak and daily 5 prayers tasks card', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (state, _) = await buildApp();
    await tester.pumpWidget(DhikrApp(appState: state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Prayer tab in BottomNav
    await tester.tap(find.text('Prayer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Streak tasks card must exist on Prayer screen
    expect(find.textContaining('Streak'), findsOneWidget);
    expect(find.textContaining('/ 5 prayers'), findsOneWidget);
    expect(find.text('Fajr'), findsWidgets);
  });
}