import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Currency metadata (ISO 4217 code + display labels in Arabic/English).
class CurrencyInfo {
  final String code;
  final String symbol;
  final String nameAr;
  final String nameEn;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.nameAr,
    required this.nameEn,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'symbol': symbol,
        'nameAr': nameAr,
        'nameEn': nameEn,
      };

  static CurrencyInfo? fromMap(Map<String, dynamic> map) {
    final code = map['code'] as String?;
    if (code == null || code.isEmpty) return null;
    return CurrencyInfo(
      code: code,
      symbol: map['symbol'] as String? ?? code,
      nameAr: map['nameAr'] as String? ?? code,
      nameEn: map['nameEn'] as String? ?? code,
    );
  }
}

/// Detected geographic context: the currency of the user's country plus a
/// human-readable country label (used in the نِصاب calculator UI).
class DetectedCurrency {
  final CurrencyInfo currency;
  final String countryCode;
  final String countryAr;
  final String countryEn;

  const DetectedCurrency({
    required this.currency,
    required this.countryCode,
    required this.countryAr,
    required this.countryEn,
  });
}

/// Live precious-metal prices converted to the *local currency* of the user's
/// country (detected from device locale then IP geolocation, EGP fallback).
///
/// Tries several free, key-less sources and uses the first one that works:
/// - Metals: gold-api.com -> swissquote public feed -> goldprice.org
/// - FX (USD->local): open.er-api.com -> exchangerate-api.com -> currency-api CDN
///
/// The result is an *indicative* global price converted to the local currency.
/// Local shop prices (الصاغة) include premiums and workmanship, so the user
/// can always adjust the values manually afterwards.
class LiveGoldPrices {
  final double gold24kPerGramLocal;
  final double silverPerGramLocal;
  final DateTime updatedAt;
  final bool fromCache;
  final CurrencyInfo currency;

  const LiveGoldPrices({
    required this.gold24kPerGramLocal,
    required this.silverPerGramLocal,
    required this.updatedAt,
    required this.currency,
    this.fromCache = false,
  });

  Map<String, dynamic> toMap() => {
        'gold': gold24kPerGramLocal,
        'silver': silverPerGramLocal,
        'updatedAt': updatedAt.toIso8601String(),
        'currency': currency.toMap(),
      };

