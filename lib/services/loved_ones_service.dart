import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loved_one.dart';
import 'firebase_auth_service.dart';
import 'prayer_alert_service.dart';

/// Shared prayer-request community backed by Firestore.
///
/// Local storage remains only as an offline cache. Counters and interactions
/// are written atomically in Firestore so users cannot overwrite each other.
class LovedOnesService {
  LovedOnesService._();
  static final LovedOnesService instance = LovedOnesService._();

  static const _storageKey = 'adhkar.loved_ones_v2_cache';
  static const _activityKey = 'adhkar.loved_ones_user_activity';
  static const _myCreatedIdsKey = 'adhkar.loved_ones_my_created_ids';
  static const _hiddenIdsKey = 'adhkar.loved_ones_hidden_reported_ids';
  static const _pageSize = 100;

  final List<LovedOneItem> _items = [];
  bool _loaded = false;
  DateTime? _lastCommentTime;
  FirebaseFirestore? _firestore;
  String? _uid;
  Future<bool>? _connectFuture;

  List<LovedOneItem> get items => List.unmodifiable(_items);

  /// مهلة قصيرة للاتصال حتى لا تعلق شاشة الإضافة على الشبكة.
  static const _connectTimeout = Duration(seconds: 10);

  /// مهلة جلب القائمة من السحابة (القراءة فقط، الكتابة لها مهلتها المستقلة).
  static const _readTimeout = Duration(seconds: 15);

  Future<bool> _connect() {
    // عملية اتصال واحدة مشتركة (لا تُكرَّر signInAnonymously عند التداخل).
    if (_firestore != null && _uid != null) return Future.value(true);
    return _connectFuture ??= _doConnect();
  }

  Future<bool> _doConnect() async {
    try {
      await FirebaseAuthService.instance
          .initialize()
          .timeout(_connectTimeout);
      final user = await FirebaseAuthService.instance
          .signInAnonymously()
          .timeout(_connectTimeout);
      _firestore = FirebaseFirestore.instance;
      _uid = user.uid;
      return true;
    } catch (e) {
      debugPrint('Loved ones cloud connection unavailable: $e');
      // نسمح بمحاولة اتصال جديدة في المرة القادمة.
      _connectFuture = null;
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore!.collection('prayer_requests');

  Future<List<LovedOneItem>> loadLovedOnes() async {
    if (_loaded) return items;
    _loaded = true;
    final connected = await _connect();
    if (connected) {
      try {
        final snap = await _requests
            .where('status', isEqualTo: 'active')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: false)
            .orderBy('createdAt', descending: true)
            .limit(_pageSize)
            .get()
            .timeout(_readTimeout);
        _items
          ..clear()
          ..addAll(snap.docs.map(_fromDocument).where((item) => !item.isExpired));
        await _persistLocal();
        await _restoreLocalIds();
        return items;
      } catch (e) {
        debugPrint('Loved ones cloud load failed: $e');
      }
    }
    await _loadLocal();
    return items;
  }

  LovedOneItem _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = doc.id;
    final created = data['createdAt'];
    if (created is Timestamp) {
      data['createdAt'] = created.toDate().toIso8601String();
    }
    data['imagePath'] = data['imagePath'] ?? data['imageUrl'];
    return LovedOneItem.fromMap(data);
  }

