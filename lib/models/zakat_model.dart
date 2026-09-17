import 'dart:convert';
import 'package:flutter/material.dart';

enum BeneficiaryType {
  zakat,   // زكاة مال
  sadaqah, // صدقة جارية / مساعدة
  udhiyah; // أضحية العيد (خروف / سهم عجل / كرتونة)

  String get labelAr => switch (this) {
    BeneficiaryType.zakat => 'زكاة مال واجبة',
    BeneficiaryType.sadaqah => 'صدقة وتبرع',
    BeneficiaryType.udhiyah => 'أضحية عيد الأضحى',
  };

  String get badgeAr => switch (this) {
    BeneficiaryType.zakat => 'زكاة 🪙',
    BeneficiaryType.sadaqah => 'صدقة 🌿',
    BeneficiaryType.udhiyah => 'أضحية 🐑',
  };

  IconData get icon => switch (this) {
    BeneficiaryType.zakat => Icons.account_balance_wallet_rounded,
    BeneficiaryType.sadaqah => Icons.volunteer_activism_rounded,
    BeneficiaryType.udhiyah => Icons.pets_rounded,
  };

  Color get color => switch (this) {
    BeneficiaryType.zakat => const Color(0xFFD97706),
    BeneficiaryType.sadaqah => const Color(0xFF10B981),
    BeneficiaryType.udhiyah => const Color(0xFF8B5CF6),
  };
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
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final BeneficiaryType type;
  final String amountOrShare;
  final String? phone;
  final String? notes;
  bool isDelivered;
  DateTime? dueDate;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'amountOrShare': amountOrShare,
      'phone': phone,
      'notes': notes,
      'isDelivered': isDelivered,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ZakatBeneficiary.fromMap(Map<String, dynamic> map) {
    BeneficiaryType t;
    try {
      t = BeneficiaryType.values.byName(map['type'] as String? ?? 'zakat');
    } catch (_) {
      t = BeneficiaryType.zakat;
    }

    return ZakatBeneficiary(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: t,
      amountOrShare: map['amountOrShare'] as String? ?? '',
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      isDelivered: map['isDelivered'] as bool? ?? false,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
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

  /// نصاب الذهب الشرعي = 85 جرام عيار 24
  double get goldNisabThreshold => 85.0 * goldPricePerGram;

  /// نصاب الفضة الشرعي = 595 جرام فضة
  double get silverNisabThreshold => 595.0 * silverPricePerGram;

  /// إجمالي الأموال الزكوية الصافية
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

  /// هل بلغ المال النصاب الشرعي؟
  bool get reachesNisab => totalZakatableWealth >= goldNisabThreshold && goldNisabThreshold > 0;

  /// مقدار الزكاة الواجبة شرعاً (ربع العشر 2.5%)
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
