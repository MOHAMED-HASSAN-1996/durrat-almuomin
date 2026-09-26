import 'package:flutter/services.dart';

import 'prayer_alert_service.dart' show PlatformPermissions;

/// اهتزاز موحّد لنقرات العدّ في التطبيق.
///
/// كل نقرة ذكر أو سبحة لازم تنزل تحت إصبع المستخدم بالإحساس، مو بس عداد
/// بصري. القوة الحقيقية تأتي من الطبقة الأصلية (نبضات متتابعة بأقصى سعة)
/// لأن فلاتر `HapticFeedback` قوتها ثابتة من النظام وما تنفع تُقوّى، فالمساعد
/// يرجع لها على iOS والويب بس عشان ما تضيعش النقرة.
///
/// الاستخدام:
/// ```dart
/// await Haptics.tap();      // نقرة عدّ عادية
/// await Haptics.complete(); // إتمام الذكر أو الدورة
/// ```
class Haptics {
  const Haptics._();

  /// نقرة العدّ العادية.
  static Future<void> tap() => _pulse(1);

  /// إتمام العدّ أو الدورة — نبضة أطول وأوضح.
  static Future<void> complete() => _pulse(2);

  static Future<void> _pulse(int intensity) async {
    final handled = await PlatformPermissions.tapVibration(
      intensity: intensity,
    );
    if (handled) return;
    // iOS أو الويب أو جهاز ما بيتهتزّش: فلاتر النظام عشان متضيعش النقرة.
    if (intensity >= 2) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }
}
