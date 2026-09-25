import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'screens/jawami_dhikr_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_control_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_radio_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'services/prayer_alert_service.dart';
import 'services/remote_content_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'types/adhkar.dart';
import 'widgets/bottom_nav.dart';

/// Root application shell: holds bottom navigation, RTL/LTR switching via
/// `MaterialApp` locale, theme switching, and the reading route.
class DhikrApp extends StatefulWidget {
  const DhikrApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<DhikrApp> createState() => _DhikrAppState();
}

class _DhikrAppState extends State<DhikrApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appState,
      child: _Shell(navigatorKey: _navigatorKey),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;

    final title = AppStrings.t(lang, 'app_name');

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: title,
      theme: DhikrTheme.light(),
      darkTheme: DhikrTheme.dark(),
      themeMode: switch (appState.themeMode) {
        ThemeModeSetting.system => ThemeMode.system,
        ThemeModeSetting.light => ThemeMode.light,
        ThemeModeSetting.dark => ThemeMode.dark,
      },
      locale: Locale(lang == AppLanguage.arabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => title,
      home: const _Gate(),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RemoteContentService.instance,
      builder: (context, _) {
        if (RemoteContentService.instance.isMaintenanceMode) {
          return const MaintenanceScreen();
        }

        final appState = context.watch<AppState>();

        if (!appState.loaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }

        if (!appState.hasCompletedOnboarding) {
          return OnboardingScreen(
            onFinished: (l) async {
              await appState.completeOnboarding(l);
            },
          );
        }

        if (!appState.hasCompletedPermissionsSetup) {
          return const PermissionsControlScreen();
        }

        return const _MainScaffold();
      },
    );
  }
}

/// The scaffold hosting bottom navigation and the six main tabs.
class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().checkDayRollover();
      // A past adhan the user never stopped is cleared as soon as the app comes
      // back, so the shade keeps only today's azans while the current one is
      // left completely alone.
      unawaited(PrayerAlertService.instance.cleanupStaleAdhanNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    final pages = <Widget>[
      HomeScreen(onOpenCategory: (category) => _openReading(category)),
      const TasbihScreen(),
      const QuranRadioScreen(),
      const PrayerTimesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        language: lang,
      ),
    );
  }

  void _openReading(DhikrCategory category) {
    if (category == DhikrCategory.tasbeeh) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const JawamiDhikrScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }
    final lang = context.read<AppState>().language;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(category: category, language: lang),
        settings: const RouteSettings(name: '/reading'),
        fullscreenDialog: true,
      ),
    );
  }
}
