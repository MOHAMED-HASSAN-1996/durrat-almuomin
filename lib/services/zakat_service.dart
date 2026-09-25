import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zakat_model.dart';

class ZakatService {
  ZakatService._();
  static final ZakatService instance = ZakatService._();

  static const _calcKey = 'adhkar.zakat_calc_v1';
  static const _beneficiariesKey = 'adhkar.zakat_beneficiaries_v1';
  static const _groupsKey = 'adhkar.ben_groups_v1';
  static const defaultGroup = 'عام';

  ZakatCalculationState _calcState = ZakatCalculationState();
  final List<ZakatBeneficiary> _beneficiaries = [];
  final List<String> _groups = [defaultGroup];
  bool _loaded = false;

  ZakatCalculationState get calcState => _calcState;
  List<ZakatBeneficiary> get beneficiaries => List.unmodifiable(_beneficiaries);

  /// Custom groups (tabs). Always contains at least [defaultGroup].
  List<String> get beneficiaryGroups => List.unmodifiable(_groups);

  /// Distinct groups actually used by non-udhiyah beneficiaries, in stable order.
  List<String> usedGroups({bool includeUdhiyah = false}) {
    final ordered = <String>[];
    for (final g in _groups) {
      if (!ordered.contains(g)) ordered.add(g);
    }
    for (final b in _beneficiaries) {
      if (!includeUdhiyah && b.isUdhiyahType) continue;
      if (!ordered.contains(b.group)) ordered.add(b.group);
    }
    if (ordered.isEmpty) ordered.add(defaultGroup);
    return ordered;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final calcRaw = prefs.getString(_calcKey);
      if (calcRaw != null && calcRaw.isNotEmpty) {
        _calcState = ZakatCalculationState.fromMap(
          jsonDecode(calcRaw) as Map<String, dynamic>,
        );
      }

      final benRaw = prefs.getString(_beneficiariesKey);
      if (benRaw != null && benRaw.isNotEmpty) {
        final list = jsonDecode(benRaw) as List;
        _beneficiaries.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _beneficiaries.add(ZakatBeneficiary.fromMap(item));
          } else if (item is Map) {
            _beneficiaries.add(ZakatBeneficiary.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }

      final groupsRaw = prefs.getString(_groupsKey);
      _groups.clear();
      if (groupsRaw != null && groupsRaw.isNotEmpty) {
        try {
          final list = jsonDecode(groupsRaw) as List;
          for (final g in list) {
            final name = (g as String?)?.trim() ?? '';
            if (name.isNotEmpty && !_groups.contains(name)) _groups.add(name);
          }
        } catch (_) {}
      }
      // Merge groups found on beneficiaries (migration / safety).
      for (final b in _beneficiaries) {
        if (!_groups.contains(b.group)) _groups.add(b.group);
      }
      if (_groups.isEmpty) _groups.add(defaultGroup);
      await _persistGroups();
    } catch (e) {
      debugPrint('Error loading Zakat data: $e');
    }
    _loaded = true;
  }

  Future<void> saveCalculation(ZakatCalculationState state) async {
    _calcState = state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_calcKey, jsonEncode(state.toMap()));
    } catch (e) {
      debugPrint('Error saving Zakat calc: $e');
    }
  }

  Future<void> addBeneficiary(ZakatBeneficiary b) async {
    await load();
    _beneficiaries.insert(0, b);
    if (!_groups.contains(b.group)) {
      _groups.add(b.group);
      await _persistGroups();
    }
    await _persistBeneficiaries();
  }

  Future<void> updateBeneficiary(ZakatBeneficiary b) async {
    await load();
    final idx = _beneficiaries.indexWhere((e) => e.id == b.id);
    if (idx != -1) {
      _beneficiaries[idx] = b;
      if (!_groups.contains(b.group)) {
        _groups.add(b.group);
        await _persistGroups();
      }
      await _persistBeneficiaries();
    }
  }

  Future<void> toggleDelivered(String id) async {
    await load();
    final idx = _beneficiaries.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _beneficiaries[idx].isDelivered = !_beneficiaries[idx].isDelivered;
      await _persistBeneficiaries();
    }
  }

  Future<void> deleteBeneficiary(String id) async {
    await load();
    _beneficiaries.removeWhere((e) => e.id == id);
    await _persistBeneficiaries();
  }

  // ── Groups (tabs) ──────────────────────────────────────────────

  Future<bool> addGroup(String name) async {
    await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty || _groups.contains(trimmed)) return false;
    _groups.add(trimmed);
    await _persistGroups();
    return true;
  }

  Future<bool> renameGroup(String oldName, String newName) async {
    await load();
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName || _groups.contains(trimmed)) return false;
    final idx = _groups.indexOf(oldName);
    if (idx == -1) return false;
    _groups[idx] = trimmed;
    for (final b in _beneficiaries) {
      if (b.group == oldName) b.group = trimmed;
    }
    await _persistGroups();
    await _persistBeneficiaries();
    return true;
  }

  /// Deletes a group and moves its cards to [defaultGroup].
  /// Returns false when it is the last remaining group.
  Future<bool> deleteGroup(String name) async {
    await load();
    if (!_groups.contains(name) || _groups.length <= 1) return false;
    _groups.remove(name);
    if (!_groups.contains(defaultGroup)) _groups.insert(0, defaultGroup);
    for (final b in _beneficiaries) {
      if (b.group == name) b.group = defaultGroup;
    }
    await _persistGroups();
    await _persistBeneficiaries();
    return true;
  }

  Future<void> _persistGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groupsKey, jsonEncode(_groups));
    } catch (e) {
      debugPrint('Error saving ben groups: $e');
    }
  }

  Future<void> _persistBeneficiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_beneficiaries.map((e) => e.toMap()).toList());
      await prefs.setString(_beneficiariesKey, data);
    } catch (e) {
      debugPrint('Error saving beneficiaries: $e');
    }
  }
}
