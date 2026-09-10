import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/state/app_state.dart';
import 'package:adhkar/services/storage.dart';
import 'package:adhkar/screens/quran_mushaf_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('verify QuranMushafScreen renders without overflow on phone screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = DhikrStorage();
    final appState = AppState(storage: storage);
    await appState.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: QuranMushafScreen(initialPage: 536),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QuranMushafScreen), findsOneWidget);

    // Verify Surah Progress indicator is present
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    // Verify Mode Toggle Icon (swap_vert_rounded in horizontal mode)
    final toggleIconFinder = find.byIcon(Icons.swap_vert_rounded);
    expect(toggleIconFinder, findsOneWidget);

    // Tap toggle icon to switch to vertical mode
    await tester.tap(toggleIconFinder);
    await tester.pumpAndSettle();

    // Now mode should be vertical with swap_horiz_rounded icon
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });
}
