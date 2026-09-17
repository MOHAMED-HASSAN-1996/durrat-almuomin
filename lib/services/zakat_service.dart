import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zakat_model.dart';

class ZakatService {
  ZakatService._();
  static final ZakatService instance = ZakatService._();

  static const _calcKey = 'adhkar.zakat_calc_v1';
  static const _beneficiariesKey = 'adhkar.zakat_beneficiaries_v1';

  ZakatCalculationState _calcState = ZakatCalculationState();
  final List<ZakatBeneficiary> _beneficiaries = [];
  bool _loaded = false;

  ZakatCalculationState get calcState => _calcState;
  List<ZakatBeneficiary> get beneficiaries => List.unmodifiable(_beneficiaries);

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
    await _persistBeneficiaries();
  }

  Future<void> updateBeneficiary(ZakatBeneficiary b) async {
    await load();
    final idx = _beneficiaries.indexWhere((e) => e.id == b.id);
    if (idx != -1) {
      _beneficiaries[idx] = b;
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
