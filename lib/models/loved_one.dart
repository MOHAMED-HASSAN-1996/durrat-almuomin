import 'dart:convert';
import 'package:flutter/material.dart';

enum LovedOneCategory {
  deceased, // متوفى (رحمه الله)
  sick,     // مريض (شفاه الله)
  need,     // قضاء حاجة وتفريج كرب
  absent;   // غائب أو مسافر (رده الله سالماً)

  String get labelAr => switch (this) {
    LovedOneCategory.deceased => 'متوفى رحمه الله',
    LovedOneCategory.sick => 'مريض نسأل الله شفاؤه',
    LovedOneCategory.need => 'قضاء حاجة وتيسير أمر',
    LovedOneCategory.absent => 'غائب أو مسافر يحفظه الله',
  };

  String get badgeLabelAr => switch (this) {
    LovedOneCategory.deceased => 'رحمة ومغفرة 🕊️',
    LovedOneCategory.sick => 'شفاء وعافية 🌿',
    LovedOneCategory.need => 'قضاء حاجة 🤲',
    LovedOneCategory.absent => 'حفظ ورجوع 🧭',
  };

  String get labelEn => switch (this) {
    LovedOneCategory.deceased => 'Deceased',
    LovedOneCategory.sick => 'Sick / Seeking Healing',
    LovedOneCategory.need => 'Seeking Relief / Need',
    LovedOneCategory.absent => 'Traveler / Absent',
  };

  IconData get icon => switch (this) {
    LovedOneCategory.deceased => Icons.nightlight_round,
    LovedOneCategory.sick => Icons.healing_rounded,
    LovedOneCategory.need => Icons.volunteer_activism_rounded,
    LovedOneCategory.absent => Icons.flight_takeoff_rounded,
  };

  Color get color => switch (this) {
    LovedOneCategory.deceased => const Color(0xFF23423B), // Forest Deep
    LovedOneCategory.sick => const Color(0xFFC5A059),     // Warm Islamic Gold
    LovedOneCategory.need => const Color(0xFFD97706),     // Amber gold
    LovedOneCategory.absent => const Color(0xFF0284C7),   // Sky blue
  };

  String get defaultDuaAr => switch (this) {
    LovedOneCategory.deceased =>
      'اللهم اغفر له وارحمه، وعافه واعف عنه، وأكرم نزله، ووسع مدخله، واغسله بالماء والثلج والبرد، ونقه من الذنوب والخطايا كما ينقى الثوب الأبيض من الدنس، واجعل قبره روضة من رياض الجنة.',
    LovedOneCategory.sick =>
      'اللهم رب الناس، أذهب الباس، واشفه وأنت الشافي، لا شفاء إلا شفاؤك، شفاءً لا يغادر سقماً، وألبسه ثوب الصحة والعافية عاجلاً غير آجل.',
    LovedOneCategory.need =>
      'اللهم يا فارج الهم وكاشف الغم، مجيب دعوة المضطرين، يسر أمره واقض حاجته وفرج كربه، وافتح له أبواب الخير والتيسير من حيث لا يحتسب.',
    LovedOneCategory.absent =>
      'اللهم احفظه في سفره وغيبته بحفظك التام، واكلأه برعايتك، واصرف عنه كل سوء، ورده إلى أهله وأحبابه سالماً غانماً معافى.',
  };
}

class LovedOneItem {
  LovedOneItem({
    required this.id,
    required this.name,
    required this.relation,
    required this.category,
    this.imagePath,
    this.customDua,
    this.fatihaCount = 0,
    this.loveCount = 0,
    List<String>? comments,
    DateTime? createdAt,
    this.authorName = '',
    this.authorPhoto = '',
  })  : comments = comments ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String relation;
  final LovedOneCategory category;
  final String? imagePath;
  String? customDua;
  int fatihaCount;
  int loveCount;
  final List<String> comments;
  final DateTime createdAt;
  final String authorName;
  final String authorPhoto;

  /// Duration logic (30-day community active window)
  int get daysRemaining {
    final diff = DateTime.now().difference(createdAt).inDays;
    final left = 30 - diff;
    return left > 0 ? left : 0;
  }

  bool get isExpired => DateTime.now().difference(createdAt).inDays >= 30;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'category': category.name,
      'imagePath': imagePath,
      'customDua': customDua,
      'fatihaCount': fatihaCount,
      'loveCount': loveCount,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'authorName': authorName,
      'authorPhoto': authorPhoto,
    };
  }

  factory LovedOneItem.fromMap(Map<String, dynamic> map) {
    LovedOneCategory cat;
    try {
      cat = LovedOneCategory.values.byName(map['category'] as String? ?? 'deceased');
    } catch (_) {
      cat = LovedOneCategory.deceased;
    }

    return LovedOneItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
      category: cat,
      imagePath: (map['imagePath'] as String?) ?? (map['imageUrl'] as String?),
      customDua: map['customDua'] as String?,
      fatihaCount: (map['fatihaCount'] as num?)?.toInt() ?? 0,
      loveCount: (map['loveCount'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorName: map['authorName'] as String? ?? '',
      authorPhoto: map['authorPhoto'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory LovedOneItem.fromJson(String source) =>
      LovedOneItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
