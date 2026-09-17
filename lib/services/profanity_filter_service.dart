/// Comprehensive profanity and inappropriate content filter for prayers, comments, and public names.
class ProfanityFilterService {
  ProfanityFilterService._();

  static const List<String> _forbiddenWords = [
    // سب وقذف وشتائم عامة
    'كلب', 'حيوان', 'حمار', 'غبي', 'حقير', 'تافه', 'سافل', 'وسخ', 'نذل', 'واطي',
    'قذر', 'لعنة', 'ملعون', 'ابن الكلب', 'يا كلب', 'يا حمار', 'يا غبي', 'خنزير',
    'ابن حرام', 'ابن الحرام', 'ابن زنا', 'عرص', 'شرموط', 'شرموطة', 'قحبة', 'منيوك',
    'خول', 'وسخة', 'سافلة', 'حقيرة', 'كذاب', 'نصاب', 'حرامي', 'مجرم', 'سارق',
    'كس', 'طيز', 'زب', 'فحل', 'دعارة', 'عاهرة', 'ديوث', 'عرصة', 'قحاب', 'منايك',
    'قواد', 'لوطي', 'شاذ', 'زنا', 'سكس', 'نيك', 'ينيك', 'تناك', 'فسق', 'فجور',
    // تعبيرات مسيئة أخرى
    'امك', 'ابوك', 'اختك', 'يلعن', 'اللعنة', 'يلعنك', 'الله يلعن', 'جهنم وبئس',
    'حرق دم', 'موت', 'عزرائيل ياخذك', 'فطس', 'تفو', 'تتفو',
    // إنجليزي
    'fuck', 'bitch', 'asshole', 'dick', 'pussy', 'bastard', 'shit', 'cunt', 'damn', 'whore', 'slut'
  ];

  /// Normalize Arabic text for accurate matching (remove harakat, tatweel, unify alef/ya)
  static String _normalize(String input) {
    var text = input.trim().toLowerCase();
    // إزالة التشكيل والتنوين
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // إزالة التطويل والكشيدة
    text = text.replaceAll('\u0640', '');
    // توحيد الألفات
    text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');
    // توحيد الياء والألف المقصورة
    text = text.replaceAll('ى', 'ي');
    // توحيد التاء المربوطة والهاء
    text = text.replaceAll('ة', 'ه');
    // إزالة تكرار الحروف المتتالية أكثر من مرتين (مثل: ككككلب -> كلب)
    text = text.replaceAll(RegExp(r'(.)\1{2,}'), r'\1');
    return text;
  }

  /// Check if the text contains any forbidden words
  static bool hasForbiddenWords(String text) {
    if (text.trim().isEmpty) return false;
    final normalized = _normalize(text);
    final words = normalized.split(RegExp(r'[\s,.\-_!؟?()]+'));

    for (final word in words) {
      if (word.isEmpty) continue;
      for (final forbidden in _forbiddenWords) {
        final normForbidden = _normalize(forbidden);
        if (word == normForbidden || word.contains(normForbidden)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Finds the first forbidden word found in the text, if any
  static String? findForbiddenWord(String text) {
    if (text.trim().isEmpty) return null;
    final normalized = _normalize(text);
    final words = normalized.split(RegExp(r'[\s,.\-_!؟?()]+'));

    for (final word in words) {
      if (word.isEmpty) continue;
      for (final forbidden in _forbiddenWords) {
        final normForbidden = _normalize(forbidden);
        if (word == normForbidden || word.contains(normForbidden)) {
          return forbidden;
        }
      }
    }
    return null;
  }

  static const List<String> _donationKeywords = [
    'فودافون كاش',
    'انستاباي',
    'انستا باي',
    'حساب بنكي',
    'تحويل فلوس',
    'تبرع مالي',
    'تبرعوا',
    'محفظه كاش',
    'محفظة كاش',
    'ارسل فلوس',
    'فلوس علاج',
    'instapay',
    'vodafone cash',
  ];

  /// Detect web URLs, domains, or messaging links
  static bool hasPhoneOrLink(String text) {
    // 1. Detect web URLs or links
    final urlPattern = RegExp(
      r'(https?:\/\/|www\.|t\.me\/|wa\.me\/|[a-zA-Z0-9-]+\.(com|net|org|io|app|me|info|xyz))',
      caseSensitive: false,
    );
    if (urlPattern.hasMatch(text)) return true;

    // 2. Normalize Arabic and English digits
    var digitsOnly = text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    // Count sequence of digits (e.g. phone numbers or bank accounts)
    final compactDigits = digitsOnly.replaceAll(RegExp(r'[^0-9]'), '');
    if (compactDigits.length >= 8) {
      return true;
    }

    return false;
  }

  /// Detect financial or donation requests
  static bool hasFinancialRequest(String text) {
    final lower = _normalize(text);
    for (final kw in _donationKeywords) {
      if (lower.contains(_normalize(kw))) return true;
    }
    return false;
  }

  /// Form validator helper
  static String? validateText(String? text, {String fieldName = 'النص'}) {
    if (text == null || text.trim().isEmpty) return null;
    final badWord = findForbiddenWord(text);
    if (badWord != null) {
      return 'عذراً، يحتوي $fieldName على كلمات غير لائقة بقدسية الدعاء';
    }
    if (hasPhoneOrLink(text)) {
      return 'عذراً، يُمنع إدراج أرقام الهواتف أو روابط المواقع حفاظاً على أمان المصلين';
    }
    if (hasFinancialRequest(text)) {
      return 'عذراً، يُمنع إدراج طلبات التبرعات أو المحافظ المالية، المنصة مخصصة للدعاء الخالص فقط';
    }
    return null;
  }
}
