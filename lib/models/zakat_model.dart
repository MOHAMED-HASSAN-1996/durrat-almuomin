import 'dart:convert';
import 'package:flutter/material.dart';

/// فئات مستحقي الزكاة (الثمانية المبينة)
enum ZakatCategory {
  fuqara,      // الفقراء
  masakin,     // المساكين
  amilin,      // العاملون عليها
  muallafah,   // المؤلفة قلوبهم
  fiRiqab,     // في الرقاب
  gharimin,    // الغارمون
  fiSabilillah,// في سبيل الله
  ibnSabil,    // ابن السبيل
  sadaqah;     // صدقة تطوعية

  String get labelAr => switch (this) {
    ZakatCategory.fuqara       => 'الفقراء',
    ZakatCategory.masakin      => 'المساكين',
    ZakatCategory.amilin       => 'العاملون عليها',
    ZakatCategory.muallafah    => 'المؤلفة قلوبهم',
    ZakatCategory.fiRiqab      => 'في الرقاب',
    ZakatCategory.gharimin     => 'الغارمون',
    ZakatCategory.fiSabilillah => 'في سبيل الله',
    ZakatCategory.ibnSabil     => 'ابن السبيل',
    ZakatCategory.sadaqah      => 'صدقة تطوعية',
  };

  String get badgeAr => switch (this) {
    ZakatCategory.fuqara       => 'فقيرة',
    ZakatCategory.masakin      => 'مسكينة',
    ZakatCategory.amilin       => 'عاملة',
    ZakatCategory.muallafah    => 'مؤلفة',
    ZakatCategory.fiRiqab      => 'رقاب',
    ZakatCategory.gharimin     => 'غارمون',
    ZakatCategory.fiSabilillah => 'سبيل الله',
    ZakatCategory.ibnSabil     => 'ابن سبيل',
    ZakatCategory.sadaqah      => 'صدقة',
  };

  IconData get icon => switch (this) {
    ZakatCategory.fuqara       => Icons.handshake_rounded,
    ZakatCategory.masakin      => Icons.volunteer_activism_rounded,
    ZakatCategory.amilin       => Icons.admin_panel_settings_rounded,
    ZakatCategory.muallafah    => Icons.favorite_rounded,
    ZakatCategory.fiRiqab      => Icons.lock_open_rounded,
    ZakatCategory.gharimin     => Icons.receipt_long_rounded,
    ZakatCategory.fiSabilillah => Icons.mosque_rounded,
    ZakatCategory.ibnSabil     => Icons.flight_takeoff_rounded,
    ZakatCategory.sadaqah      => Icons.card_giftcard_rounded,
  };

  Color get color => switch (this) {
    ZakatCategory.fuqara       => const Color(0xFFD97706),
    ZakatCategory.masakin      => const Color(0xFF10B981),
    ZakatCategory.amilin       => const Color(0xFF3B82F6),
    ZakatCategory.muallafah    => const Color(0xFFF59E0B),
    ZakatCategory.fiRiqab      => const Color(0xFF8B5CF6),
    ZakatCategory.gharimin     => const Color(0xFFEF4444),
    ZakatCategory.fiSabilillah => const Color(0xFF06B6D4),
    ZakatCategory.ibnSabil     => const Color(0xFFEC4899),
    ZakatCategory.sadaqah      => const Color(0xFF6B7280),
  };
}

/// فئات مستحقي الأضحية
enum UdhiyahCategory {
  relatives,   // أقارب
  neighbors,   // جيران
  poor,        // فقراء
  orphans,     // أيتام
  friends,     // أصدقاء
  travelers,   // مسافرون
  needy;       // محتاجون

  String get labelAr => switch (this) {
    UdhiyahCategory.relatives  => 'الأقارب',
    UdhiyahCategory.neighbors  => 'الجيران',
    UdhiyahCategory.poor       => 'الفقراء',
    UdhiyahCategory.orphans    => 'الأيتام',
    UdhiyahCategory.friends    => 'الأصدقاء',
    UdhiyahCategory.travelers  => 'المسافرون',
    UdhiyahCategory.needy      => 'المحتاجون',
  };

  String get badgeAr => switch (this) {
    UdhiyahCategory.relatives  => 'أقارب',
    UdhiyahCategory.neighbors  => 'جيران',
    UdhiyahCategory.poor       => 'فقراء',
    UdhiyahCategory.orphans    => 'أيتام',
    UdhiyahCategory.friends    => 'أصدقاء',
    UdhiyahCategory.travelers  => 'مسافرون',
    UdhiyahCategory.needy      => 'محتاجون',
  };

