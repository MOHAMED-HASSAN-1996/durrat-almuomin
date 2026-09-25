import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/zakat_model.dart';
import '../services/gold_price_service.dart';
import '../services/zakat_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

/// شاشة متكاملة تجمع:
/// 1. حاسبة الزكاة (أموال، ذهب، فضة، تجارة، أسهم، ديون)
/// 2. حاسبة النصاب (نصاب الذهب 85 جم والفضة 595 جم وأسعار الجرام والشروط الفقهية)
/// 3. سجل مستحقي الزكاة (توزيع وإدارة مستحقي زكاة المال والصدقات)
/// 4. سجل مستحقي الأضاحي (توزيع حصص وأنصبة ولحوم الأضاحي)
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final ZakatService _service = ZakatService.instance;
  late ZakatCalculationState _calc;
  bool _loading = true;

  // Controllers
  final _goldPriceCtrl = TextEditingController();
  final _silverPriceCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _gold24kCtrl = TextEditingController();
  final _gold21kCtrl = TextEditingController();
  final _silverCtrl = TextEditingController();
  final _tradeCtrl = TextEditingController();
  final _stocksCtrl = TextEditingController();
  final _debtsToYouCtrl = TextEditingController();
  final _debtsOwedCtrl = TextEditingController();

  // Gold jewelry items
  List<_GoldJewelryItem> _goldJewelryItems = [];

  // Live prices
  bool _liveLoading = false;
  DateTime? _liveUpdatedAt;

  // Detected local currency (from country/locale), defaults to EGP.
  CurrencyInfo _currency = const CurrencyInfo(
    code: 'EGP',
    symbol: 'ج.م',
    nameAr: 'الجنيه المصري',
    nameEn: 'Egyptian Pound',
  );

  // Beneficiary groups (tabs)
  static const _benAllTab = 'الكل';
  String _selectedBenGroup = _benAllTab;
  String _selectedUdhiyahGroup = _benAllTab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    _calc = _service.calcState;

    _goldPriceCtrl.text = _calc.goldPricePerGram > 0 ? _calc.goldPricePerGram.toStringAsFixed(0) : '';
    _silverPriceCtrl.text = _calc.silverPricePerGram > 0 ? _calc.silverPricePerGram.toStringAsFixed(0) : '';
    if (_calc.cashAmount > 0) _cashCtrl.text = _calc.cashAmount.toStringAsFixed(0);
    if (_calc.goldWeightGrams24k > 0) _gold24kCtrl.text = _calc.goldWeightGrams24k.toStringAsFixed(1);
    if (_calc.goldWeightGrams21k > 0) _gold21kCtrl.text = _calc.goldWeightGrams21k.toStringAsFixed(1);
    if (_calc.silverWeightGrams > 0) _silverCtrl.text = _calc.silverWeightGrams.toStringAsFixed(0);
    if (_calc.tradeInventoryValue > 0) _tradeCtrl.text = _calc.tradeInventoryValue.toStringAsFixed(0);
    if (_calc.stocksAndInvestments > 0) _stocksCtrl.text = _calc.stocksAndInvestments.toStringAsFixed(0);
    if (_calc.debtsOwedToYou > 0) _debtsToYouCtrl.text = _calc.debtsOwedToYou.toStringAsFixed(0);
    if (_calc.debtsYouOwe > 0) _debtsOwedCtrl.text = _calc.debtsYouOwe.toStringAsFixed(0);

    final cached = await GoldPriceService.instance.loadCache();
    _liveUpdatedAt = cached?.updatedAt;
    final cur = await GoldPriceService.instance.loadCachedCurrency();
    if (cur != null && cur.code.isNotEmpty) _currency = cur;
    await _loadJewelry();

    // Refresh the detected currency from the device locale / IP in the
    // background so the price units always match the user's country.
    GoldPriceService.instance.detectCurrency().then((detected) {
      if (!mounted) return;
      if (detected.currency.code != _currency.code) {
        setState(() => _currency = detected.currency);
      }
    }).catchError((_) {});

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshLivePrices() async {
    if (_liveLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _liveLoading = true);
    try {
      final prices = await GoldPriceService.instance.fetchLive();
      _currency = prices.currency;
      _goldPriceCtrl.text = prices.gold24kPerGramLocal.toStringAsFixed(0);
      _silverPriceCtrl.text = prices.silverPerGramLocal.toStringAsFixed(0);
      _liveUpdatedAt = prices.updatedAt;
      _onValuesChanged();
      if (!mounted) return;
      AppToast.show(context, 
        SnackBar(
          content: Text(
            'تم تحديث الأسعار بالعملة المحلية (${_currency.nameAr}) — راجع محل الصاغة للدقة',
            style: TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          backgroundColor: DhikrColors.forest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 
        SnackBar(
          content: const Text(
            'تعذّر التحديث المباشر — تحقق من الإنترنت أو أدخل السعر يدوياً',
            style: TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _liveLoading = false);
    }
  }

  String _formatLiveTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _onValuesChanged() {
    _calc.goldPricePerGram = double.tryParse(_goldPriceCtrl.text.replaceAll(',', '')) ?? 3500.0;
    _calc.silverPricePerGram = double.tryParse(_silverPriceCtrl.text.replaceAll(',', '')) ?? 45.0;
    _calc.cashAmount = double.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.goldWeightGrams24k = double.tryParse(_gold24kCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.goldWeightGrams21k = double.tryParse(_gold21kCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.silverWeightGrams = double.tryParse(_silverCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.tradeInventoryValue = double.tryParse(_tradeCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.stocksAndInvestments = double.tryParse(_stocksCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.debtsOwedToYou = double.tryParse(_debtsToYouCtrl.text.replaceAll(',', '')) ?? 0.0;
    _calc.debtsYouOwe = double.tryParse(_debtsOwedCtrl.text.replaceAll(',', '')) ?? 0.0;

    _service.saveCalculation(_calc);
    setState(() {});
  }

  void _resetCalculator() {
    HapticFeedback.mediumImpact();
    setState(() {
      _cashCtrl.clear();
      _gold24kCtrl.clear();
      _gold21kCtrl.clear();
      _silverCtrl.clear();
      _tradeCtrl.clear();
      _stocksCtrl.clear();
      _debtsToYouCtrl.clear();
      _debtsOwedCtrl.clear();
      _calc = ZakatCalculationState(
        goldPricePerGram: double.tryParse(_goldPriceCtrl.text) ?? 3500.0,
        silverPricePerGram: double.tryParse(_silverPriceCtrl.text) ?? 45.0,
      );
    });
    _service.saveCalculation(_calc);
  }

  void _showAddBeneficiarySheet({
    ZakatBeneficiary? toEdit,
    String defaultType = 'fuqara',
    bool isUdhiyahOnly = false,
    String? defaultGroup,
  }) {
    final nameCtrl = TextEditingController(text: toEdit?.name ?? '');
    final amountCtrl = TextEditingController(text: toEdit?.amountOrShare ?? '');
    final phoneCtrl = TextEditingController(text: toEdit?.phone ?? '');
    final notesCtrl = TextEditingController(text: toEdit?.notes ?? '');
    final newGroupCtrl = TextEditingController();
    var selectedType = toEdit?.type ?? defaultType;
    var selectedGroup = toEdit?.group ?? defaultGroup ?? ZakatService.defaultGroup;
    var creatingNewGroup = false;

    DateTime? selectedDueDate = toEdit?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final isAr = context.watch<AppState>().language == AppLanguage.arabic;
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 28, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 36),
                decoration: BoxDecoration(
                  color: dark ? DhikrColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        toEdit != null
                            ? 'تعديل بيانات المستحق'
                            : (isUdhiyahOnly ? 'إضافة مستحق أضحية 🐑' : 'إضافة مستحق زكاة أو صدقة 🤲'),
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type selector chips — different per tab
                      if (isUdhiyahOnly) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: UdhiyahCategory.values.map((t) {
                            final selected = selectedType == t.name;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedType = t.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected ? t.color.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? t.color : (dark ? Colors.white24 : Colors.black26),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  t.badgeAr,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 13,
                                    color: selected ? t.color : (dark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ZakatCategory.values.map((t) {
                            final selected = selectedType == t.name;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedType = t.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected ? t.color.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? t.color : (dark ? Colors.white24 : Colors.black26),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  t.badgeAr,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 13,
                                    color: selected ? t.color : (dark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Group selector (which tab the card belongs to)
                      ...[
                        const Text(
                          'المجموعة',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._service.usedGroups(includeUdhiyah: true).map((g) {
                              final selected = !creatingNewGroup && selectedGroup == g;
                              return GestureDetector(
                                onTap: () => setModalState(() {
                                  selectedGroup = g;
                                  creatingNewGroup = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? DhikrColors.forest.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected ? DhikrColors.forest : (dark ? Colors.white24 : Colors.black26),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12.5,
                                      color: selected
                                          ? DhikrColors.forest
                                          : (dark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: () => setModalState(() => creatingNewGroup = !creatingNewGroup),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: creatingNewGroup
                                      ? DhikrColors.forest.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: creatingNewGroup ? DhikrColors.forest : (dark ? Colors.white24 : Colors.black26),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.plus, size: 13, color: DhikrColors.forest),
                                    SizedBox(width: 4),
                                    Text(
                                      'مجموعة جديدة',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: DhikrColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (creatingNewGroup) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: newGroupCtrl,
                            autofocus: true,
                            style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'اسم المجموعة الجديدة (مثال: الجيران)',
                              hintStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 12),
                              filled: true,
                              fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],

                      // Name
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: isUdhiyahOnly ? 'اسم المستحق / الأسرة للأضحية' : 'اسم المستحق أو الأسرة',
                          labelStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont),
                          filled: true,
                          fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Amount or Share
                      TextField(
                        controller: amountCtrl,
                        style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: isUdhiyahOnly
                              ? 'النصيب (مثال: خروف كامل، سهم عجل، 5 كجم)'
                              : 'المبلغ المخصص (مثال: 2,500 ${_currency.symbol})',
                          labelStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont),
                          filled: true,
                          fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          labelStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont),
                          filled: true,
                          fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Due Date and Time - Two distinct fields (Date & Time separated)
                      Row(
                        children: [
                          // 1. Date Field — بدون chip، الكارت نفسه قابل للضغط + 12px زيادة فوق وتحت
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final initial = selectedDueDate ?? now;
                                final pickedDate = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: initial,
                                  firstDate: now.subtract(const Duration(days: 365)),
                                  lastDate: now.add(const Duration(days: 365)),
                                  locale: const Locale('ar'),
                                );
                                if (pickedDate == null) return;
                                setModalState(() {
                                  selectedDueDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    selectedDueDate?.hour ?? now.hour,
                                    selectedDueDate?.minute ?? now.minute,
                                  );
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selectedDueDate != null
                                        ? DhikrColors.forest.withValues(alpha: 0.35)
                                        : (dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.calendar, size: 14, color: DhikrColors.forest),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'تاريخ الميعاد:',
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedDueDate != null
                                          ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                                          : 'غير محدد',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: selectedDueDate != null ? FontWeight.w800 : FontWeight.w500,
                                        fontSize: 12.5,
                                        color: selectedDueDate != null
                                            ? (dark ? DhikrColors.sand : DhikrColors.forest)
                                            : (dark ? Colors.white54 : Colors.black45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. Time Field — بدون chip، الكارت نفسه قابل للضغط — مصغر زي الفيلد الفوقي
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final initial = selectedDueDate ?? now;
                                final pickedTime = await showTimePicker(
                                  context: sheetContext,
                                  initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
                                );
                                if (pickedTime == null) return;
                                setModalState(() {
                                  final baseDate = selectedDueDate ?? now;
                                  selectedDueDate = DateTime(
                                    baseDate.year,
                                    baseDate.month,
                                    baseDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selectedDueDate != null
                                        ? DhikrColors.forest.withValues(alpha: 0.35)
                                        : (dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock, size: 14, color: DhikrColors.forest),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'وقت التسليم:',
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedDueDate != null
                                          ? (() {
                                              final h = selectedDueDate!.hour > 12
                                                  ? selectedDueDate!.hour - 12
                                                  : (selectedDueDate!.hour == 0 ? 12 : selectedDueDate!.hour);
                                              final m = selectedDueDate!.minute.toString().padLeft(2, '0');
                                              final a = selectedDueDate!.hour >= 12 ? 'م' : 'ص';
                                              return '$h:$m $a';
                                            })()
                                          : 'غير محدد',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: selectedDueDate != null ? FontWeight.w800 : FontWeight.w500,
                                        fontSize: 12.5,
                                        color: selectedDueDate != null
                                            ? (dark ? DhikrColors.sand : DhikrColors.forest)
                                            : (dark ? Colors.white54 : Colors.black45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      TextField(
                        controller: notesCtrl,
                        style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'ملاحظات / العنوان',
                          labelStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont),
                          filled: true,
                          fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save button (واضح ومميز)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            HapticFeedback.selectionClick();

                            var group = selectedGroup;
                            if (creatingNewGroup) {
                              final typed = newGroupCtrl.text.trim();
                              if (typed.isNotEmpty) {
                                await _service.addGroup(typed);
                                group = typed;
                              }
                            }
                            if (group.trim().isEmpty) group = ZakatService.defaultGroup;

                            final b = ZakatBeneficiary(
                              id: toEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: name,
                              type: selectedType,
                              amountOrShare: amountCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              isDelivered: toEdit?.isDelivered ?? false,
                              dueDate: selectedDueDate,
                              createdAt: toEdit?.createdAt,
                              group: group,
                            );

                            if (toEdit != null) {
                              await _service.updateBeneficiary(b);
                            } else {
                              await _service.addBeneficiary(b);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {
                              // Jump to the tab where the card was saved.
                              if (isUdhiyahOnly) {
                                _selectedUdhiyahGroup = b.group;
                              } else {
                                _selectedBenGroup = b.group;
                              }
                            });
                          },
                          icon: const Icon(LucideIcons.checkCircle2, size: 20, color: Colors.white),
                          label: Text(
                            toEdit != null ? 'حفظ التعديلات' : 'إضافة إلى السجل والجدول',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DhikrColors.forest,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: DhikrColors.forest.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _goldPriceCtrl.dispose();
    _silverPriceCtrl.dispose();
    _cashCtrl.dispose();
    _gold24kCtrl.dispose();
    _gold21kCtrl.dispose();
    _silverCtrl.dispose();
    _tradeCtrl.dispose();
    _stocksCtrl.dispose();
    _debtsToYouCtrl.dispose();
    _debtsOwedCtrl.dispose();
    super.dispose();
  }

  String get _pageTitle {
    switch (widget.initialTabIndex) {
      case 1:
        return 'حاسبة النصاب الشرعي';
      case 2:
        return 'مستحقو الزكاة والصدقات';
      case 3:
        return 'مستحقو الأضاحي';
      case 0:
      default:
        return 'حاسبة الزكاة';
    }
  }

  Widget _buildSelectedTab(bool dark) {
    switch (widget.initialTabIndex) {
      case 1:
        return _buildNisabCalcTab(dark);
      case 2:
        return _buildZakatBeneficiariesTab(dark);
      case 3:
        return _buildUdhiyahBeneficiariesTab(dark);
      case 0:
      default:
        return _buildZakatCalcTab(dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
        appBar: AppBar(
          title: Text(
            _pageTitle,
            style: const TextStyle(
              fontFamily: DhikrTheme.titleFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (dark ? Colors.white : DhikrColors.forest).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.bookOpenCheck,
                  size: 19,
                  color: dark ? DhikrColors.sage : DhikrColors.forest,
                ),
              ),
              tooltip: 'دليل الحاسبة والتطبيق العملي',
              onPressed: () => _showPracticalGuideSheet(context, dark, widget.initialTabIndex),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: DhikrColors.forest))
            : SafeArea(
                child: _buildSelectedTab(dark),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1: حاسبة الزكاة (ZAKAT CALCULATOR)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildZakatCalcTab(bool dark) {
    final totalWealth = _calc.totalZakatableWealth;
    final zakatDue = _calc.zakatDue;
    final debtsOwed = _calc.debtsYouOwe;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Zakat Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? [DhikrColors.darkSurface, DhikrColors.darkSurfaceHigh]
                  : [DhikrColors.forestDeep, DhikrColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (dark ? DhikrColors.forestLight : DhikrColors.sand).withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? Colors.black : DhikrColors.forestDeep).withValues(alpha: dark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DhikrColors.sand.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          LucideIcons.calculator,
                          color: DhikrColors.sand,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مقدار الزكاة الواجب إخراجها',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: DhikrColors.sand,
                            ),
                          ),
                          Text(
                            _formatCurrency(zakatDue),
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'تفريغ الحقول',
                    onPressed: _resetCalculator,
                    icon: const Icon(LucideIcons.rotateCcw, color: DhikrColors.sand, size: 20),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي الأموال والأصول',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        _formatCurrency(totalWealth + debtsOwed),
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: Colors.white24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'صافي الوعاء الزكوي',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        _formatCurrency(totalWealth),
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: DhikrColors.sand,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Cash & Savings
        _buildSectionTitle('1. السيولة النقدية والحسابات البنكية', dark),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _cashCtrl,
          label: 'إجمالي الأموال والودائع البنكية الحرة',
          suffix: _currency.symbol,
          icon: LucideIcons.wallet,
          dark: dark,
          onChanged: (_) => _onValuesChanged(),
        ),
        const SizedBox(height: 20),

        // Section: Gold & Silver
        _buildSectionTitle('2. الذهب والفضة المدخرين', dark),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _gold24kCtrl,
                label: 'ذهب عيار 24 (سبائك)',
                suffix: 'جرام',
                icon: LucideIcons.award,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                controller: _gold21kCtrl,
                label: 'ذهب عيار 21 (مدخر)',
                suffix: 'جرام',
                icon: LucideIcons.award,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _silverCtrl,
          label: 'فضة مدخرة',
          suffix: 'جرام',
          icon: LucideIcons.circleDot,
          dark: dark,
          onChanged: (_) => _onValuesChanged(),
        ),
        const SizedBox(height: 10),

        // Section: Trade Goods & Investments
        _buildSectionTitle('3. عروض التجارة والاستثمارات', dark),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _tradeCtrl,
          label: 'قيمة بضائع التجارة المعدة للبيع (بسعر البيع الحالي)',
          suffix: _currency.symbol,
          icon: LucideIcons.store,
          dark: dark,
          onChanged: (_) => _onValuesChanged(),
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _stocksCtrl,
          label: 'الأسهم والصناديق الاستثمارية',
          suffix: _currency.symbol,
          icon: LucideIcons.trendingUp,
          dark: dark,
          onChanged: (_) => _onValuesChanged(),
        ),
        const SizedBox(height: 20),

        // Section: Debts
        _buildSectionTitle('4. الديون لك وعليك', dark),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _debtsToYouCtrl,
                label: 'ديون مرجوة لك (+)',
                suffix: _currency.symbol,
                icon: LucideIcons.plusCircle,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                controller: _debtsOwedCtrl,
                label: 'ديون حالّة عليك (-)',
                suffix: _currency.symbol,
                icon: LucideIcons.minusCircle,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _onValuesChanged();
              AppToast.show(context, 
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('تم حفظ ومزامنة حسابات الزكاة بنجاح', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  backgroundColor: DhikrColors.forest,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(LucideIcons.save, size: 18),
            label: const Text(
              'حفظ الحسابات في السجل',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DhikrColors.forest,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2: حاسبة النصاب (NISAB CALCULATOR)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNisabCalcTab(bool dark) {
    final goldNisab = _calc.goldNisabThreshold;
    final silverNisab = _calc.silverNisabThreshold;
    final totalWealth = _calc.totalZakatableWealth;
    // Jewelry counts toward nisab (converted to 24k-equivalent value).
    final jewelryValue = _goldJewelryItems.fold<double>(
      0,
      (sum, e) => sum + e.weight * e.purity * _calc.goldPricePerGram,
    );
    final combinedWealth = totalWealth + jewelryValue;
    final reachesGold = combinedWealth >= goldNisab && goldNisab > 0;
    final reachesSilver = combinedWealth >= silverNisab && silverNisab > 0;
    final dueCount = _goldJewelryItems.where(_isItemDue).length;
    final hasDue = dueCount > 0;

    final bannerColors = hasDue
        ? (dark ? [const Color(0xFF2A1512), const Color(0xFF180D0B)] : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)])
        : reachesGold
            ? (dark ? [const Color(0xFF1B2A22), const Color(0xFF101C16)] : [const Color(0xFFEAF5EE), const Color(0xFFD8ECDF)])
            : (dark ? [const Color(0xFF261D10), const Color(0xFF161108)] : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]);
    final bannerAccent = hasDue
        ? const Color(0xFFEF4444)
        : reachesGold
            ? DhikrColors.forest
            : const Color(0xFFD97706);
    final bannerTitle = hasDue
        ? 'حان موعد الزكاة'
        : reachesGold
            ? 'بلغت النصاب'
            : 'لم تبلغ النصاب بعد';
    final bannerSubtitle = hasDue
        ? 'لديك $dueCount ${dueCount == 1 ? 'مشغول مستحق' : 'مشغولات مستحقة'} — سدد وسجّل السداد'
        : reachesGold
            ? 'تجب الزكاة 2.5% إذا حال عليها الحول'
            : 'أكمل إدخال الأموال لمعرفة بلوغ النصاب';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
      children: [
        // ── Status Banner ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bannerColors,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bannerAccent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: bannerAccent.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: bannerAccent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      hasDue
                          ? LucideIcons.alertTriangle
                          : reachesGold
                              ? LucideIcons.checkCircle
                              : LucideIcons.scale,
                      color: bannerAccent,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bannerTitle,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: hasDue
                                ? const Color(0xFFEF4444)
                                : reachesGold
                                    ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                    : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bannerSubtitle,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            height: 1.6,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_goldJewelryItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'قيمة المشغولات (${_goldJewelryItems.length} ${ _goldJewelryItems.length == 1 ? 'قطعة' : 'قطع'})',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                    Text(
                      _formatCurrency(jewelryValue),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: bannerAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Nisab Values Card ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              // Gold Nisab
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: reachesGold
                            ? DhikrColors.forest.withValues(alpha: 0.12)
                            : const Color(0xFFD97706).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.coins,
                        size: 19,
                        color: reachesGold ? DhikrColors.forest : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نصاب الذهب',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : DhikrColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '85 جراماً · عيار 24',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(goldNisab),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: reachesGold ? DhikrColors.forest : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
              // Silver Nisab
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: reachesSilver
                            ? DhikrColors.forest.withValues(alpha: 0.12)
                            : const Color(0xFFD97706).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.circleDot,
                        size: 19,
                        color: reachesSilver ? DhikrColors.forest : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نصاب الفضة',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : DhikrColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '595 جراماً',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(silverNisab),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: reachesSilver ? DhikrColors.forest : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Price Configuration ──
        _buildNisabSectionHeader(
          icon: LucideIcons.coins,
          title: 'أسعار اليوم',
          subtitle: 'سعر استرشادي مباشر (${_currency.nameAr}) — راجع الصاغة للدقة',
          dark: dark,
          trailing: _buildLiveRefreshButton(dark),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldCaption('ذهب عيار 24', dark),
                  const SizedBox(height: 6),
                  _buildNisabInputField(
                    controller: _goldPriceCtrl,
                    hint: '0',
                    suffix: _currency.symbol,
                    dark: dark,
                    onChanged: (_) => _onValuesChanged(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldCaption('الفضة', dark),
                  const SizedBox(height: 6),
                  _buildNisabInputField(
                    controller: _silverPriceCtrl,
                    hint: '0',
                    suffix: _currency.symbol,
                    dark: dark,
                    onChanged: (_) => _onValuesChanged(),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_liveUpdatedAt != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.wifi, size: 11, color: DhikrColors.forest),
              const SizedBox(width: 4),
              Text(
                'آخر تحديث مباشر ${_formatLiveTime(_liveUpdatedAt!)}',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 10,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        _buildDetectedCurrencyBadge(dark),
        const SizedBox(height: 22),

        // ── Gold Jewelry Section ──
        _buildNisabSectionHeader(
          icon: LucideIcons.award,
          title: 'المشغولات الذهبية',
          subtitle: 'أضف مشغولاتك مع تاريخ الشراء لمتابعة موعد الزكاة',
          dark: dark,
        ),
        const SizedBox(height: 10),

        // Gold jewelry items list
        ...List.generate(_goldJewelryItems.length, (i) {
          final item = _goldJewelryItems[i];
          final hijriDate = _getHijriDate(item.hawlStart);
          final isDue = _isItemDue(item);
          return InkWell(
            onTap: () => _showAddGoldItemSheet(context, dark, editIndex: i),
            borderRadius: BorderRadius.circular(14),
            child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? DhikrColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDue
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : const Color(0xFFD97706).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDue
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : const Color(0xFFD97706).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDue ? LucideIcons.alertTriangle : LucideIcons.award,
                    color: isDue ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${item.weight.toStringAsFixed(1)} جم',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                          Text(' • ', style: TextStyle(
                            fontSize: 11,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          )),
                          Text(
                            'عيار ${item.karat}',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                      if (item.lastZakatPaidAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'آخر سداد ${_formatLiveTime(item.lastZakatPaidAt!)}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 10,
                            color: DhikrColors.forest,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isDue)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'حان الزكاة',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _confirmPayGoldItem(context, i, dark),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: DhikrColors.forest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'سددت الزكاة',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'منذ $hijriDate',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 10,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmDeleteGoldItem(context, i, dark),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            ),
          );
        }),

        // Add button
        InkWell(
          onTap: () => _showAddGoldItemSheet(context, dark),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: dark ? DhikrColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, size: 16, color: const Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  'إضافة مشغول ذهبي',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedCurrencyBadge(bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFFD97706).withValues(alpha: 0.12)
            : const Color(0xFFD97706).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFFD97706)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'العملة تلقائيًا حسب موقعك: ${_currency.nameAr} (${_currency.symbol}) — سعر الجرام والفضة والنصاب بهذه العملة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10.5,
                height: 1.5,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRefreshButton(bool dark) {
    return InkWell(
      onTap: _liveLoading ? null : _refreshLivePrices,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: DhikrColors.forest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DhikrColors.forest.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_liveLoading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DhikrColors.forest,
                ),
              )
            else
              const Icon(LucideIcons.refreshCw, size: 13, color: DhikrColors.forest),
            const SizedBox(width: 4),
            const Text(
              'تحديث مباشر',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: DhikrColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNisabSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool dark,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFD97706)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: dark ? Colors.white : DhikrColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11,
                  height: 1.5,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildFieldCaption(String text, bool dark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
      ),
    );
  }

  Widget _buildNisabInputField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required bool dark,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: dark ? Colors.white : DhikrColors.charcoal,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 14,
          color: dark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFB0B8C1),
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: dark ? DhikrColors.sage : DhikrColors.forest,
        ),
        filled: true,
        fillColor: dark ? DhikrColors.darkSurface : const Color(0xFFFAFAF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }

  Widget _buildFiqhRuleItem(String title, String desc, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DhikrColors.forest,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                    text: desc,
                    style: TextStyle(
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3: مستحقو الزكاة (ZAKAT BENEFICIARIES)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildZakatBeneficiariesTab(bool dark) {
    final allList = _service.beneficiaries;
    final baseList = allList.where((e) => e.isZakatType).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = _service.usedGroups(includeUdhiyah: true);
    if (_selectedBenGroup != _benAllTab && !groups.contains(_selectedBenGroup)) {
      _selectedBenGroup = _benAllTab;
    }
    final list = _selectedBenGroup == _benAllTab
        ? baseList
        : baseList.where((e) => e.group == _selectedBenGroup).toList();
    final deliveredCount = list.where((e) => e.isDelivered).length;

    String defaultGroupForAdd() {
      if (_selectedBenGroup != _benAllTab && groups.contains(_selectedBenGroup)) {
        return _selectedBenGroup;
      }
      return ZakatService.defaultGroup;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBeneficiarySheet(
          defaultType: ZakatCategory.fuqara.name,
          isUdhiyahOnly: false,
          defaultGroup: defaultGroupForAdd(),
        ),
        backgroundColor: DhikrColors.forest,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.userPlus, size: 18),
        label: const Text('إضافة مستحق زكاة', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _buildGroupsTabBar(
            dark: dark,
            groups: groups,
            baseList: baseList,
            selected: _selectedBenGroup,
            onSelect: (g) => setState(() => _selectedBenGroup = g),
            isUdhiyahTab: false,
          ),
          Expanded(
            child: baseList.isEmpty
                ? _buildEmptyState(
                    icon: LucideIcons.handCoins,
                    title: 'سجل مستحقي الزكاة والصدقات فارغ',
                    subtitle: 'أضف الأسر والأفراد المستحقين لزكاة المال أو الصدقات لمتابعة المبالغ وتسليمها',
                    dark: dark,
                  )
                : list.isEmpty
                    ? _buildEmptyState(
                        icon: LucideIcons.folderOpen,
                        title: 'لا توجد كروت في "$_selectedBenGroup"',
                        subtitle: 'أضف كارتاً جديداً وسيُحفظ تلقائياً في هذه المجموعة',
                        dark: dark,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                        children: [
                          _buildStatsBar(
                            totalLabel: _selectedBenGroup == _benAllTab
                                ? 'إجمالي المستحقين: ${list.length}'
                                : 'مجموعة "$_selectedBenGroup": ${list.length}',
                            deliveredLabel: 'تم الصرف: $deliveredCount من ${list.length}',
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _buildBeneficiaryCard(list[i], dark, isUdhiyah: false),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  /// Scrollable groups tab bar above the beneficiary cards (shared by zakat & udhiyah tabs).
  Widget _buildGroupsTabBar({
    required bool dark,
    required List<String> groups,
    required List<ZakatBeneficiary> baseList,
    required String selected,
    required ValueChanged<String> onSelect,
    required bool isUdhiyahTab,
  }) {
    int countOf(String group) {
      if (group == _benAllTab) return baseList.length;
      return baseList.where((e) => e.group == group).length;
    }

    Widget tab(String label, {required bool selected, required VoidCallback onTap, VoidCallback? onLongPress}) {
      final count = countOf(label);      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? DhikrColors.forest
                : (dark ? DhikrColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? DhikrColors.forest
                  : (dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  color: selected
                      ? Colors.white
                      : (dark ? Colors.white70 : DhikrColors.charcoal),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : DhikrColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : DhikrColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            tab(
              _benAllTab,
              selected: selected == _benAllTab,
              onTap: () => onSelect(_benAllTab),
            ),
            ...groups.map((g) => tab(
                  g,
                  selected: selected == g,
                  onTap: () => onSelect(g),
                  onLongPress: () => _showManageGroupDialog(g, dark, isUdhiyahTab: isUdhiyahTab),
                )),
            // Add-new-group button
            GestureDetector(
              onTap: () => _showManageGroupDialog(null, dark, isUdhiyahTab: isUdhiyahTab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DhikrColors.forest.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: DhikrColors.forest),
                    SizedBox(width: 4),
                    Text(
                      'مجموعة',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: DhikrColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a new group (name == null) or rename/delete an existing one.
  void _showManageGroupDialog(String? group, bool dark, {required bool isUdhiyahTab}) {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController(text: group ?? '');
    final isNew = group == null;

    void setActiveTab(String value) {
      setState(() {
        if (isUdhiyahTab) {
          _selectedUdhiyahGroup = value;
        } else {
          _selectedBenGroup = value;
        }
      });
    }

    String activeTab() => isUdhiyahTab ? _selectedUdhiyahGroup : _selectedBenGroup;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isNew ? 'مجموعة جديدة' : 'إدارة "$group"',
          style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: isNew,
              style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اسم المجموعة (مثال: الأقارب، الجيران)',
                hintStyle: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12),
                filled: true,
                fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            if (!isNew) ...[
              const SizedBox(height: 8),
              Text(
                'حذف المجموعة ينقل كروتها إلى "عام" ولا يحذف الكروت نفسها.',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isNew)
            TextButton(
              onPressed: () async {
                final ok = await _service.deleteGroup(group);
                if (!mounted) return;
                if (!ok) {
                  AppToast.show(context, 
                    const SnackBar(
                      content: Text(
                        'لا يمكن حذف آخر مجموعة',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                if (activeTab() == group) setActiveTab(_benAllTab);
                AppToast.show(context, 
                  SnackBar(
                    content: Text(
                      'تم حذف "$group" ونقل كروتها إلى "عام"',
                      style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                    ),
                    backgroundColor: DhikrColors.forest,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Color(0xFFEF4444)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              bool ok;
              if (isNew) {
                ok = await _service.addGroup(name);
                if (!mounted) return;
                if (!ok) {
                  AppToast.show(context, 
                    const SnackBar(
                      content: Text(
                        'هذه المجموعة موجودة بالفعل',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setActiveTab(name);
              } else {
                ok = await _service.renameGroup(group, name);
                if (!mounted) return;
                if (!ok) {
                  AppToast.show(context, 
                    const SnackBar(
                      content: Text(
                        'تعذّر التعديل — الاسم موجود أو فارغ',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                if (activeTab() == group) setActiveTab(name);
              }
              if (!mounted) return;
              AppToast.show(context, 
                SnackBar(
                  content: Text(
                    isNew ? 'تم إنشاء مجموعة "$name"' : 'تم تعديل المجموعة',
                    style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                  ),
                  backgroundColor: DhikrColors.forest,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              isNew ? 'إنشاء' : 'حفظ',
              style: const TextStyle(fontFamily: DhikrTheme.arabicFont, color: DhikrColors.forest),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4: مستحقو الأضاحي (UDHIYAH BENEFICIARIES)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUdhiyahBeneficiariesTab(bool dark) {
    final allList = _service.beneficiaries;
    final baseList = allList.where((e) => e.isUdhiyahType).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = _service.usedGroups(includeUdhiyah: true);
    if (_selectedUdhiyahGroup != _benAllTab && !groups.contains(_selectedUdhiyahGroup)) {
      _selectedUdhiyahGroup = _benAllTab;
    }
    final list = _selectedUdhiyahGroup == _benAllTab
        ? baseList
        : baseList.where((e) => e.group == _selectedUdhiyahGroup).toList();
    final deliveredCount = list.where((e) => e.isDelivered).length;

    String defaultGroupForAdd() {
      if (_selectedUdhiyahGroup != _benAllTab && groups.contains(_selectedUdhiyahGroup)) {
        return _selectedUdhiyahGroup;
      }
      return ZakatService.defaultGroup;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBeneficiarySheet(
          defaultType: UdhiyahCategory.relatives.name,
          isUdhiyahOnly: true,
          defaultGroup: defaultGroupForAdd(),
        ),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.heartHandshake, size: 18),
        label: const Text('إضافة مستحق أضحية', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _buildGroupsTabBar(
            dark: dark,
            groups: groups,
            baseList: baseList,
            selected: _selectedUdhiyahGroup,
            onSelect: (g) => setState(() => _selectedUdhiyahGroup = g),
            isUdhiyahTab: true,
          ),
          Expanded(
            child: baseList.isEmpty
                ? _buildEmptyState(
                    icon: LucideIcons.heartHandshake,
                    title: 'سجل توزيع الأضاحي فارغ',
                    subtitle: 'أضف العائلات والمستحقين لحصص ولحوم الأضاحي لتنظيم عملية الذبح والتوزيع بدقة',
                    dark: dark,
                  )
                : list.isEmpty
                    ? _buildEmptyState(
                        icon: LucideIcons.folderOpen,
                        title: 'لا توجد كروت في "$_selectedUdhiyahGroup"',
                        subtitle: 'أضف كارتاً جديداً وسيُحفظ تلقائياً في هذه المجموعة',
                        dark: dark,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                        children: [
                          _buildStatsBar(
                            totalLabel: _selectedUdhiyahGroup == _benAllTab
                                ? 'إجمالي أنصبة الأضاحي: ${list.length}'
                                : 'مجموعة "$_selectedUdhiyahGroup": ${list.length}',
                            deliveredLabel: 'تم التسليم: $deliveredCount من ${list.length}',
                            dark: dark,
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _buildBeneficiaryCard(list[i], dark, isUdhiyah: true),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _getHijriDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    final hijriYears = diff ~/ 354;
    final hijriMonths = ((diff % 354) ~/ 29.5).toInt();
    if (hijriYears == 0 && hijriMonths == 0) return '$diff يوماً';
    if (hijriYears == 0) return '$hijriMonths شهراً';
    if (hijriMonths == 0) return '$hijriYears سنة هجرية';
    return '$hijriYears سنة و $hijriMonths شهر';
  }

  bool _isItemDue(_GoldJewelryItem item) {
    return DateTime.now().difference(item.hawlStart).inDays >= 354;
  }

  static const _jewelryPrefsKey = 'adhkar.gold_jewelry_v1';

  Future<void> _persistJewelry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_goldJewelryItems.map((e) => e.toMap()).toList());
      await prefs.setString(_jewelryPrefsKey, raw);
    } catch (e) {
      debugPrint('Jewelry persist failed: $e');
    }
  }

  Future<void> _loadJewelry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_jewelryPrefsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      _goldJewelryItems = list
          .whereType<Map<String, dynamic>>()
          .map(_GoldJewelryItem.fromMap)
          .whereType<_GoldJewelryItem>()
          .toList();
    } catch (e) {
      debugPrint('Jewelry load failed: $e');
    }
  }

  void _confirmDeleteGoldItem(BuildContext context, int index, bool dark) {
    HapticFeedback.lightImpact();
    final item = _goldJewelryItems[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            const Text(
              'حذف المشغول',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${item.name}"؟',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _goldJewelryItems.removeAt(index));
              _persistJewelry();
              AppToast.show(context, 
                SnackBar(
                  content: Text(
                    'تم حذف "${item.name}"',
                    style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'تراجع',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() => _goldJewelryItems.insert(index, item));
                      _persistJewelry();
                    },
                  ),
                ),
              );
            },
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayGoldItem(BuildContext context, int index, bool dark) {
    HapticFeedback.lightImpact();
    if (index < 0 || index >= _goldJewelryItems.length) return;
    final item = _goldJewelryItems[index];
    final dueAmount = _calc.goldPricePerGram > 0
        ? item.weight * item.purity * _calc.goldPricePerGram * 0.025
        : 0.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.handCoins, color: DhikrColors.forest, size: 22),
            const SizedBox(width: 8),
            const Text(
              'تسجيل سداد الزكاة',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم سداد زكاة "${item.name}"؟ سيبدأ حول جديد من اليوم.',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                height: 1.6,
              ),
            ),
            if (dueAmount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DhikrColors.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المستحق التقريبي (2.5%)',
                      style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12),
                    ),
                    Text(
                      _formatCurrency(dueAmount),
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        color: DhikrColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final prev = _goldJewelryItems[index];
              setState(() {
                _goldJewelryItems[index] = _GoldJewelryItem(
                  name: prev.name,
                  weight: prev.weight,
                  karat: prev.karat,
                  purchaseDate: prev.purchaseDate,
                  lastZakatPaidAt: DateTime.now(),
                );
              });
              _persistJewelry();
              AppToast.show(context, 
                SnackBar(
                  content: const Text(
                    'تم تسجيل السداد — يبدأ حول جديد من اليوم',
                    style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                  ),
                  backgroundColor: DhikrColors.forest,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'تراجع',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() => _goldJewelryItems[index] = prev);
                      _persistJewelry();
                    },
                  ),
                ),
              );
            },
            child: const Text(
              'تأكيد السداد',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: DhikrColors.forest),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoldItemSheet(BuildContext context, bool dark, {int? editIndex}) {
    HapticFeedback.lightImpact();
    final existing = editIndex != null &&
        editIndex >= 0 &&
        editIndex < _goldJewelryItems.length
        ? _goldJewelryItems[editIndex]
        : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final weightCtrl = TextEditingController(
      text: existing != null ? existing.weight.toStringAsFixed(1) : '',
    );
    String selectedKarat = existing?.karat ?? '21';
    DateTime selectedDate = existing?.purchaseDate ?? DateTime.now();
    final isEditing = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isAr = context.read<AppState>().language == AppLanguage.arabic;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                decoration: BoxDecoration(
                  color: dark ? DhikrColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(LucideIcons.award, color: const Color(0xFFD97706), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'تعديل المشغول الذهبي' : 'إضافة مشغول ذهبي',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: dark ? Colors.white : DhikrColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'اسم المشغول',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: nameCtrl,
                        label: '',
                        hintText: 'مثال: خاتم، سلسلة، إسورة',
                        suffix: '',
                        icon: LucideIcons.tag,
                        dark: dark,
                        keyboardType: TextInputType.text,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'الوزن بالجرام',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: weightCtrl,
                        label: '',
                        hintText: 'مثال: 12.5',
                        suffix: 'جرام',
                        icon: LucideIcons.scale,
                        dark: dark,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'العيار',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: ['18', '21', '24'].map((k) {
                          final isSelected = selectedKarat == k;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedKarat = k),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD97706)
                                      : (dark ? DhikrColors.darkBg : const Color(0xFFF5F5F0)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD97706)
                                        : Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'عيار $k',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : (dark ? Colors.white70 : DhikrColors.charcoal),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تاريخ الشراء',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: dark ? DhikrColors.darkBg : const Color(0xFFF5F5F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 18, color: const Color(0xFFD97706)),
                              const SizedBox(width: 10),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 14,
                                  color: dark ? Colors.white : DhikrColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final weight = double.tryParse(weightCtrl.text.trim());
                            if (name.isEmpty || weight == null || weight <= 0) {
                              AppToast.show(ctx,
                                SnackBar(
                                  content: const Text(
                                    'من فضلك أدخل الاسم والوزن بشكل صحيح',
                                    style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            final updated = _GoldJewelryItem(
                              name: name,
                              weight: weight,
                              karat: selectedKarat,
                              purchaseDate: selectedDate,
                              lastZakatPaidAt: existing?.lastZakatPaidAt,
                            );
                            setState(() {
                              if (isEditing && editIndex != null) {
                                _goldJewelryItems[editIndex] = updated;
                              } else {
                                _goldJewelryItems.add(updated);
                              }
                            });
                            _persistJewelry();
                            Navigator.pop(ctx);
                            AppToast.show(context, 
                              SnackBar(
                                content: Text(
                                  isEditing ? 'تم حفظ تعديل "$name"' : 'تم إضافة "$name" بنجاح',
                                  style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                                ),
                                backgroundColor: DhikrColors.forest,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFFD97706).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isEditing ? 'حفظ التعديلات' : 'إضافة',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  COMMON BENEFICIARY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsBar({required String totalLabel, required String deliveredLabel, required bool dark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DhikrColors.forest.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalLabel,
            style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
          ),
          Text(
            deliveredLabel,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              color: DhikrColors.forest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle, required bool dark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DhikrColors.forest.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: DhikrColors.forest, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBeneficiaryDate(DateTime dt) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'م' : 'ص';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $amPm';

    if (isToday) {
      return 'اليوم • $timeStr';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $timeStr';
  }

  Widget _buildBeneficiaryCard(ZakatBeneficiary item, bool dark, {required bool isUdhiyah}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isDelivered
              ? DhikrColors.forest.withValues(alpha: 0.4)
              : BeneficiaryTypeHelper.color(item.type).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Checkbox(
              value: item.isDelivered,
              activeColor: DhikrColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (_) async {
                HapticFeedback.selectionClick();
                await _service.toggleDelivered(item.id);
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          decoration: item.isDelivered ? TextDecoration.lineThrough : null,
                          color: item.isDelivered
                              ? (dark ? DhikrColors.darkMuted : Colors.grey)
                              : (dark ? Colors.white : DhikrColors.charcoal),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: BeneficiaryTypeHelper.color(item.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        BeneficiaryTypeHelper.badgeAr(item.type),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: BeneficiaryTypeHelper.color(item.type),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BeneficiaryTypeHelper.color(item.type).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.amountOrShare,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: BeneficiaryTypeHelper.color(item.type),
                    ),
                  ),
                ),
                if (item.phone != null && item.phone!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.phone, size: 12, color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                      const SizedBox(width: 5),
                      Text(
                        item.phone!,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.fileText, size: 12, color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarClock,
                      size: 13,
                      color: item.dueDate != null
                          ? DhikrColors.forest
                          : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.dueDate != null
                          ? 'الميعاد المحدد: ${_formatBeneficiaryDate(item.dueDate!)}'
                          : 'أضيف في: ${_formatBeneficiaryDate(item.createdAt)}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11,
                        fontWeight: item.dueDate != null ? FontWeight.w700 : FontWeight.normal,
                        color: item.dueDate != null
                            ? (dark ? DhikrColors.sand : DhikrColors.forest)
                            : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 22),
            onSelected: (val) async {
              if (val == 'edit') {
                _showAddBeneficiarySheet(toEdit: item, defaultType: item.type, isUdhiyahOnly: isUdhiyah);
              } else if (val == 'delete') {
                await _service.deleteBeneficiary(item.id);
                setState(() {});
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل', style: TextStyle(fontFamily: DhikrTheme.arabicFont))),
              const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent))),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, bool dark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: dark ? DhikrColors.sand : DhikrColors.forest,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required bool dark,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true, signed: false),
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: dark ? Colors.white : DhikrColors.charcoal,
      ),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 12,
          color: dark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFB0B8C1),
        ),
        labelStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: dark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
        ),
        suffixText: suffix.isEmpty ? null : suffix,
        suffixStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: dark ? DhikrColors.sage : DhikrColors.forest,
        ),
        prefixIcon: Icon(icon, size: 18, color: DhikrColors.forest),
        filled: true,
        fillColor: dark ? DhikrColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DhikrColors.forest, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${_currency.symbol}';
  }

  void _showPracticalGuideSheet(BuildContext context, bool dark, int tabIndex) {
    HapticFeedback.lightImpact();

    final (title, subtitle, items) = switch (tabIndex) {
      1 => (
        'دليل النصاب الشرعي',
        'شرح مفصل لحساب النصاب وشروط وجوب الزكاة',
        [
          (
            title: 'نصاب الذهب',
            desc: '85 جراماً من الذهب الخالص عيار 24، يُعادل قيمته بالجنيه المصري حسب سعر السوق الحالي.',
            icon: LucideIcons.coins,
          ),
          (
            title: 'نصاب الفضة',
            desc: '595 جراماً من الفضة الخالصة، وهو أدنى من النصاب الذهبي وأكثر تيسيراً على المزكي.',
            icon: LucideIcons.circleDot,
          ),
          (
            title: 'شروط وجوب الزكاة',
            desc: 'بلوغ النصاب + حولان الحول (354 يوماً) + الملك التام + الفضل عن الحاجة + السلامة من الدين.',
            icon: LucideIcons.badgeAlert,
          ),
          (
            title: 'الفرق بين النصاب والزكاة',
            desc: 'النصاب هو الحد الأدنى للمال الذي تجب فيه الزكاة، أما الزكاة فهي 2.5% من المال بعد بلوغ النصاب وحولان الحول.',
            icon: LucideIcons.scale,
          ),
        ],
      ),
      2 => (
        'دليل مصارف الزكاة الشرعية',
        'الأصناف الثمانية المستحقة للزكاة المذكورة في القرآن الكريم',
        [
          (
            title: 'الفقراء والمساكين (الأولى بالرعاية)',
            desc: 'من لا يجدون كفايتهم الأساسية من طعام ومسكن ودواء، وهم المقصد الأساسي للزكاة لإغنائهم وسد حاجتهم.',
            icon: LucideIcons.heartHandshake,
          ),
          (
            title: 'الغارمون (أصحاب الديون)',
            desc: 'الذين تراكمت عليهم ديون مباحة في علاج أو زواج أو تجارة حلال وعجزوا عن أدائها.',
            icon: LucideIcons.badgeAlert,
          ),
          (
            title: 'في سبيل الله وابن السبيل',
            desc: 'مصالح المسلمين والدفاع عن الدين، والمسافر المحتاج المنقطع عن أهله وماله.',
            icon: LucideIcons.compass,
          ),
          (
            title: 'من لا تجوز الزكاة لهم',
            desc: 'لا يجوز إعطاء الزكاة للأصول (الأب والأم والجد) ولا للفروع (الأبناء والبنات) ولا للزوجة؛ لأن نفقتهم واجبة شرعاً على المنفق.',
            icon: LucideIcons.shieldAlert,
          ),
        ],
      ),
      3 => (
        'دليل توزيع الأضحية وصدقة اللحم',
        'السنن النبوية والضوابط في اقتسام وتوزيع اللحوم',
        [
          (
            title: 'التقسيم الثلاثي المستحب',
            desc: 'يستحب تقسيم الأضحية ثلاثة أثلاث: ثلث لأهل البيت وأولادهم، ثلث هدية للأرحام والجيران، وثلث صدقة للفقراء والمحتاجين.',
            icon: LucideIcons.pieChart,
          ),
          (
            title: 'وقت الذبح الشرعي للأضحية',
            desc: 'يبدأ الذبح بعد انتهاء صلاة عيد الأضحى مباشرة، ويستمر حتى مغيب شمس اليوم الرابع (آخر أيام التشريق).',
            icon: LucideIcons.calendarDays,
          ),
          (
            title: 'شروط سلامة الأضحية',
            desc: 'يُشترط سلامتها من العيوب الواضحة: ليست عوراء بيّن عورها، ولا عرجاء، ولا مريضة، وأن تكون بلغت السن الشرعية.',
            icon: LucideIcons.checkCircle2,
          ),
          (
            title: 'أجرة الجزار',
            desc: 'لا يجوز إعطاء الجزار شيئاً من لحم الأضحية أو جلدها كأجر على ذبحه، بل يُعطى أجرته كاملة من مال خاص، ويجوز إهداؤه كفقير لا كأجر.',
            icon: LucideIcons.info,
          ),
        ],
      ),
      _ => (
        'الدليل العملي لحاسبة الزكاة',
        'خطوات حساب وعاء الزكاة وإخراج ربع العشر (2.5%)',
        [
          (
            title: 'شروط وجوب زكاة المال',
            desc: '1) بلوغ المال النصاب الشرعي. 2) مرور حول هجري كامل (354 يوماً) على بقائه بالغاً النصاب. 3) الملك التام وفضله عن الحاجات الضرورية.',
            icon: LucideIcons.calendarCheck,
          ),
          (
            title: 'حساب الوعاء الزكوي',
            desc: 'تجمع: السيولة النقدية + الودائع البنكية الحرة + الذهب والفضة المدخرين بسعر اليوم + عروض التجارة بسعر البيع الحالي + الديون المرجوة لك.',
            icon: LucideIcons.plusCircle,
          ),
          (
            title: 'ما يُخصم من الأموال',
            desc: 'تُخصم الديون العاجلة الحالة عليك فقط التي يحين سدادها خلال العام الهجري الحالي، ولا تُخصم الديون المؤجلة طويلة الأجل إلا قسط العام.',
            icon: LucideIcons.minusCircle,
          ),
          (
            title: 'المعادلة ونسبة الإخراج',
            desc: 'إذا كان الصافي يساوي النصاب أو يزيد: مقدار الزكاة = صافي الوعاء الزكوي × 2.5% (أو قسمة الناتج على 40).',
            icon: LucideIcons.calculator,
          ),
        ],
      ),
    };

    final isUdhiyahGuide = tabIndex == 3;
    final sadaqahMeatItems = [
      (
        title: 'فضل إطعام الطعام ولحم الصدقة',
        desc: 'إطعام الطعام وتوزيع اللحوم على المحتاجين من أعظم القربات وأجل الصدقات التي تطهر المال وتدفع البلاء في سائر أيام العام.',
        icon: LucideIcons.heartHandshake,
      ),
      (
        title: 'جواز توزيع اللحم كله أو بعضه',
        desc: 'في صدقة اللحم العادية (غير الأضحية)، يجوز التصدق بكامل الذبيحة واللحم للفقراء أو إعطاؤه لجمعية موثوقة دون اشتراط التثليث.',
        icon: LucideIcons.badgePercent,
      ),
      (
        title: 'عدم التقيد بوقت أو أيام معينة',
        desc: 'تُخرج صدقة اللحم في أي وقت من أوقات السنة ليلاً أو نهاراً، وتتضاعف أجورها في الأوقات الفاضلة كرمضان وعشر ذي الحجة.',
        icon: LucideIcons.calendarClock,
      ),
      (
        title: 'الطيب من اللحم وحفظه',
        desc: 'يستحب أن يكون اللحم من أطيب ما يحبه الإنسان وأن يُحفظ بطريقة صحية كريمة تليق بحاجة المستحق: {لَن تَنَالُواْ ٱلْبِرَّ حَتَّىٰ تُنفِقُواْ مِمَّا تُحِبُّونَ}.',
        icon: LucideIcons.shieldCheck,
      ),
      (
        title: 'أولوية الأقارب والجيران',
        desc: 'إذا كان للمتصدق أقارب محتاجون أو جيران متعففون فهم أولى بالصدقة، وتكون صدقة وصلة رحم وتكافل مبارك.',
        icon: LucideIcons.users,
      ),
    ];

    Widget buildItemList(List<({String desc, IconData icon, String title})> list) {
      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final it = list[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF14241E) : const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DhikrColors.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(it.icon, size: 18, color: dark ? DhikrColors.sage : DhikrColors.forest),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.title,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        it.desc,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12,
                          height: 1.5,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isAr = context.watch<AppState>().language == AppLanguage.arabic;
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        final sheetContent = Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset > 0 ? bottomInset + 12 : 24),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DhikrColors.forest.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bookOpenCheck, color: DhikrColors.forest, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            color: dark ? Colors.white : DhikrColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isUdhiyahGuide) ...[
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: DhikrColors.forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                    labelStyle: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'أضحية العيد 🐑'),
                      Tab(text: 'صدقة اللحم 🥩'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildItemList(items),
                      buildItemList(sadaqahMeatItems),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Expanded(child: buildItemList(items)),
              ],
              const SizedBox(height: 14),
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DhikrColors.forest,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: DhikrColors.forest.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'فهمت ذلك، جزاكم الله خيراً 🌿',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: isUdhiyahGuide
              ? DefaultTabController(length: 2, child: sheetContent)
              : sheetContent,
        );
      },
    );
  }
}

class _GoldJewelryItem {
  final String name;
  final double weight;
  final String karat;
  final DateTime purchaseDate;
  final DateTime? lastZakatPaidAt;

  const _GoldJewelryItem({
    required this.name,
    required this.weight,
    required this.karat,
    required this.purchaseDate,
    this.lastZakatPaidAt,
  });

  /// Start of the current hawl: last payment restarts it, otherwise purchase.
  DateTime get hawlStart => lastZakatPaidAt ?? purchaseDate;

  double get purity {
    switch (karat) {
      case '24':
        return 1.0;
      case '21':
        return 0.875;
      case '18':
        return 0.75;
      default:
        return 0.875;
    }
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'weight': weight,
        'karat': karat,
        'purchaseDate': purchaseDate.toIso8601String(),
        'lastPaidAt': lastZakatPaidAt?.toIso8601String(),
      };

  static _GoldJewelryItem? fromMap(Map<String, dynamic> map) {
    try {
      final name = (map['name'] as String?)?.trim() ?? '';
      final weight = (map['weight'] as num?)?.toDouble() ?? 0;
      final purchaseDate = DateTime.tryParse(map['purchaseDate'] as String? ?? '');
      if (name.isEmpty || weight <= 0 || purchaseDate == null) return null;
      final lastPaidRaw = map['lastPaidAt'] as String?;
      return _GoldJewelryItem(
        name: name,
        weight: weight,
        karat: (map['karat'] as String?) ?? '21',
        purchaseDate: purchaseDate,
        lastZakatPaidAt: lastPaidRaw != null ? DateTime.tryParse(lastPaidRaw) : null,
      );
    } catch (_) {
      return null;
    }
  }
}