  static LiveGoldPrices? fromMap(Map<String, dynamic> map) {
    try {
      final gold = (map['gold'] as num?)?.toDouble();
      final silver = (map['silver'] as num?)?.toDouble();
      final updatedAt = DateTime.tryParse(map['updatedAt'] as String? ?? '');
      if (gold == null || silver == null || updatedAt == null) return null;
      if (gold <= 0 || silver <= 0) return null;
      final currency = CurrencyInfo.fromMap(
        (map['currency'] as Map? ?? {}) as Map<String, dynamic>,
      );
      final currencyInfo = currency ??
          const CurrencyInfo(
            code: 'EGP',
            symbol: 'ج.م',
            nameAr: 'الجنيه المصري',
            nameEn: 'Egyptian Pound',
          );
      return LiveGoldPrices(
        gold24kPerGramLocal: gold,
        silverPerGramLocal: silver,
        updatedAt: updatedAt,
        currency: currencyInfo,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}

class GoldPriceService {
  GoldPriceService._();
  static final GoldPriceService instance = GoldPriceService._();

  static const _cacheKey = 'adhkar.gold_live_v1';
  static const _currencyCacheKey = 'adhkar.currency_v1';
  static const _troyOunceGrams = 31.1034768;
  static const _timeout = Duration(seconds: 15);

  static const _defaultCurrency = CurrencyInfo(
    code: 'EGP',
    symbol: 'ج.م',
    nameAr: 'الجنيه المصري',
    nameEn: 'Egyptian Pound',
  );

  /// ISO 3166-1 alpha-2 country code -> ISO 4217 currency code.
  static const Map<String, String> _countryCurrency = {
    // The Arab world + Islamic countries
    'EG': 'EGP', 'SA': 'SAR', 'AE': 'AED', 'QA': 'QAR', 'KW': 'KWD',
    'BH': 'BHD', 'OM': 'OMR', 'JO': 'JOD', 'IQ': 'IQD', 'SY': 'SYP',
    'LB': 'LBP', 'LY': 'LYD', 'TN': 'TND', 'DZ': 'DZD', 'MA': 'MAD',
    'SD': 'SDG', 'YE': 'YER', 'MR': 'MRU', 'SO': 'SOS', 'DJ': 'DJF',
    'KM': 'KMF', 'TR': 'TRY', 'AF': 'AFN', 'PK': 'PKR', 'IR': 'IRR',
    'ID': 'IDR', 'BD': 'BDT', 'NG': 'NGN',
    // Gulf / Levant / North Africa aliases covered above.
    // West & Central Africa (CFA zones)
    'TD': 'XAF', 'NE': 'XOF', 'ML': 'XOF', 'BF': 'XOF', 'BJ': 'XOF',
    'CI': 'XOF', 'SN': 'XOF', 'GW': 'XOF', 'TG': 'XOF', 'GN': 'GNF',
    'GM': 'GMD', 'SL': 'SLL', 'LR': 'LRD', 'GH': 'GHS', 'CM': 'XAF',
    'GA': 'XAF', 'CG': 'XAF', 'CD': 'CDF', 'KE': 'KES', 'TZ': 'TZS',
    'UG': 'UGX', 'RW': 'RWF', 'BI': 'BIF', 'ET': 'ETB', 'ER': 'ERN',
    // Western Europe & North America
    'US': 'USD', 'CA': 'CAD', 'GB': 'GBP', 'IE': 'EUR', 'CH': 'CHF',
    'FR': 'EUR', 'DE': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR',
    'BE': 'EUR', 'PT': 'EUR', 'GR': 'EUR', 'AT': 'EUR', 'FI': 'EUR',
    'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK',
    'HU': 'HUF', 'RO': 'RON', 'BG': 'BGN', 'UA': 'UAH', 'RU': 'RUB',
    'KZ': 'KZT', 'UZ': 'UZS', 'AZ': 'AZN', 'GE': 'GEL', 'AM': 'AMD',
    // Asia-Pacific & the rest
    'IN': 'INR', 'CN': 'CNY', 'JP': 'JPY', 'KR': 'KRW', 'AU': 'AUD',
    'NZ': 'NZD', 'SG': 'SGD', 'TH': 'THB', 'PH': 'PHP', 'VN': 'VND',
    'MY': 'MYR', 'BR': 'BRL', 'MX': 'MXN', 'AR': 'ARS',
  };

  /// ISO 3166-1 alpha-2 -> Arabic display name (best effort).
  static const Map<String, String> _countryAr = {
    'EG': 'مصر', 'SA': 'السعودية', 'AE': 'الإمارات', 'QA': 'قطر',
    'KW': 'الكويت', 'BH': 'البحرين', 'OM': 'عُمان', 'JO': 'الأردن',
    'IQ': 'العراق', 'SY': 'سوريا', 'LB': 'لبنان', 'LY': 'ليبيا',
    'TN': 'تونس', 'DZ': 'الجزائر', 'MA': 'المغرب', 'SD': 'السودان',
    'YE': 'اليمن', 'MR': 'موريتانيا', 'SO': 'الصومال', 'DJ': 'جيبوتي',
    'KM': 'جزر القمر', 'TR': 'تركيا', 'AF': 'أفغانستان', 'PK': 'باكستان',
    'IR': 'إيران', 'ID': 'إندونيسيا', 'MY': 'ماليزيا', 'BD': 'بنغلاديش',
    'NG': 'نيجيريا',
    'KD': 'السودان', 'US': 'الولايات المتحدة', 'CA': 'كندا', 'GB': 'المملكة المتحدة',
    'FR': 'فرنسا', 'DE': 'ألمانيا', 'IT': 'إيطاليا', 'ES': 'إسبانيا',
    'NL': 'هولندا', 'BE': 'بلجيكا', 'PT': 'البرتغال', 'GR': 'اليونان',
    'AT': 'النمسا', 'SE': 'السويد', 'CH': 'سويسرا', 'AU': 'أستراليا',
    'CN': 'الصين', 'JP': 'اليابان', 'IN': 'الهند', 'RU': 'روسيا',
  };

  /// Common currency labels. Falls back to [CurrencyInfo] with the ISO code
  /// as its display symbol for anything not listed here.
  static const Map<String, CurrencyInfo> _catalog = {
    'EGP': CurrencyInfo(code: 'EGP', symbol: 'ج.م', nameAr: 'الجنيه المصري', nameEn: 'Egyptian Pound'),
    'SAR': CurrencyInfo(code: 'SAR', symbol: 'ر.س', nameAr: 'الريال السعودي', nameEn: 'Saudi Riyal'),
    'AED': CurrencyInfo(code: 'AED', symbol: 'د.إ', nameAr: 'الدرهم الإماراتي', nameEn: 'UAE Dirham'),
    'QAR': CurrencyInfo(code: 'QAR', symbol: 'ر.ق', nameAr: 'الريال القطري', nameEn: 'Qatari Riyal'),
    'KWD': CurrencyInfo(code: 'KWD', symbol: 'د.ك', nameAr: 'الدينار الكويتي', nameEn: 'Kuwaiti Dinar'),
    'BHD': CurrencyInfo(code: 'BHD', symbol: 'د.ب', nameAr: 'الدينار البحريني', nameEn: 'Bahraini Dinar'),
    'OMR': CurrencyInfo(code: 'OMR', symbol: 'ر.ع', nameAr: 'الريال العماني', nameEn: 'Omani Rial'),
    'JOD': CurrencyInfo(code: 'JOD', symbol: 'د.أ', nameAr: 'الدينار الأردني', nameEn: 'Jordanian Dinar'),
    'IQD': CurrencyInfo(code: 'IQD', symbol: 'د.ع', nameAr: 'الدينار العراقي', nameEn: 'Iraqi Dinar'),
    'SYP': CurrencyInfo(code: 'SYP', symbol: 'ل.س', nameAr: 'الليرة السورية', nameEn: 'Syrian Pound'),
    'LBP': CurrencyInfo(code: 'LBP', symbol: 'ل.ل', nameAr: 'الليرة اللبنانية', nameEn: 'Lebanese Pound'),
    'LYD': CurrencyInfo(code: 'LYD', symbol: 'د.ل', nameAr: 'الدينار الليبي', nameEn: 'Libyan Dinar'),
    'TND': CurrencyInfo(code: 'TND', symbol: 'د.ت', nameAr: 'الدينار التونسي', nameEn: 'Tunisian Dinar'),
    'DZD': CurrencyInfo(code: 'DZD', symbol: 'د.ج', nameAr: 'الدينار الجزائري', nameEn: 'Algerian Dinar'),
    'MAD': CurrencyInfo(code: 'MAD', symbol: 'د.م', nameAr: 'الدرهم المغربي', nameEn: 'Moroccan Dirham'),
    'SDG': CurrencyInfo(code: 'SDG', symbol: 'ج.س', nameAr: 'الجنيه السوداني', nameEn: 'Sudanese Pound'),
    'YER': CurrencyInfo(code: 'YER', symbol: 'ر.ي', nameAr: 'الريال اليمني', nameEn: 'Yemeni Rial'),
    'MRU': CurrencyInfo(code: 'MRU', symbol: 'أ.م', nameAr: 'الأوقية الموريتانية', nameEn: 'Mauritanian Ouguiya'),
    'SOS': CurrencyInfo(code: 'SOS', symbol: 'ش.ص', nameAr: 'الشلن الصومالي', nameEn: 'Somali Shilling'),
    'DJF': CurrencyInfo(code: 'DJF', symbol: 'ف.ج', nameAr: 'الفرنك الجيبوتي', nameEn: 'Djiboutian Franc'),
    'KMF': CurrencyInfo(code: 'KMF', symbol: 'ف.ق', nameAr: 'الفرنك القمري', nameEn: 'Comorian Franc'),
    'TRY': CurrencyInfo(code: 'TRY', symbol: '₺', nameAr: 'الليرة التركية', nameEn: 'Turkish Lira'),
    'AFN': CurrencyInfo(code: 'AFN', symbol: '؋', nameAr: 'الأفغاني', nameEn: 'Afghan Afghani'),
    'PKR': CurrencyInfo(code: 'PKR', symbol: 'ر.ب', nameAr: 'الروبية الباكستانية', nameEn: 'Pakistani Rupee'),
    'INR': CurrencyInfo(code: 'INR', symbol: '₹', nameAr: 'الروبية الهندية', nameEn: 'Indian Rupee'),
    'BDT': CurrencyInfo(code: 'BDT', symbol: '৳', nameAr: 'التاكا البنغلاديشي', nameEn: 'Bangladeshi Taka'),
    'IRR': CurrencyInfo(code: 'IRR', symbol: '﷼', nameAr: 'الريال الإيراني', nameEn: 'Iranian Rial'),
    'IDR': CurrencyInfo(code: 'IDR', symbol: 'ر.إ', nameAr: 'الروبية الإندونيسية', nameEn: 'Indonesian Rupiah'),
    'MYR': CurrencyInfo(code: 'MYR', symbol: 'ر.م', nameAr: 'الرينغيت الماليزي', nameEn: 'Malaysian Ringgit'),
    'NGN': CurrencyInfo(code: 'NGN', symbol: '₦', nameAr: 'النيرة النيجيرية', nameEn: 'Nigerian Naira'),
    'XAF': CurrencyInfo(code: 'XAF', symbol: 'ف.س.أ', nameAr: 'فرنك وسط أفريقيا', nameEn: 'Central African CFA Franc'),
    'XOF': CurrencyInfo(code: 'XOF', symbol: 'ف.س.غ', nameAr: 'فرنك غرب أفريقيا', nameEn: 'West African CFA Franc'),
    'USD': CurrencyInfo(code: 'USD', symbol: '\$', nameAr: 'الدولار الأمريكي', nameEn: 'US Dollar'),
    'CAD': CurrencyInfo(code: 'CAD', symbol: 'C\$', nameAr: 'الدولار الكندي', nameEn: 'Canadian Dollar'),
    'GBP': CurrencyInfo(code: 'GBP', symbol: '£', nameAr: 'الجنيه الإسترليني', nameEn: 'British Pound'),
    'EUR': CurrencyInfo(code: 'EUR', symbol: '€', nameAr: 'اليورو', nameEn: 'Euro'),
    'CHF': CurrencyInfo(code: 'CHF', symbol: 'CHF', nameAr: 'الفرنك السويسري', nameEn: 'Swiss Franc'),
    'SEK': CurrencyInfo(code: 'SEK', symbol: 'kr', nameAr: 'الكرونة السويدية', nameEn: 'Swedish Krona'),
    'NOK': CurrencyInfo(code: 'NOK', symbol: 'kr', nameAr: 'الكرونة النرويجية', nameEn: 'Norwegian Krone'),
    'DKK': CurrencyInfo(code: 'DKK', symbol: 'kr', nameAr: 'الكرونة الدنماركية', nameEn: 'Danish Krone'),
    'PLN': CurrencyInfo(code: 'PLN', symbol: 'zł', nameAr: 'الزلوتي البولندي', nameEn: 'Polish Zloty'),
    'RUB': CurrencyInfo(code: 'RUB', symbol: '₽', nameAr: 'الروبل الروسي', nameEn: 'Russian Ruble'),
    'CNY': CurrencyInfo(code: 'CNY', symbol: '¥', nameAr: 'اليوان الصيني', nameEn: 'Chinese Yuan'),
    'JPY': CurrencyInfo(code: 'JPY', symbol: '¥', nameAr: 'الين الياباني', nameEn: 'Japanese Yen'),
    'AUD': CurrencyInfo(code: 'AUD', symbol: 'A\$', nameAr: 'الدولار الأسترالي', nameEn: 'Australian Dollar'),
    'NZD': CurrencyInfo(code: 'NZD', symbol: 'NZ\$', nameAr: 'الدولار النيوزيلندي', nameEn: 'New Zealand Dollar'),
    'BRL': CurrencyInfo(code: 'BRL', symbol: 'R\$', nameAr: 'الريال البرازيلي', nameEn: 'Brazilian Real'),
  };

  static CurrencyInfo _catalogFor(String code) =>
      _catalog[code] ??
      CurrencyInfo(code: code, symbol: code, nameAr: code, nameEn: code);

  Future<http.Response> _get(String url) {
    return http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AdhkarApp/1.0'},
    ).timeout(_timeout);
  }

  /// Cached detected currency (fast path), or null.
  Future<CurrencyInfo?> loadCachedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currencyCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cached = CurrencyInfo.fromMap(map);
      if (cached != null && cached.code.isNotEmpty) return cached;
    } catch (_) {}
    return null;
  }