  IconData get icon => switch (this) {
    UdhiyahCategory.relatives  => Icons.family_restroom_rounded,
    UdhiyahCategory.neighbors  => Icons.home_rounded,
    UdhiyahCategory.poor       => Icons.handshake_rounded,
    UdhiyahCategory.orphans    => Icons.child_care_rounded,
    UdhiyahCategory.friends    => Icons.groups_rounded,
    UdhiyahCategory.travelers  => Icons.flight_rounded,
    UdhiyahCategory.needy      => Icons.volunteer_activism_rounded,
  };

  Color get color => switch (this) {
    UdhiyahCategory.relatives  => const Color(0xFF8B5CF6),
    UdhiyahCategory.neighbors  => const Color(0xFF06B6D4),
    UdhiyahCategory.poor       => const Color(0xFFD97706),
    UdhiyahCategory.orphans    => const Color(0xFFEC4899),
    UdhiyahCategory.friends    => const Color(0xFF10B981),
    UdhiyahCategory.travelers  => const Color(0xFF3B82F6),
    UdhiyahCategory.needy      => const Color(0xFFEF4444),
  };
}

/// Legacy enum kept for backward compatibility with old saved data.
enum BeneficiaryType {
  zakat,
  sadaqah,
  udhiyah;

  String get labelAr => switch (this) {
    BeneficiaryType.zakat   => 'زكاة مال واجبة',
    BeneficiaryType.sadaqah => 'صدقة وتبرع',
    BeneficiaryType.udhiyah => 'أضحية عيد الأضحى',
  };

  String get badgeAr => switch (this) {
    BeneficiaryType.zakat   => 'زكاة',
    BeneficiaryType.sadaqah => 'صدقة',
    BeneficiaryType.udhiyah => 'أضحية',
  };

  IconData get icon => switch (this) {
    BeneficiaryType.zakat   => Icons.account_balance_wallet_rounded,
    BeneficiaryType.sadaqah => Icons.volunteer_activism_rounded,
    BeneficiaryType.udhiyah => Icons.pets_rounded,
  };

  Color get color => switch (this) {
    BeneficiaryType.zakat   => const Color(0xFFD97706),
    BeneficiaryType.sadaqah => const Color(0xFF10B981),
    BeneficiaryType.udhiyah => const Color(0xFF8B5CF6),
  };
}

/// Helper to get display info from a stored type string (works for both old and new data).
class BeneficiaryTypeHelper {
  static String badgeAr(String type) {
    if (ZakatCategory.values.any((e) => e.name == type)) {
      return ZakatCategory.values.byName(type).badgeAr;
    }
    if (UdhiyahCategory.values.any((e) => e.name == type)) {
      return UdhiyahCategory.values.byName(type).badgeAr;
    }
    if (BeneficiaryType.values.any((e) => e.name == type)) {
      return BeneficiaryType.values.byName(type).badgeAr;
    }
    return type;
  }

  static IconData icon(String type) {
    if (ZakatCategory.values.any((e) => e.name == type)) {
      return ZakatCategory.values.byName(type).icon;
    }
    if (UdhiyahCategory.values.any((e) => e.name == type)) {
      return UdhiyahCategory.values.byName(type).icon;
    }
    if (BeneficiaryType.values.any((e) => e.name == type)) {
      return BeneficiaryType.values.byName(type).icon;
    }
    return Icons.help_outline_rounded;
  }

  static Color color(String type) {
    if (ZakatCategory.values.any((e) => e.name == type)) {
      return ZakatCategory.values.byName(type).color;
    }
    if (UdhiyahCategory.values.any((e) => e.name == type)) {
      return UdhiyahCategory.values.byName(type).color;
    }
    if (BeneficiaryType.values.any((e) => e.name == type)) {
      return BeneficiaryType.values.byName(type).color;
    }
    return Colors.grey;
  }

  static String labelAr(String type) {
    if (ZakatCategory.values.any((e) => e.name == type)) {
      return ZakatCategory.values.byName(type).labelAr;
    }
    if (UdhiyahCategory.values.any((e) => e.name == type)) {
      return UdhiyahCategory.values.byName(type).labelAr;
    }
    if (BeneficiaryType.values.any((e) => e.name == type)) {
      return BeneficiaryType.values.byName(type).labelAr;
    }
    return type;
  }
}

class ZakatBeneficiary {
  ZakatBeneficiary({
    required this.id,
    required this.name,
    required this.type,
    required this.amountOrShare,
    this.phone,
    this.notes,
    this.isDelivered = false,
    this.dueDate,
    DateTime? createdAt,
    String? group,
  })  : createdAt = createdAt ?? DateTime.now(),
        group = (group == null || group.trim().isEmpty) ? 'عام' : group.trim();

  final String id;
  final String name;
  final String type; // stored as enum .name string (e.g. 'fuqara', 'relatives', or legacy 'zakat')
  final String amountOrShare;
  final String? phone;
  final String? notes;
  bool isDelivered;
  DateTime? dueDate;
  final DateTime createdAt;
  String group;

