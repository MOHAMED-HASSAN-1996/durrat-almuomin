import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/hadith_data.dart';
import '../services/arabic_text_utils.dart';
import '../services/remote_content_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

/// شاشة الأحاديث النبوية الصحيحة والموثقة
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  /// Local library merged with admin-managed remote hadith by id: remote
  /// edits override the same local entry, brand-new remote entries lead.
  List<HadithItem> get _allHadith {
    final remote = RemoteContentService.instance.remoteHadith;
    final remoteIds = remote.map((h) => h.id).toSet();
    return [
      ...remote,
      ...authenticHadiths.where((h) => !remoteIds.contains(h.id)),
    ];
  }

  @override
  void initState() {
    super.initState();
    RemoteContentService.instance.initialize();
    RemoteContentService.instance.addListener(_onRemoteContent);
  }

  @override
  void dispose() {
    RemoteContentService.instance.removeListener(_onRemoteContent);
    super.dispose();
  }

  void _onRemoteContent() {
    if (mounted) setState(() {});
  }

  List<String> get _categories {
    final map = <String, int>{};
    for (final h in _allHadith) {
      map[h.category] = (map[h.category] ?? 0) + 1;
    }
    final cats = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ['الكل', ...cats.map((e) => e.key)];
  }

  Map<String, int> get _categoryCounts {
    final map = <String, int>{'الكل': _allHadith.length};
    for (final h in _allHadith) {
      map[h.category] = (map[h.category] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    final filtered = _allHadith.where((h) {
      if (_selectedCategory != 'الكل' && h.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return h.title.toLowerCase().contains(q) ||
          h.arabic.toLowerCase().contains(q) ||
          h.source.toLowerCase().contains(q) ||
          h.category.toLowerCase().contains(q);
    }).toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: AppBar(
                title: const Text(
                  'أحاديث نبوية صحيحة',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  // شريط البحث
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark ? DhikrColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (dark ? DhikrColors.sage : DhikrColors.forest)
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث في متن الحديث أو الموضوع...',
                          hintStyle: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            color: dark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // تصنيفات الأحاديث (Chips مع عداد)
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        final count = _categoryCounts[cat] ?? 0;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : (dark
                                          ? DhikrColors.sage.withValues(alpha: 0.18)
                                          : DhikrColors.forest.withValues(alpha: 0.08)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (dark ? DhikrColors.sage : DhikrColors.forest),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: DhikrColors.forest,
                          backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
                          elevation: 0,
                          pressElevation: 0,
                          side: BorderSide(
                            color: isSelected
                                ? DhikrColors.forest
                                : (dark ? DhikrColors.sageSoft.withValues(alpha: 0.2) : const Color(0xFFE5E7EB)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 4),

                  // قائمة الأحاديث
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📜', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد أحاديث مطابقة للبحث أو التصنيف',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 14,
                                    color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final item = filtered[idx];
                              return _buildHadithCard(item, dark);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHadithCard(HadithItem item, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الكارت: الفئة + نسخ
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 16),
                tooltip: 'نسخ الحديث',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${item.arabic}\n${item.source}'));
                  AppToast.show(context, 
                    const SnackBar(
                      content: Text('تم نسخ الحديث الشريف بنجاح'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // نص الحديث
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.03)
                  : DhikrColors.forest.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (dark ? DhikrColors.sage : DhikrColors.forest)
                    .withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Text(
              ArabicTextUtils.stripTashkeel(item.arabic),
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.9,
                color: dark
                    ? Colors.white.withValues(alpha: 0.95)
                    : DhikrColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // المصدر فقط
          Row(
            children: [
              const Icon(LucideIcons.bookCheck, size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.source,
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
