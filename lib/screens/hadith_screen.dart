import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/hadith_data.dart';
import '../theme/app_theme.dart';

/// شاشة الأحاديث النبوية الصحيحة والموثقة
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  List<String> get _categories {
    final set = <String>{'الكل'};
    for (final h in authenticHadiths) {
      set.add(h.category);
    }
    return set.toList();
  }

  Map<String, int> get _categoryCounts {
    final map = <String, int>{'الكل': authenticHadiths.length};
    for (final h in authenticHadiths) {
      map[h.category] = (map[h.category] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final filtered = authenticHadiths.where((h) {
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
      textDirection: TextDirection.rtl,
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
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                          elevation: isSelected ? 3 : 0,
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
          // رأس الكارت: العنوان والفئة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: dark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 16),
                tooltip: 'نسخ الحديث',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${item.arabic}\n${item.source}'));
                  ScaffoldMessenger.of(context).showSnackBar(
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

          // عنوان الحديث
          Text(
            item.title,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: dark ? const Color(0xFFA5E6C7) : const Color(0xFF16382E),
            ),
          ),
          const SizedBox(height: 8),

          // نص الحديث
          Text(
            item.arabic,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.8,
              color: dark ? Colors.white.withValues(alpha: 0.95) : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),

          // الراوي والمصدر
          Text(
            item.narrator,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 4),
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