  /// Convenience: is this beneficiary in the zakat categories?
  bool get isZakatType => ZakatCategory.values.any((e) => e.name == type);

  /// Convenience: is this beneficiary in the udhiyah categories?
  bool get isUdhiyahType => UdhiyahCategory.values.any((e) => e.name == type);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amountOrShare': amountOrShare,
      'phone': phone,
      'notes': notes,
      'isDelivered': isDelivered,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'group': group,
    };
  }

  factory ZakatBeneficiary.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] as String? ?? 'fuqara';

    // Normalize legacy types to new categories
    String normalizedType = rawType;
    if (rawType == 'zakat') normalizedType = 'fuqara';
    if (rawType == 'sadaqah') normalizedType = 'sadaqah';
    if (rawType == 'udhiyah') normalizedType = 'relatives';

    return ZakatBeneficiary(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: normalizedType,
      amountOrShare: map['amountOrShare'] as String? ?? '',
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      isDelivered: map['isDelivered'] as bool? ?? false,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      group: (map['group'] as String?)?.trim().isEmpty ?? true
          ? 'عام'
          : (map['group'] as String).trim(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ZakatBeneficiary.fromJson(String source) =>
      ZakatBeneficiary.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class ZakatCalculationState {
  ZakatCalculationState({
    this.goldPricePerGram = 3500.0,
    this.silverPricePerGram = 45.0,
    this.cashAmount = 0.0,
    this.goldWeightGrams24k = 0.0,
    this.goldWeightGrams21k = 0.0,
    this.silverWeightGrams = 0.0,
    this.tradeInventoryValue = 0.0,
    this.stocksAndInvestments = 0.0,
    this.debtsOwedToYou = 0.0,
    this.debtsYouOwe = 0.0,
  });

  double goldPricePerGram;
  double silverPricePerGram;
  double cashAmount;
  double goldWeightGrams24k;
  double goldWeightGrams21k;
  double silverWeightGrams;
  double tradeInventoryValue;
  double stocksAndInvestments;
  double debtsOwedToYou;
  double debtsYouOwe;

  double get goldNisabThreshold => 85.0 * goldPricePerGram;
  double get silverNisabThreshold => 595.0 * silverPricePerGram;

  double get totalZakatableWealth {
    final goldValue = (goldWeightGrams24k * goldPricePerGram) +
        (goldWeightGrams21k * goldPricePerGram * (21.0 / 24.0));
    final silverValue = silverWeightGrams * silverPricePerGram;

    final assets = cashAmount +
        goldValue +
        silverValue +
        tradeInventoryValue +
        stocksAndInvestments +
        debtsOwedToYou;

    final net = assets - debtsYouOwe;
    return net > 0 ? net : 0.0;
  }

  bool get reachesNisab => totalZakatableWealth >= goldNisabThreshold && goldNisabThreshold > 0;

  double get zakatDue => reachesNisab ? (totalZakatableWealth * 0.025) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'goldPricePerGram': goldPricePerGram,
      'silverPricePerGram': silverPricePerGram,
      'cashAmount': cashAmount,
      'goldWeightGrams24k': goldWeightGrams24k,
      'goldWeightGrams21k': goldWeightGrams21k,
      'silverWeightGrams': silverWeightGrams,
      'tradeInventoryValue': tradeInventoryValue,
      'stocksAndInvestments': stocksAndInvestments,
      'debtsOwedToYou': debtsOwedToYou,
      'debtsYouOwe': debtsYouOwe,
    };
  }

  factory ZakatCalculationState.fromMap(Map<String, dynamic> map) {
    return ZakatCalculationState(
      goldPricePerGram: (map['goldPricePerGram'] as num?)?.toDouble() ?? 3500.0,
      silverPricePerGram: (map['silverPricePerGram'] as num?)?.toDouble() ?? 45.0,
      cashAmount: (map['cashAmount'] as num?)?.toDouble() ?? 0.0,
      goldWeightGrams24k: (map['goldWeightGrams24k'] as num?)?.toDouble() ?? 0.0,
      goldWeightGrams21k: (map['goldWeightGrams21k'] as num?)?.toDouble() ?? 0.0,
      silverWeightGrams: (map['silverWeightGrams'] as num?)?.toDouble() ?? 0.0,
      tradeInventoryValue: (map['tradeInventoryValue'] as num?)?.toDouble() ?? 0.0,
      stocksAndInvestments: (map['stocksAndInvestments'] as num?)?.toDouble() ?? 0.0,
      debtsOwedToYou: (map['debtsOwedToYou'] as num?)?.toDouble() ?? 0.0,
      debtsYouOwe: (map['debtsYouOwe'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
