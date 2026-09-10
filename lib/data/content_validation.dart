import '../types/adhkar.dart';
import 'adhkar.dart';

/// Validates the built-in Adhkar content and returns per-item errors.
///
/// The application calls [validateAdhkarList] at startup. If any item is
/// malformed the UI must degrade gracefully (skip the broken item rather than
/// crash the whole screen). This is a safety net over the hand-verified data.
class ContentValidationResult {
  const ContentValidationResult({required this.errors, required this.valid});

  final List<String> errors;
  final List<Dhikr> valid;

  bool get isClean => errors.isEmpty;
}

ContentValidationResult validateAdhkarList(List<Dhikr> list) {
  final errors = <String>[];
  final seenIds = <String>{};
  final valid = <Dhikr>[];

  for (final d in list) {
    final itemErrors = <String>[];

    if (d.id.isEmpty) {
      itemErrors.add('Empty id');
    } else if (!seenIds.add(d.id)) {
      itemErrors.add('Duplicate id: ${d.id}');
    }
    if (d.arabic.trim().isEmpty) {
      itemErrors.add('${d.id}: Arabic text is empty');
    }
    if (d.english.trim().isEmpty) {
      itemErrors.add('${d.id}: English translation is empty');
    }
    if (d.repeat <= 0) {
      itemErrors.add('${d.id}: repeat must be > 0');
    }
    if (d.source.trim().isEmpty) {
      itemErrors.add('${d.id}: source is empty');
    }
    // any defined category is valid (morning/evening/ruqyah)
    if (!DhikrCategory.values.contains(d.category)) {
      itemErrors.add('${d.id}: invalid category');
    }

    if (itemErrors.isEmpty) {
      valid.add(d);
    } else {
      errors.addAll(itemErrors);
    }
  }
  return ContentValidationResult(errors: errors, valid: valid);
}

/// A single aggregate validation over all built-in content.
ContentValidationResult validateAllBuiltIn() {
  final morning = validateAdhkarList(morningAdhkar);
  final evening = validateAdhkarList(eveningAdhkar);
  final ruqyah = validateAdhkarList(ruqyahAdhkar);
  final sleep = validateAdhkarList(sleepAdhkar);
  final waking = validateAdhkarList(wakingAdhkar);
  final afterPrayer = validateAdhkarList(afterPrayerAdhkar);
  final tasbeeh = validateAdhkarList(tasbeehAdhkar);
  return ContentValidationResult(
    errors: [
      ...morning.errors,
      ...evening.errors,
      ...ruqyah.errors,
      ...sleep.errors,
      ...waking.errors,
      ...afterPrayer.errors,
      ...tasbeeh.errors,
    ],
    valid: [
      ...morning.valid,
      ...evening.valid,
      ...ruqyah.valid,
      ...sleep.valid,
      ...waking.valid,
      ...afterPrayer.valid,
      ...tasbeeh.valid,
    ],
  );
}

/// Returns the built-in content for a category, skipping any malformed items.
List<Dhikr> getBuiltInAdhkar(DhikrCategory category) {
  final raw = switch (category) {
    DhikrCategory.morning => morningAdhkar,
    DhikrCategory.evening => eveningAdhkar,
    DhikrCategory.ruqyah => ruqyahAdhkar,
    DhikrCategory.sleep => sleepAdhkar,
    DhikrCategory.waking => wakingAdhkar,
    DhikrCategory.afterPrayer => afterPrayerAdhkar,
    DhikrCategory.tasbeeh => tasbeehAdhkar,
  };
  return validateAdhkarList(raw).valid;
}