  Map<String, dynamic> _toDocument(LovedOneItem item) {
    final now = Timestamp.fromDate(item.createdAt);
    return {
      'ownerId': _uid,
      'name': item.name,
      'relation': item.relation,
      'category': item.category.name,
      'customDua': item.customDua,
      'imageUrl': item.imagePath != null && item.imagePath!.startsWith('http')
          ? item.imagePath
          : null,
      'imagePath': item.imagePath != null && item.imagePath!.startsWith('http')
          ? item.imagePath
          : null,
      'fatihaCount': item.fatihaCount,
      'loveCount': item.loveCount,
      'authorName': item.authorName,
      'authorPhoto': item.authorPhoto,
      'createdAt': now,
      'expiresAt': Timestamp.fromDate(
        item.createdAt.add(const Duration(days: 30)),
      ),
      'status': 'active',
    };
  }

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.whereType<Map>().map(
              (e) => LovedOneItem.fromMap(Map<String, dynamic>.from(e)),
            ));
      await _restoreLocalIds();
      _items.removeWhere((item) => item.isExpired);
    } catch (e) {
      debugPrint('Loved ones local load failed: $e');
    }
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_items.map((item) => item.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Loved ones local cache failed: $e');
    }
  }

  Future<void> _restoreLocalIds() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList(_hiddenIdsKey) ?? [];
    _items.removeWhere((item) => hidden.contains(item.id));
  }

  /// محاولة نشر لم تكتمل بعد (الشبكة بطيئة) — تُعاد بدل إنشاء طلب مكرر.
  Future<DocumentReference<Map<String, dynamic>>>? _pendingCreate;

  LovedOneItem _withId(LovedOneItem item, String id) => LovedOneItem(
        id: id,
        name: item.name,
        relation: item.relation,
        category: item.category,
        imagePath: item.imagePath,
        customDua: item.customDua,
        fatihaCount: item.fatihaCount,
        loveCount: item.loveCount,
        comments: item.comments,
        createdAt: item.createdAt,
        authorName: item.authorName,
        authorPhoto: item.authorPhoto,
      );

  /// حفظ محلي متكرر-آمن: لا يُدخل الطلب مرتين ولا يكرّر معرّفه.
  Future<void> _storeLocal(LovedOneItem item) async {
    if (!_items.any((e) => e.id == item.id)) {
      _items.insert(0, item);
    }
    await _persistLocal();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_myCreatedIdsKey) ?? [];
    if (!ids.contains(item.id)) {
      ids.add(item.id);
      await prefs.setStringList(_myCreatedIdsKey, ids);
    }
  }

  /// يضيف طلباً جديداً للدعاء.
  ///
  /// يُعيد `true` إذا وصل الطلب فعلياً إلى السحابة، و`false` إذا لم يكتمل
  /// النشر بعد (لا اتصال أو رفضت قواعد الأمان أو بطيء الرد).
  Future<bool> addLovedOne(LovedOneItem item) async {
    if (!_loaded) {
      // جلب القائمة أولاً حتى لا يضيع الطلب المضاف عند عودة الجلب من السحابة.
      // (تعمل بمهلة داخلية فلا تعلق شاشة الإضافة.)
      await loadLovedOnes();
    } else if (_firestore == null || _uid == null) {
      await _connect();
    }

    if (_firestore == null || _uid == null) {
      await _storeLocal(item);
      return false;
    }

    Future<DocumentReference<Map<String, dynamic>>>? pending;
    try {
      // إن كانت محاولة سابقة لا تزال في طابور الانتظار نكملها بدل تكرار الطلب.
      pending = _pendingCreate ??= _requests.add(_toDocument(item));

      // عند وصول الكتابة للسحابة لاحقاً نتبنّى معرّفها ونحفظ محلياً.
      pending.then((ref) async {
        if (identical(_pendingCreate, pending)) _pendingCreate = null;
        await _storeLocal(_withId(item, ref.id));
      }).catchError((Object e) {
        debugPrint('Loved ones deferred publish failed: $e');
        if (identical(_pendingCreate, pending)) _pendingCreate = null;
      });

      final ref = await pending.timeout(const Duration(seconds: 20));
      if (identical(_pendingCreate, pending)) _pendingCreate = null;
      await _storeLocal(_withId(item, ref.id));
      return true;
    } on TimeoutException {
      // الكتابة ما زالت معلّقة: ستظهر تلقائياً في القائمة عند اكتمالها.
      debugPrint('Loved ones publish still pending after timeout');
      return false;
    } catch (e) {
      // رفضت قواعد الأمان أو خطأ غير متوقع: نحفظ محلياً ونبلّغ الواجهة.
      debugPrint('Loved ones cloud insert failed: $e');
      if (identical(_pendingCreate, pending)) _pendingCreate = null;
      await _storeLocal(item);
      return false;
    }
  }

  Future<List<String>> getMyCreatedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_myCreatedIdsKey) ?? [];
  }

  Future<Map<String, int>> getUserSpiritualStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ameen': prefs.getInt('${_activityKey}_ameen') ?? 0,
      'fatiha': prefs.getInt('${_activityKey}_fatiha') ?? 0,
      'myPosts': (prefs.getStringList(_myCreatedIdsKey) ?? []).length,
    };
  }

  Future<void> _record(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_activityKey}_$key';
    await prefs.setInt(fullKey, (prefs.getInt(fullKey) ?? 0) + 1);
  }

  Future<void> recordUserAmeen() => _record('ameen');
  Future<void> recordUserFatiha() => _record('fatiha');

  Future<void> _unrecord(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_activityKey}_$key';
    final current = prefs.getInt(fullKey) ?? 0;
    await prefs.setInt(fullKey, current <= 0 ? 0 : current - 1);
  }

  Future<void> unrecordUserAmeen() => _unrecord('ameen');
  Future<void> unrecordUserFatiha() => _unrecord('fatiha');

  /// التراجع عن تفاعل سابق (حذف تفاعل المستخدم وإنقاص العداد).
  Future<int> retractInteraction(String id, String type) async {
    await loadLovedOnes();
    if (_firestore == null || _uid == null) return _localRetract(id, type);
    final interaction = _requests.doc(id).collection('interactions').doc(_uid);
    final request = _requests.doc(id);
    final countField = type == 'fatiha' ? 'fatihaCount' : 'loveCount';
    final result = await FirebaseFirestore.instance.runTransaction((tx) async {
      final interactionSnap = await tx.get(interaction);
      final requestSnap = await tx.get(request);
      if (!requestSnap.exists) return 0;
      final data = requestSnap.data() ?? {};
      final current = (data[countField] as num?)?.toInt() ?? 0;
      if (!interactionSnap.exists) return current;
      tx.delete(interaction);
      tx.update(request, {countField: FieldValue.increment(-1)});
      return current <= 0 ? 0 : current - 1;
    });
    if (type == 'fatiha') {
      await unrecordUserFatiha();
    } else {
      await unrecordUserAmeen();
    }
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      if (type == 'fatiha') {
        _items[index].fatihaCount = result;
      } else {
        _items[index].loveCount = result;
      }
      await _persistLocal();
    }
    return result;
  }

  Future<int> _localRetract(String id, String type) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return 0;
    if (type == 'fatiha') {
      _items[index].fatihaCount =
          _items[index].fatihaCount <= 0 ? 0 : _items[index].fatihaCount - 1;
      await unrecordUserFatiha();
    } else {
      _items[index].loveCount =
          _items[index].loveCount <= 0 ? 0 : _items[index].loveCount - 1;
      await unrecordUserAmeen();
    }
    await _persistLocal();
    return type == 'fatiha' ? _items[index].fatihaCount : _items[index].loveCount;
  }

  Future<int> retractFatiha(String id) => retractInteraction(id, 'fatiha');
  Future<int> retractAmeen(String id) => retractInteraction(id, 'ameen');

  Future<void> updateLovedOne(LovedOneItem item) async {
    await loadLovedOnes();
    if (_firestore != null && _uid != null) {
      final doc = await _requests.doc(item.id).get();
      if (doc.exists && doc.data()?['ownerId'] == _uid) {
        await doc.reference.update(_toDocument(item));
      }
    }
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) _items[index] = item;
    await _persistLocal();
  }

  Future<void> deleteLovedOne(String id) async {
    await loadLovedOnes();
    if (_firestore != null && _uid != null) {
      final doc = _requests.doc(id);
      final snap = await doc.get();
      if (snap.exists && snap.data()?['ownerId'] == _uid) {
        await doc.update({
          'status': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    _items.removeWhere((e) => e.id == id);
    await _persistLocal();
  }

  Future<int> _incrementInteraction(String id, String type) async {
    await loadLovedOnes();
    if (_firestore == null || _uid == null) return _localIncrement(id, type);
    final interaction = _requests.doc(id).collection('interactions').doc(_uid);
    final request = _requests.doc(id);
    final countField = type == 'fatiha' ? 'fatihaCount' : 'loveCount';
    final result = await FirebaseFirestore.instance.runTransaction((tx) async {
      final interactionSnap = await tx.get(interaction);
      final requestSnap = await tx.get(request);
      if (!requestSnap.exists) return 0;
      final data = requestSnap.data() ?? {};
      final current = (data[countField] as num?)?.toInt() ?? 0;
      // كل ضغطة تزيد العدّاد (حتى لو تفاعل المستخدم من قبل).
      if (!interactionSnap.exists) {
        tx.set(interaction, {'type': type, 'createdAt': FieldValue.serverTimestamp()});
      }
      tx.update(request, {countField: FieldValue.increment(1)});
      return current + 1;
    });
    if (type == 'fatiha') {
      await recordUserFatiha();
    } else {
      await recordUserAmeen();
    }
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      if (type == 'fatiha') {
        _items[index].fatihaCount = result;
      } else {
        _items[index].loveCount = result;
      }
      await _persistLocal();
    }
    return result;
  }

  Future<int> _localIncrement(String id, String type) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return 0;
    if (type == 'fatiha') {
      _items[index].fatihaCount++;
      await recordUserFatiha();
    } else {
      _items[index].loveCount++;
      await recordUserAmeen();
    }
    await _persistLocal();
    return type == 'fatiha' ? _items[index].fatihaCount : _items[index].loveCount;
  }

  Future<int> incrementFatiha(String id) => _incrementInteraction(id, 'fatiha');
  Future<int> toggleHeart(String id) => _incrementInteraction(id, 'ameen');
  Future<int> incrementLove(String id) => toggleHeart(id);

  Future<void> addComment(String id, String comment) async {
    final text = comment.trim();
    if (text.isEmpty || isCommentInCooldown) return;
    await loadLovedOnes();
    if (_firestore != null && _uid != null) {
      await _requests.doc(id).collection('comments').add({
        'userId': _uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'visible',
      });

      // إشعار صاحب المنشور: كتابة إشعار في Firestore للمستخدم المستهدف
      try {
        final docSnap = await _requests.doc(id).get();
        if (docSnap.exists) {
          final data = docSnap.data();
          final ownerId = data?['ownerId'] as String?;
          final postName = (data?['name'] as String?) ?? 'منشورك';
          if (ownerId != null && ownerId.isNotEmpty && ownerId != _uid) {
            await _firestore!.collection('notifications').add({
              'targetUserId': ownerId,
              'actorUserId': _uid,
              'requestId': id,
              'type': 'lovedOnesComment',
              'titleAr': 'دعاء جديد على منشورك 🤲',
              'bodyAr': 'قام أحد الإخوة بالدعاء لـ $postName: "$text"',
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            });
          } else if (ownerId == _uid) {
            // صاحب المنشور نفسه علّق على منشوره (أو للاختبار المحلي)
            // نطلق إشعاراً محلياً فورياً عبر نظام التنبيهات
            PrayerAlertService.instance.showLocalNotification(
              id: id.hashCode.abs() % 10000,
              title: 'دعاء جديد على منشورك 🤲',
              body: 'دعاء لـ $postName: "$text"',
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to trigger comment notification: $e');
      }
    }
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index].comments.insert(0, text);
      await _persistLocal();
    }
    _lastCommentTime = DateTime.now();
  }

  Future<void> removeComment(String id, String commentText) async {
    await loadLovedOnes();
    if (_firestore != null) {
      try {
        final snap = await _requests
            .doc(id)
            .collection('comments')
            .where('text', isEqualTo: commentText)
            .limit(1)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete comment from firestore: $e');
      }
    }
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index].comments.remove(commentText);
      await _persistLocal();
    }
  }

  Future<List<String>> loadComments(String id) async {
    if (_firestore == null) await _connect();
    if (_firestore == null) return [];
    try {
      final snap = await _requests
          .doc(id)
          .collection('comments')
          .where('status', isEqualTo: 'visible')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      return snap.docs
          .map((doc) => (doc.data()['text'] as String?)?.trim() ?? '')
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Loved ones comments load failed: $e');
      return [];
    }
  }

  bool get isCommentInCooldown =>
      _lastCommentTime != null &&
      DateTime.now().difference(_lastCommentTime!).inSeconds < 15;

  Future<bool> canAddPrayerToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return (prefs.getInt('adhkar.loved_ones_daily_count_$today') ?? 0) < 2;
  }

  Future<void> recordPrayerAddedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'adhkar.loved_ones_daily_count_$today';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  Future<void> reportLovedOne({
    required String id,
    required String reason,
    String? details,
  }) async {
    await loadLovedOnes();
    if (_firestore != null && _uid != null) {
      await _firestore!.collection('reports').add({
        'requestId': id,
        'reporterId': _uid,
        'reason': reason,
        'details': details ?? '',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_hiddenIdsKey) ?? [];
    if (!ids.contains(id)) ids.add(id);
    await prefs.setStringList(_hiddenIdsKey, ids);
    _items.removeWhere((e) => e.id == id);
    await _persistLocal();
  }

  Future<void> renewLovedOne(String id) async {
    await loadLovedOnes();
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final old = _items[index];
    final renewed = LovedOneItem(
      id: id,
      name: old.name,
      relation: old.relation,
      category: old.category,
      imagePath: old.imagePath,
      customDua: old.customDua,
      fatihaCount: old.fatihaCount,
      loveCount: old.loveCount,
      comments: old.comments,
      createdAt: DateTime.now(),
      authorName: old.authorName,
      authorPhoto: old.authorPhoto,
    );
    await updateLovedOne(renewed);
  }
}
