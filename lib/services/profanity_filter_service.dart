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

  // ════════════════════════════════════════════════════════════════════════
  //  كلمات جمع التبرعات المحظورة
  //  Google Play Policy: لا يُسمح بجمع التبرعات أو المدفوعات في تطبيق
  //  بدون اتفاقية Merchant مع Google Play. هذه القائمة تحمي التطبيق.
  // ════════════════════════════════════════════════════════════════════════
  static const List<String> _donationKeywords = [
    // محافظ إلكترونية مصرية وعربية
    'فودافون كاش',
    'فودافون كاشي',
    'vodafone cash',
    'انستاباي',
    'انستا باي',
    'instapay',
    'محفظة كاش',
    'محفظه كاش',
    'ووي',
    'wepay',
    'فوري',
    'fawry',
    'بيميتش',
    'bmetech',
    'اورانج كاش',
    'orange cash',
    'اتصالات كاش',
    'etisalat cash',
    'باي موبايل',
    'pay mobile',

    // طلبات التحويل البنكي
    'رقم حساب',
    'رقم الحساب',
    'حساب بنكي',
    'iban',
    'ايبان',
    'حوالة بنكية',
    'تحويل بنكي',
    'swift',
    'تحويل مصرفي',

    // صياغات طلب التبرع
    'تبرع',
    'تبرعوا',
    'تبرعات',
    'تبرع مالي',
    'تبرع لي',
    'تبرع لنا',
    'تبرع لأجل',
    'تبرع الان',
    'تبرع الآن',
    'مساعدة مادية',
    'دعم مادي',
    'مساعده ماديه',
    'إعانة مالية',
    'دعم مالي',
    'مساعدة مالية',
    'مادي',
    'محتاج مساعدة مالية',
    'ارسل فلوس',
    'ابعت فلوس',
    'send money',
    'فلوس علاج',
    'تكاليف علاج',
    'مصاريف علاج',
    'تكاليف عملية',
    'محتاج مبلغ',
    'محتاج فلوس',
    'محتاج مصاريف',
    'نفقات علاج',
    'فلوس دواء',
    'ثمن دواء',

    // عملات
    'دولار',
    'يورو',
    'ريال',
    'جنيه',
    'درهم',
    'دينار',
    '\$',
    '€',
    '£',

    // جمع تبرعات
    'حملة تبرع',
    'تبرع خيري',
    'صندوق خيري',
    'صدقة جارية',
    'الصدقة الجارية',
    'كفالة',
    'جمع تبرعات',
    'جمعية خيرية',
    'موقع تبرع',
    'crowdfunding',
    'gofundme',
    'paypal',
    'باي بال',
    'crypto',
    'بيتكوين',
    'bitcoin',

    // الدفع الإلكتروني
    'اشترك',
    'اشتراك',
    'ادفع',
    'دفع',
    'ادفع الان',
    'اشتري',
    'اشتر',
    'buy now',
    'pay now',
    'subscribe',
    'payment',
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

  /// نتيجة الفحص الكاملة
  static ({ViolationType type, String? message}) checkContent(String text) {
    if (text.trim().isEmpty) {
      return (type: ViolationType.none, message: null);
    }

    final badWord = findForbiddenWord(text);
    if (badWord != null) {
      return (
        type: ViolationType.profanity,
        message: '⛔ كلمة محظورة\n\nيحتوي الدعاء على كلمات غير لائقة بمقام الدعاء والمناجاة. يرجى مراجعة النص.',
      );
    }

    if (hasPhoneOrLink(text)) {
      return (
        type: ViolationType.phoneOrLink,
        message: '⛔ كلمة محظورة\n\nيُمنع إدراج أرقام الهواتف أو روابط المواقع. هذه المنصة مخصصة للدعاء الخالص فقط.',
      );
    }

    if (hasFinancialRequest(text)) {
      return (
        type: ViolationType.financialRequest,
        message: '⛔ كلمة محظورة\n\nيُمنع إدراج طلبات التبرعات أو المحافظ المالية أو ذكر مبالغ.\n\nهذه المنصة مخصصة للدعاء والتراحم الروحي فقط، وليست منصة جمع تبرعات.',
      );
    }

    return (type: ViolationType.none, message: null);
  }

  /// Form validator helper — يُعيد رسالة الخطأ إذا وُجد مخالفة
  static String? validateText(String? text, {String fieldName = 'النص'}) {
    if (text == null || text.trim().isEmpty) return null;
    final result = checkContent(text);
    return result.message;
  }
}

/// نوع المخالفة
enum ViolationType { profanity, phoneOrLink, financialRequest, none }
