import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loved_one.dart';

class LovedOnesService {
  LovedOnesService._();
  static final LovedOnesService instance = LovedOnesService._();

  static const _storageKey = 'adhkar.loved_ones_v1';
  static const _userActivityKey = 'adhkar.loved_ones_user_activity';
  static const _myCreatedIdsKey = 'adhkar.loved_ones_my_created_ids';
  static const _hiddenOrReportedIdsKey = 'adhkar.loved_ones_hidden_reported_ids';

  final List<LovedOneItem> _items = [];
  bool _loaded = false;
  DateTime? _lastCommentTime;

  List<LovedOneItem> get items => List.unmodifiable(_items);

  Future<List<LovedOneItem>> loadLovedOnes() async {
    if (_loaded) return items;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _items.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _items.add(LovedOneItem.fromMap(item));
          } else if (item is Map) {
            _items.add(LovedOneItem.fromMap(Map<String, dynamic>.from(item)));
          }
        }
        final myIds = prefs.getStringList(_myCreatedIdsKey) ?? [];
        final reported = prefs.getStringList(_hiddenOrReportedIdsKey) ?? [];
        // Auto-cleanup expired community items (>30 days) and hidden/reported items
        _items.removeWhere((e) => (e.isExpired && !myIds.contains(e.id)) || reported.contains(e.id));
      }

      // Seed inspiring community prayer requests if list is empty
      if (_items.isEmpty) {
        _items.addAll([
          LovedOneItem(
            id: 'community_1',
            name: 'والدتي الغالية (طلب شفاء وعافية)',
            relation: 'أم لأحد المصلين',
            category: LovedOneCategory.sick,
            customDua: 'اللهم يا شافي يا معافي اشفِ أمي شفاءً لا يغادر سقماً، وارفع عنها الألم، واجعل ما أصابها طهوراً ورفعة لدرجاتها يا رحمن يا رحيم.',
            fatihaCount: 142,
            loveCount: 389,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          LovedOneItem(
            id: 'community_2',
            name: 'والدي الحبيب (رحمة ومغفرة)',
            relation: 'أب متوفى',
            category: LovedOneCategory.deceased,
            customDua: 'اللهم أنزل على قبر أبي الضياء والنور والفسحة والسرور، وافسح له في قبره مد بصره، واجمعه مع النبيين والصديقين والشهداء في الفردوس الأعلى.',
            fatihaCount: 265,
            loveCount: 512,
            createdAt: DateTime.now().subtract(const Duration(hours: 7)),
          ),
          LovedOneItem(
            id: 'community_3',
            name: 'أهلنا والمستضعفون في فلسطين والسودان',
            relation: 'إخواننا في العقيدة',
            category: LovedOneCategory.need,
            customDua: 'اللهم كن لأهلنا المستضعفين عوناً ونصيراً، وفرج كربهم، واجبر كسرهم، واطعم جائعهم، واشف جريحهم، وارحم شهداءهم، واكتب لهم النصر والتمكين.',
            fatihaCount: 538,
            loveCount: 1204,
            createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          ),
          LovedOneItem(
            id: 'community_4',
            name: 'طالب علم يرجو التوفيق في الامتحانات',
            relation: 'أخ في الله',
            category: LovedOneCategory.need,
            customDua: 'اللهم لا سهل إلا ما جعلته سهلاً، وأنت تجعل الحزن إذا شئت سهلاً، اللهم يسّر له امتحاناته وسدد خطاه وافتح عليه فتوح العارفين.',
            fatihaCount: 88,
            loveCount: 245,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);
        await _persist();
      }
    } catch (e) {
      debugPrint('Error loading loved ones: $e');
    }
    _loaded = true;
    return items;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_items.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error persisting loved ones: $e');
    }
  }

  Future<void> addLovedOne(LovedOneItem item) async {
    await loadLovedOnes();
    _items.insert(0, item);
    await _persist();
    try {
      final prefs = await SharedPreferences.getInstance();
      final myIds = prefs.getStringList(_myCreatedIdsKey) ?? [];
      if (!myIds.contains(item.id)) {
        myIds.add(item.id);
        await prefs.setStringList(_myCreatedIdsKey, myIds);
      }
    } catch (_) {}
  }

  Future<List<String>> getMyCreatedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_myCreatedIdsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>> getUserSpiritualStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ameen = prefs.getInt('${_userActivityKey}_ameen') ?? 0;
      final fatiha = prefs.getInt('${_userActivityKey}_fatiha') ?? 0;
      final myIds = prefs.getStringList(_myCreatedIdsKey) ?? [];
      return {
        'ameen': ameen,
        'fatiha': fatiha,
        'myPosts': myIds.length,
      };
    } catch (_) {
      return {'ameen': 0, 'fatiha': 0, 'myPosts': 0};
    }
  }

  Future<void> recordUserAmeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getInt('${_userActivityKey}_ameen') ?? 0;
      await prefs.setInt('${_userActivityKey}_ameen', cur + 1);
    } catch (_) {}
  }

  Future<void> recordUserFatiha() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getInt('${_userActivityKey}_fatiha') ?? 0;
      await prefs.setInt('${_userActivityKey}_fatiha', cur + 1);
    } catch (_) {}
  }

  Future<void> updateLovedOne(LovedOneItem item) async {
    await loadLovedOnes();
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
      await _persist();
    }
  }

  Future<void> deleteLovedOne(String id) async {
    await loadLovedOnes();
    _items.removeWhere((e) => e.id == id);
    await _persist();
    try {
      final prefs = await SharedPreferences.getInstance();
      final myIds = prefs.getStringList(_myCreatedIdsKey) ?? [];
      myIds.remove(id);
      await prefs.setStringList(_myCreatedIdsKey, myIds);
    } catch (_) {}
  }

  Future<int> incrementFatiha(String id) async {
    await loadLovedOnes();
    await recordUserFatiha();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].fatihaCount++;
      await _persist();
      return _items[idx].fatihaCount;
    }
    return 0;
  }

  Future<int> toggleHeart(String id) async {
    await loadLovedOnes();
    await recordUserAmeen();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].loveCount++;
      await _persist();
      return _items[idx].loveCount;
    }
    return 0;
  }

  /// Alias for [toggleHeart] — increments the love/heart count
  Future<int> incrementLove(String id) => toggleHeart(id);

  Future<void> addComment(String id, String comment) async {
    if (comment.trim().isEmpty) return;
    await loadLovedOnes();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].comments.insert(0, comment.trim());
      _lastCommentTime = DateTime.now();
      await _persist();
    }
  }

  /// Comment cooldown (15s between comments)
  bool get isCommentInCooldown {
    if (_lastCommentTime == null) return false;
    return DateTime.now().difference(_lastCommentTime!).inSeconds < 15;
  }

  /// Daily prayer creation rate limit (max 2 per day)
  Future<bool> canAddPrayerToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final count = prefs.getInt('adhkar.loved_ones_daily_count_$today') ?? 0;
      return count < 2;
    } catch (_) {
      return true;
    }
  }

  Future<void> recordPrayerAddedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final count = prefs.getInt('adhkar.loved_ones_daily_count_$today') ?? 0;
      await prefs.setInt('adhkar.loved_ones_daily_count_$today', count + 1);
    } catch (_) {}
  }

  /// Report/flag inappropriate prayer request (Google Play UGC compliance)
  Future<void> reportLovedOne({
    required String id,
    required String reason,
    String? details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_hiddenOrReportedIdsKey) ?? [];
      if (!list.contains(id)) {
        list.add(id);
        await prefs.setStringList(_hiddenOrReportedIdsKey, list);
      }
      _items.removeWhere((e) => e.id == id);
      await _persist();
    } catch (e) {
      debugPrint('Error reporting prayer request: $e');
    }
  }

  /// Renew prayer request for another 30 days
  Future<void> renewLovedOne(String id) async {
    await loadLovedOnes();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final old = _items[idx];
      _items[idx] = LovedOneItem(
        id: old.id,
        name: old.name,
        relation: old.relation,
        category: old.category,
        imagePath: old.imagePath,
        customDua: old.customDua,
        fatihaCount: old.fatihaCount,
        loveCount: old.loveCount,
        comments: old.comments,
        createdAt: DateTime.now(),
      );
      await _persist();
    }
  }
}
