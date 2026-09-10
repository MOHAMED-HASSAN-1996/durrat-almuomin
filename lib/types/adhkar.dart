/// Core data model for the DHIKR app.
///
/// This file defines the single source of truth data types used across the
/// application. It is intentionally free of business logic so it can be shared
/// by the UI layer, the storage layer, and the test suite.
library;

enum DhikrCategory {
  morning,
  evening,
  ruqyah,
  sleep,
  waking,
  afterPrayer,
  tasbeeh,
}

extension DhikrCategoryX on DhikrCategory {
  String get id => switch (this) {
        DhikrCategory.morning => 'morning',
        DhikrCategory.evening => 'evening',
        DhikrCategory.ruqyah => 'ruqyah',
        DhikrCategory.sleep => 'sleep',
        DhikrCategory.waking => 'waking',
        DhikrCategory.afterPrayer => 'afterPrayer',
        DhikrCategory.tasbeeh => 'tasbeeh',
      };

  static DhikrCategory? fromId(String id) {
    for (final c in DhikrCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// A single Adhkar item with full Arabic (vocalized) text, translation,
/// repetition target, source reference, virtue (fadl), and optional local audio path.
class Dhikr {
  const Dhikr({
    required this.id,
    required this.category,
    required this.arabic,
    required this.english,
    required this.repeat,
    required this.source,
    this.virtue,
    this.virtueEn,
    this.audio,
    this.quranAudio,
  });

  final String id;
  final DhikrCategory category;
  final String arabic;
  final String english;
  final int repeat;
  final String source;
  /// فضل الذكر — short authentic virtue text shown next to source.
  final String? virtue;
  final String? virtueEn;
  /// Path to a bundled audio asset (TTS voice), when one ships.
  final String? audio;
  /// Ordered URLs of real recorded recitation (Quranic adhkar only).
  /// When present the "listen" button streams these instead of [audio].
  final List<String>? quranAudio;

  /// True when this dhikr has a real-recitation stream to play.
  bool get hasQuranAudio => quranAudio != null && quranAudio!.isNotEmpty;

  /// Stable identifier of the playable source, used by the audio button to
  /// know whether this dhikr is the one currently playing.
  String? get audioKey => hasQuranAudio ? 'quran:$id' : audio;

  /// Raw JSON key mapping, so the same shape is used for stored/imported data.
  factory Dhikr.fromJson(Map<String, dynamic> json) {
    final cat = DhikrCategoryX.fromId(json['category'] as String? ?? '');
    if (cat == null) {
      throw const FormatException('Invalid category in Dhikr JSON');
    }
    return Dhikr(
      id: json['id'] as String? ?? '',
      category: cat,
      arabic: json['arabic'] as String? ?? '',
      english: json['english'] as String? ?? '',
      repeat: (json['repeat'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      virtue: json['virtue'] as String?,
      virtueEn: json['virtueEn'] as String?,
      audio: json['audio'] as String?,
      quranAudio: (json['quranAudio'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.id,
        'arabic': arabic,
        'english': english,
        'repeat': repeat,
        'source': source,
        if (virtue != null) 'virtue': virtue,
        if (virtueEn != null) 'virtueEn': virtueEn,
        if (audio != null) 'audio': audio,
        if (quranAudio != null) 'quranAudio': quranAudio,
      };
}

/// Snapshot of a single Dhikr's progress within a session. `current` is the
/// number of repetitions the user has tapped, and is guaranteed to never exceed
/// [Dhikr.repeat] at the model layer.
class DhikrProgress {
  const DhikrProgress({required this.current, required this.isCompleted});

  final int current;
  final bool isCompleted;

  DhikrProgress copyWith({int? current, bool? isCompleted}) {
    return DhikrProgress(
      current: current ?? this.current,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// The progress of a whole category (morning or evening) for one calendar day.
class CategoryProgress {
  const CategoryProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  double get fraction => total == 0 ? 0 : completed / total;

  int get percent => (fraction * 100).round();

  int get remaining => total - completed;

  bool get isComplete => total > 0 && completed >= total;
}

/// A persisted snapshot of a single day's progress across both categories.
class DayProgress {
  const DayProgress({
    required this.date,
    required this.morning,
    required this.evening,
  });

  final String date; // ISO yyyy-MM-dd, local calendar date
  final CategoryProgress morning;
  final CategoryProgress evening;
}

/// User-selectable application language.
enum AppLanguage { arabic, english }

/// User-selectable theme mode.
enum ThemeModeSetting { system, light, dark }

/// Persisted user settings.
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.arabic,
    this.themeMode = ThemeModeSetting.light,
    this.audioEnabled = true,
    this.hasChosenLanguage = false,
  });

  final AppLanguage language;
  final ThemeModeSetting themeMode;
  final bool audioEnabled;
  final bool hasChosenLanguage;

  AppSettings copyWith({
    AppLanguage? language,
    ThemeModeSetting? themeMode,
    bool? audioEnabled,
    bool? hasChosenLanguage,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      hasChosenLanguage: hasChosenLanguage ?? this.hasChosenLanguage,
    );
  }

  bool get isRtl => language == AppLanguage.arabic;
}