  Future<void> _saveCurrency(CurrencyInfo currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyCacheKey, jsonEncode(currency.toMap()));
    } catch (_) {}
  }

  /// Localized label for the given country code (Arabic first, English
  /// fallback uses [engName] if provided).
  static String _countryLabel(String code, {String engName = ''}) {
    final ar = _countryAr[code];
    if (ar != null) return ar;
    if (engName.isNotEmpty) return engName;
    return code;
  }

  /// Maps a free-form country name (Arabic or English, as stored by the
  /// location picker / home screen) to an ISO 3166-1 alpha-2 code. Returns ''
  /// when unknown.
  static String _countryCodeFromName(String name) {
    if (name.isEmpty) return '';
    final n = name.trim().toLowerCase();
    for (final entry in _countryAr.entries) {
      if (entry.value.toLowerCase() == n) return entry.key;
    }
    if (n.contains('العراق') || n.contains('iraq')) return 'IQ';
    if (n.contains('مصر') || n == 'egypt') return 'EG';
    if (n.contains('السعودية') || n.contains('saudi')) return 'SA';
    if (n.contains('الإمارات') || n.contains('إمارات') || n.contains('uae') || n.contains('emirates') || n.contains('dubai')) return 'AE';
    if (n.contains('الكويت') || n.contains('kuwait')) return 'KW';
    if (n.contains('البحرين') || n.contains('bahrain')) return 'BH';
    if (n.contains('قطر') || n == 'qatar') return 'QA';
    if (n.contains('عُمان') || n.contains('عمان') || n.contains('oman')) return 'OM';
    if (n.contains('الأردن') || n.contains('الاردن') || n.contains('jordan')) return 'JO';
    if (n.contains('سوريا') || n.contains('سورية') || n.contains('syria')) return 'SY';
    if (n.contains('لبنان') || n.contains('lebanon')) return 'LB';
    if (n.contains('ليبيا') || n.contains('libya')) return 'LY';
    if (n.contains('تونس') || n.contains('tunisia')) return 'TN';
    if (n.contains('الجزائر') || n.contains('algeria')) return 'DZ';
    if (n.contains('المغرب') || n.contains('morocco')) return 'MA';
    if (n.contains('السودان') || n.contains('sudan')) return 'SD';
    if (n.contains('اليمن') || n.contains('yemen')) return 'YE';
    if (n.contains('موريتانيا') || n.contains('mauritania')) return 'MR';
    if (n.contains('الصومال') || n.contains('somalia')) return 'SO';
    if (n.contains('جيبوتي') || n.contains('djibouti')) return 'DJ';
    if (n.contains('القمر') || n.contains('comoros')) return 'KM';
    if (n.contains('تركيا') || n.contains('turkey')) return 'TR';
    if (n.contains('أفغانستان') || n.contains('افغانستان') || n.contains('afghan')) return 'AF';
    if (n.contains('باكستان') || n.contains('pakistan')) return 'PK';
    if (n.contains('إيران') || n.contains('ايران') || n.contains('iran')) return 'IR';
    if (n.contains('إندونيسيا') || n.contains('اندونيسيا') || n.contains('indonesia')) return 'ID';
    if (n.contains('ماليزيا') || n.contains('malaysia')) return 'MY';
    if (n.contains('بنغلاديش') || n.contains('bangladesh')) return 'BD';
    if (n.contains('نيجيريا') || n.contains('nigeria')) return 'NG';
    if (n.contains('الهند') || n == 'india') return 'IN';
    if (n.contains('الصين') || n == 'china') return 'CN';
    if (n.contains('اليابان') || n == 'japan') return 'JP';
    if (n.contains('أمريكا') || n.contains('امريكا') || n.contains('america') || n.contains('united states') || n == 'usa' || n == 'us') return 'US';
    if (n.contains('كندا') || n.contains('canada')) return 'CA';
    if (n.contains('المملكة المتحدة') || n.contains('بريطانيا') || n.contains('united kingdom') || n.contains('britain') || n == 'uk') return 'GB';
    if (n.contains('فرنسا') || n.contains('france')) return 'FR';
    if (n.contains('ألمانيا') || n.contains('المانيا') || n.contains('germany')) return 'DE';
    if (n.contains('إيطاليا') || n.contains('ايطاليا') || n.contains('italy')) return 'IT';
    if (n.contains('إسبانيا') || n.contains('اسبانيا') || n.contains('spain')) return 'ES';
    if (n.contains('هولندا') || n.contains('netherlands')) return 'NL';
    if (n.contains('بلجيكا') || n.contains('belgium')) return 'BE';
    if (n.contains('البرتغال') || n.contains('portugal')) return 'PT';
    if (n.contains('اليونان') || n.contains('greece')) return 'GR';
    if (n.contains('النمسا') || n.contains('austria')) return 'AT';
    if (n.contains('السويد') || n.contains('sweden')) return 'SE';
    if (n.contains('سويسرا') || n.contains('switzerland')) return 'CH';
    if (n.contains('أستراليا') || n.contains('استراليا') || n.contains('australia')) return 'AU';
    if (n.contains('روسيا') || n.contains('russia')) return 'RU';
    return '';
  }

  /// Reads the location the user actually chose/saved in the app (the same
  /// one shown on the home screen) and maps it to a currency. Returns null
  /// if no matching country is stored.
  ///
  /// The location is read straight from SharedPreferences (key
  /// `adhkar.location`) because a freshly-created [DhikrStorage] is not
  /// initialized with prefs by a service layer.
  Future<DetectedCurrency?> _fromSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('adhkar.location');
      if (stored == null || stored.isEmpty) return null;
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic>) return null;
      final countryAr = (decoded['countryAr'] as String?) ?? '';
      final countryEn = (decoded['countryEn'] as String?) ?? '';
      // Prefer the explicit ISO code saved with the GPS-based location (the
      // most reliable source — set from GPS reverse-geocoding).
      final savedCc = ((decoded['countryCode'] as String?) ?? '').trim().toUpperCase();
      var cc = savedCc.isNotEmpty ? savedCc : '';
      if (cc.isEmpty || _countryCurrency[cc] == null) {
        cc = _countryCodeFromName(countryAr.isNotEmpty ? countryAr : countryEn);
      }
      if (cc.isEmpty || _countryCurrency[cc] == null) return null;
      final code = _countryCurrency[cc]!;
      final info = _catalogFor(code);
      await _saveCurrency(info);
      return DetectedCurrency(
        currency: info,
        countryCode: cc,
        countryAr: countryAr.isNotEmpty ? countryAr : _countryLabel(cc),
        countryEn: countryEn,
      );
    } catch (_) {
      return null;
    }
  }

  /// Detects the user's currency. Priority:
  /// 1) The country saved in the app (what the user sees on home).
  /// 2) IP geolocation of the connection.
  /// 3) Device locale country code.
  /// 4) Cached value.
  /// 5) EGP fallback.
  Future<DetectedCurrency> detectCurrency() async {
    // 1) Saved app location (authoritative — matches the home screen).
    final saved = await _fromSavedLocation();
    if (saved != null) return saved;

    // 2) IP geolocation (ipwho.is returns the country code + currency code).
    try {
      final res = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final cc = ((data['country_code'] as String?) ?? '').toUpperCase();
          final currencyObj = data['currency'] as Map? ?? {};
          var curCode = (currencyObj['code'] as String?) ?? '';
          if (curCode.isEmpty || curCode.length != 3) {
            curCode = cc.isNotEmpty ? (_countryCurrency[cc] ?? '') : '';
          }
          if (curCode.isNotEmpty && curCode.length == 3) {
            final info = _catalogFor(curCode);
            await _saveCurrency(info);
            return DetectedCurrency(
              currency: info,
              countryCode: cc,
              countryAr: _countryLabel(cc),
              countryEn: (data['country'] as String?) ?? '',
            );
          }
        }
      }
    } catch (_) {}

    // 3) Device locale (fast, no network, respects the phone region).
    final localeCountry = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (localeCountry != null && localeCountry.length == 2) {
      final code = _countryCurrency[localeCountry.toUpperCase()];
      if (code != null) {
        final info = _catalogFor(code);
        await _saveCurrency(info);
        return DetectedCurrency(
          currency: info,
          countryCode: localeCountry.toUpperCase(),
          countryAr: _countryLabel(localeCountry.toUpperCase()),
          countryEn: '',
        );
      }
    }

    // 4) Cached value.
    final cached = await loadCachedCurrency();
    if (cached != null) {
      return DetectedCurrency(
        currency: cached,
        countryCode: '',
        countryAr: '',
        countryEn: '',
      );
    }

    // 5) Fallback.
    return const DetectedCurrency(
      currency: _defaultCurrency,
      countryCode: 'EG',
      countryAr: 'مصر',
      countryEn: 'Egypt',
    );
  }

  /// Local-currency units per 1 USD, from the free FX sources. Returns > 0
  /// on success (e.g. EGP rate ~48 for Egypt).
  Future<double> _localPerUsd(String code) async {
    final errors = <String>[];

    // Source 1: open.er-api.com (rates are units of local currency per USD).
    try {
      final res = await _get('https://open.er-api.com/v6/latest/USD');
      if (res.statusCode == 200) {
        final rate = ((jsonDecode(res.body) as Map)['rates'] as Map?)?[code] as num?;
        if (rate != null && rate > 0) return rate.toDouble();
      }
      errors.add('er-api:${res.statusCode}');
    } catch (e) {
      errors.add('er-api:$e');
    }

    // Source 2: exchangerate-api.com
    try {
      final res = await _get('https://api.exchangerate-api.com/v4/latest/USD');
      if (res.statusCode == 200) {
        final rate = ((jsonDecode(res.body) as Map)['rates'] as Map?)?[code] as num?;
        if (rate != null && rate > 0) return rate.toDouble();
      }
      errors.add('exchangerate-api:${res.statusCode}');
    } catch (e) {
      errors.add('exchangerate-api:$e');
    }

    // Source 3: currency-api CDN (lowercase keys).
    try {
      final res = await _get(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json',
      );
      if (res.statusCode == 200) {
        final rate = ((jsonDecode(res.body) as Map)['usd'] as Map?)?[code.toLowerCase()] as num?;
        if (rate != null && rate > 0) return rate.toDouble();
      }
      errors.add('currency-api:${res.statusCode}');
    } catch (e) {
      errors.add('currency-api:$e');
    }

    throw Exception('fx failed for $code: ${errors.join(' | ')}');
  }

  /// USD per troy ounce for [symbol] ('XAU' or 'XAG'), first working source.
  Future<double> _metalUsdPerOz(String symbol) async {
    final errors = <String>[];

    // 1) gold-api.com
    try {
      final res = await _get('https://api.gold-api.com/price/$symbol');
      if (res.statusCode == 200) {
        final price = (jsonDecode(res.body) as Map)['price'] as num?;
        if (price != null && price > 0) return price.toDouble();
      }
      errors.add('gold-api:${res.statusCode}');
    } catch (e) {
      errors.add('gold-api:$e');
    }

    // 2) Swissquote public feed (ask price, USD/oz)
    try {
      final res = await _get(
        'https://forex-data-feed.swissquote.com/public-quotes/bboquotes/instrument/$symbol/USD',
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) {
          final ask = ((list[0] as Map)['ask'] as num?);
          if (ask != null && ask > 0) return ask.toDouble();
        }
      }
      errors.add('swissquote:${res.statusCode}');
    } catch (e) {
      errors.add('swissquote:$e');
    }

    // 3) goldprice.org free rates feed
    try {
      final res = await _get('https://data-asg.goldprice.org/dbXRates/USD');
      if (res.statusCode == 200) {
        final items = ((jsonDecode(res.body) as Map)['items'] as List?) ?? [];
        if (items.isNotEmpty) {
          final first = items[0] as Map;
          final key = symbol == 'XAU' ? 'xauPrice' : 'xagPrice';
          final price = (first[key] as num?);
          if (price != null && price > 0) return price.toDouble();
        }
      }
      errors.add('goldprice:${res.statusCode}');
    } catch (e) {
      errors.add('goldprice:$e');
    }

    throw Exception('metal $symbol failed: ${errors.join(' | ')}');
  }

  /// Fetches live prices converted to the detected local currency. Throws with
  /// details on failure so the UI can show a friendly message and keep the
  /// manual values.
  Future<LiveGoldPrices> fetchLive() async {
    try {
      final detected = await detectCurrency();
      final code = detected.currency.code;
      final xau = await _metalUsdPerOz('XAU');
      final xag = await _metalUsdPerOz('XAG');

      // EGP/USD etc. Special-case USD to avoid a redundant FX look-up.
      double localPerUsd;
      if (code == 'USD') {
        localPerUsd = 1.0;
      } else {
        localPerUsd = await _localPerUsd(code);
      }

      final prices = LiveGoldPrices(
        gold24kPerGramLocal: xau / _troyOunceGrams * localPerUsd,
        silverPerGramLocal: xag / _troyOunceGrams * localPerUsd,
        updatedAt: DateTime.now(),
        currency: detected.currency,
      );
      await _saveCache(prices);
      return prices;
    } catch (e) {
      debugPrint('GoldPriceService.fetchLive failed: $e');
      rethrow;
    }
  }

  Future<LiveGoldPrices?> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return LiveGoldPrices.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Gold cache load failed: $e');
      return null;
    }
  }

  Future<void> _saveCache(LiveGoldPrices prices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(prices.toMap()));
    } catch (e) {
      debugPrint('Gold cache save failed: $e');
    }
  }
}