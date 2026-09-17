import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/zakat_model.dart';
import '../services/zakat_service.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    _calc = _service.calcState;

    _goldPriceCtrl.text = _calc.goldPricePerGram > 0 ? _calc.goldPricePerGram.toStringAsFixed(0) : '3500';
    _silverPriceCtrl.text = _calc.silverPricePerGram > 0 ? _calc.silverPricePerGram.toStringAsFixed(0) : '45';
    if (_calc.cashAmount > 0) _cashCtrl.text = _calc.cashAmount.toStringAsFixed(0);
    if (_calc.goldWeightGrams24k > 0) _gold24kCtrl.text = _calc.goldWeightGrams24k.toStringAsFixed(1);
    if (_calc.goldWeightGrams21k > 0) _gold21kCtrl.text = _calc.goldWeightGrams21k.toStringAsFixed(1);
    if (_calc.silverWeightGrams > 0) _silverCtrl.text = _calc.silverWeightGrams.toStringAsFixed(0);
    if (_calc.tradeInventoryValue > 0) _tradeCtrl.text = _calc.tradeInventoryValue.toStringAsFixed(0);
    if (_calc.stocksAndInvestments > 0) _stocksCtrl.text = _calc.stocksAndInvestments.toStringAsFixed(0);
    if (_calc.debtsOwedToYou > 0) _debtsToYouCtrl.text = _calc.debtsOwedToYou.toStringAsFixed(0);
    if (_calc.debtsYouOwe > 0) _debtsOwedCtrl.text = _calc.debtsYouOwe.toStringAsFixed(0);

    if (mounted) setState(() => _loading = false);
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
    BeneficiaryType defaultType = BeneficiaryType.zakat,
    bool isUdhiyahOnly = false,
  }) {
    final nameCtrl = TextEditingController(text: toEdit?.name ?? '');
    final amountCtrl = TextEditingController(text: toEdit?.amountOrShare ?? '');
    final phoneCtrl = TextEditingController(text: toEdit?.phone ?? '');
    final notesCtrl = TextEditingController(text: toEdit?.notes ?? '');
    var selectedType = toEdit?.type ?? defaultType;

    DateTime? selectedDueDate = toEdit?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
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

                      // Type selector chips (if not udhiyah only)
                      if (!isUdhiyahOnly) ...[
                        Wrap(
                          spacing: 8,
                          children: [
                            BeneficiaryType.zakat,
                            BeneficiaryType.sadaqah,
                          ].map((BeneficiaryType t) {
                            final selected = selectedType == t;
                            return ChoiceChip(
                              label: Text(t.badgeAr),
                              selected: selected,
                              selectedColor: t.color.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                                color: selected ? t.color : (dark ? Colors.white70 : Colors.black87),
                              ),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedType = t);
                              },
                            );
                          }).toList(),
                        ),
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
                      const SizedBox(height: 10),

                      // Amount or Share
                      TextField(
                        controller: amountCtrl,
                        style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: isUdhiyahOnly
                              ? 'النصيب (مثال: خروف كامل، سهم عجل، 5 كجم)'
                              : 'المبلغ المخصص (مثال: 2,500 ج.م)',
                          labelStyle: const TextStyle(fontFamily: DhikrTheme.bodyFont),
                          filled: true,
                          fillColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

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
                      const SizedBox(height: 10),

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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                          const SizedBox(width: 8),

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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                      const SizedBox(height: 10),

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
                      const SizedBox(height: 22),

                      // Save button (واضح ومميز)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            HapticFeedback.selectionClick();

                            final b = ZakatBeneficiary(
                              id: toEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: name,
                              type: isUdhiyahOnly ? BeneficiaryType.udhiyah : selectedType,
                              amountOrShare: amountCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              isDelivered: toEdit?.isDelivered ?? false,
                              dueDate: selectedDueDate,
                              createdAt: toEdit?.createdAt,
                            );

                            if (toEdit != null) {
                              await _service.updateBeneficiary(b);
                            } else {
                              await _service.addBeneficiary(b);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {});
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
        return 'حاسبة النصاب الشرعي ⚖️';
      case 2:
        return 'مستحقو الزكاة والصدقات 🤲';
      case 3:
        return 'مستحقو الأضاحي 🐑';
      case 0:
      default:
        return 'حاسبة الزكاة 🪙';
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

    return Directionality(
      textDirection: TextDirection.rtl,
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
              tooltip: 'دليل الحاسبة والتطبيق العملي 📖',
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
          suffix: 'ج.م',
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
        const SizedBox(height: 20),

        // Section: Trade Goods & Investments
        _buildSectionTitle('3. عروض التجارة والاستثمارات', dark),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _tradeCtrl,
          label: 'قيمة بضائع التجارة المعدة للبيع (بسعر البيع الحالي)',
          suffix: 'ج.م',
          icon: LucideIcons.store,
          dark: dark,
          onChanged: (_) => _onValuesChanged(),
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _stocksCtrl,
          label: 'الأسهم والصناديق الاستثمارية',
          suffix: 'ج.م',
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
                suffix: 'ج.م',
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
                suffix: 'ج.م',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('تم حفظ ومزامنة حسابات الزكاة بنجاح 💾', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w700)),
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
              'حفظ الحسابات في السجل 💾',
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
    final reachesGold = totalWealth >= goldNisab && goldNisab > 0;
    final reachesSilver = totalWealth >= silverNisab && silverNisab > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
      children: [
        // Nisab Status Hero Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: reachesGold
                  ? (dark ? [const Color(0xFF1B2A22), const Color(0xFF101C16)] : [const Color(0xFFEAF5EE), const Color(0xFFD8ECDF)])
                  : (dark ? [const Color(0xFF261D10), const Color(0xFF161108)] : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: reachesGold ? DhikrColors.forest.withValues(alpha: 0.4) : const Color(0xFFD97706).withValues(alpha: 0.4),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (reachesGold ? DhikrColors.forest : const Color(0xFFD97706)).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reachesGold
                          ? DhikrColors.forest.withValues(alpha: 0.2)
                          : const Color(0xFFD97706).withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      reachesGold ? LucideIcons.checkCircle : LucideIcons.scale,
                      color: reachesGold ? DhikrColors.forest : const Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reachesGold ? 'أموالك بلغت نصاب الذهب الشرعي ⚖️' : 'أموالك لم تبلغ نصاب الذهب بعد',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: reachesGold ? DhikrColors.forest : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reachesGold
                              ? 'تجب الزكاة بنسبة 2.5% إذا حال عليها الحول (عام هجري)'
                              : 'لا تجب الزكاة حتى يبلغ المال النصاب ويحول عليه الحول',
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
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'نصاب الذهب (85 جم)',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(goldNisab),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: reachesGold ? DhikrColors.forest : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.25)),
                  Column(
                    children: [
                      const Text(
                        'نصاب الفضة (595 جم)',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(silverNisab),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: reachesSilver ? DhikrColors.forest : const Color(0xFFB45309),
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

        // Price Configuration Section
        _buildSectionTitle('أسعار جرام الذهب والفضة اليوم', dark),
        const SizedBox(height: 6),
        Text(
          'يمكنك تعديل الأسعار وفق أسعار السوق المحلي الحالية لتحديث النصاب تلقائياً:',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 12,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _goldPriceCtrl,
                label: 'سعر جرام ذهب 24',
                suffix: 'ج.م',
                icon: LucideIcons.coins,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                controller: _silverPriceCtrl,
                label: 'سعر جرام الفضة',
                suffix: 'ج.م',
                icon: LucideIcons.circleDot,
                dark: dark,
                onChanged: (_) => _onValuesChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Fiqh Rules of Nisab Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? DhikrColors.forestLight.withValues(alpha: 0.2) : DhikrColors.sageSoft.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.bookOpen, color: DhikrColors.forest, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'شروط وجوب الزكاة الشرعية',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildFiqhRuleItem('1. بلوغ النصاب:', 'أن يبلغ المال المدخر قيمة 85 جراماً من الذهب الخالص عيار 24.', dark),
              _buildFiqhRuleItem('2. حولان الحول:', 'أن يمر على امتلاك النصاب عام هجري كامل (354 يوماً) دون أن ينقص عنه.', dark),
              _buildFiqhRuleItem('3. الملك التام والنماء:', 'أن يكون المال مملوكاً للمزكي ملكاً كاملاً، قابلاً للنماء والاستثمار.', dark),
              _buildFiqhRuleItem('4. الفضل عن الحاجة الأصلية:', 'أن يكون المال زائداً عن ضروريات الحياة من مسكن ومأكل ودواء.', dark),
              _buildFiqhRuleItem('5. السلامة من الدين:', 'أن تُخصم الديون العاجلة الحالة عليك قبل حساب الوعاء الزكوي.', dark),
            ],
          ),
        ),
      ],
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
    final list = allList.where((e) => e.type != BeneficiaryType.udhiyah).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final deliveredCount = list.where((e) => e.isDelivered).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBeneficiarySheet(defaultType: BeneficiaryType.zakat, isUdhiyahOnly: false),
        backgroundColor: DhikrColors.forest,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.userPlus, size: 18),
        label: const Text('إضافة مستحق زكاة', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
      ),
      body: list.isEmpty
          ? _buildEmptyState(
              icon: LucideIcons.handCoins,
              title: 'سجل مستحقي الزكاة والصدقات فارغ',
              subtitle: 'أضف الأسر والأفراد المستحقين لزكاة المال أو الصدقات لمتابعة المبالغ وتسليمها',
              dark: dark,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 90),
              children: [
                _buildStatsBar(
                  totalLabel: 'إجمالي المستحقين: ${list.length}',
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4: مستحقو الأضاحي (UDHIYAH BENEFICIARIES)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUdhiyahBeneficiariesTab(bool dark) {
    final allList = _service.beneficiaries;
    final list = allList.where((e) => e.type == BeneficiaryType.udhiyah).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final deliveredCount = list.where((e) => e.isDelivered).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBeneficiarySheet(defaultType: BeneficiaryType.udhiyah, isUdhiyahOnly: true),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.heartHandshake, size: 18),
        label: const Text('إضافة مستحق أضحية', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
      ),
      body: list.isEmpty
          ? _buildEmptyState(
              icon: LucideIcons.heartHandshake,
              title: 'سجل توزيع الأضاحي فارغ',
              subtitle: 'أضف العائلات والمستحقين لحصص ولحوم الأضاحي لتنظيم عملية الذبح والتوزيع بدقة',
              dark: dark,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 90),
              children: [
                _buildStatsBar(
                  totalLabel: 'إجمالي أنصبة الأضاحي: ${list.length}',
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
              : item.type.color.withValues(alpha: 0.25),
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
                        color: item.type.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.type.badgeAr,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: item.type.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.type.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.amountOrShare,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: item.type.color,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: DhikrTheme.arabicFont,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: dark ? Colors.white : DhikrColors.charcoal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: dark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
        ),
        suffixText: suffix,
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
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ج.م';
  }

  void _showPracticalGuideSheet(BuildContext context, bool dark, int tabIndex) {
    HapticFeedback.lightImpact();

    final (title, subtitle, items) = switch (tabIndex) {
      1 => (
        'دليل زكاة الفطر المباركة 🌾',
        'الأحكام والضوابط الشرعية لإخراج زكاة الفطر',
        [
          (
            title: 'حكمها وعلى من تجب',
            desc: 'واجبة على كل مسلم حر ومسلمة، يملك قوت يومه وليلته ويفيض عن حاجته وحاجة من تلزمه نفقتهم يوم العيد وليلته.',
            icon: LucideIcons.badgeAlert,
          ),
          (
            title: 'وقت إخراجها المستحب',
            desc: 'تُخرج قبل صلاة العيد وهو الأفضل والمستحب، ويجوز إخراجها قبل العيد بيوم أو يومين، ولا يجوز تأخيرها عن صلاة العيد بغير عذر.',
            icon: LucideIcons.clock,
          ),
          (
            title: 'الصاع الشرعي ومقداره',
            desc: 'صاع نبوي من غالب قوت البلد (قمح، أرز، تمر، زبيب..)، ويقدّر وزنه بقرابة 2.5 إلى 3 كجم تقريباً بحسب نوع الحبوب.',
            icon: LucideIcons.scale,
          ),
          (
            title: 'إخراج القيمة نقداً',
            desc: 'أجاز مذهب الإمام أبي حنيفة وجماعة من السلف إخراج قيمتها نقداً لمصلحة الفقير وسد حاجاته المتنوعة يوم العيد.',
            icon: LucideIcons.coins,
          ),
        ],
      ),
      2 => (
        'دليل مصارف الزكاة الشرعية 🤝',
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
        'دليل توزيع الأضحية وصدقة اللحم 🐑',
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
        'الدليل العملي لحاسبة الزكاة 🪙',
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
          textDirection: TextDirection.rtl,
          child: isUdhiyahGuide
              ? DefaultTabController(length: 2, child: sheetContent)
              : sheetContent,
        );
      },
    );
  }
}
