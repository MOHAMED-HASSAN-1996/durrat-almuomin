import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/loved_one.dart';
import '../services/loved_ones_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'app_toast.dart';

/// حوار الإبلاغ عن بطاقة دعاء بظهر الغيب — مشترك بين القائمة وشاشة التفاصيل.
void showLovedOneReportDialog(
  BuildContext context,
  LovedOneItem item, {
  VoidCallback? onReported,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final isAr = Provider.of<AppState>(context, listen: false).language ==
      AppLanguage.arabic;
  String selectedReason = 'محتوى غير لائق أو مسيء';
  final reasons = [
    'محتوى غير لائق أو مسيء',
    'طلب تبرعات مالية أو أرقام هواتف',
    'إعلان أو روابط ترويجية',
    'انتهاك خصوصية أو صورة غير مناسبة',
    'أخرى',
  ];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: dark ? const Color(0xFF14241E) : Colors.white,
          title: const Row(
            children: [
              Icon(LucideIcons.flag, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'إبلاغ عن هذا المحتوى',
                style: TextStyle(
                  fontFamily: DhikrTheme.titleFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ساعدنا في الحفاظ على نقاء وقدسية مجتمع الدعاء، يرجى تحديد سبب الإبلاغ:',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (r) {
                  final isSel = selectedReason == r;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedReason = r),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFF10B981)
                              : (dark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSel ? const Color(0xFF10B981) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 13,
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w500,
                                color: isSel
                                    ? const Color(0xFF10B981)
                                    : (dark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await LovedOnesService.instance.reportLovedOne(
                  id: item.id,
                  reason: selectedReason,
                );
                if (context.mounted) {
                  AppToast.show(
                    context,
                    const SnackBar(
                      content: Text(
                          'تم استلام بلاغك وإخفاء المحتوى فوراً. جزاكم الله خيراً 🤲'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                onReported?.call();
              },
              child: const Text(
                'إرسال وإخفاء',
                style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
