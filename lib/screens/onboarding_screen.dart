import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Full-bleed immersive Onboarding Screen with luxurious religious artwork backgrounds,
/// smooth linear gradient overlay, and high-contrast elegant typography.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final ValueChanged<AppLanguage> onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  AppLanguage _selectedLang = AppLanguage.arabic;

  final List<Map<String, String>> _slides = [
    {
      'titleAr': 'المصحف الشريف وتدبر الآيات',
      'titleEn': 'The Holy Quran & Reflection',
      'descAr': 'قراءة المصحف العثماني برسم المدينة المنورة، بتنسيق ١٥ سطراً لكل صفحة مع مظاهر مريحة للعين.',
      'descEn': 'Read the Medina Mushaf with standard 15 lines per page and soothing reading themes.',
      'image': 'assets/images/onboarding_quran.jpg',
    },
    {
      'titleAr': 'مواقيت الصلاة وإذاعة القرآن',
      'titleEn': 'Prayer Times & Quran Radio',
      'descAr': 'مواقيت صلاة دقيقة بحسب موقعك وبث مباشر لإذاعة القرآن الكريم من القاهرة وكبار القراء على مدار الساعة.',
      'descEn': 'Accurate prayer times according to your location, with 24/7 Cairo Quran Radio and legendary reciters.',
      'image': 'assets/images/onboarding_athan.jpg',
    },
    {
      'titleAr': 'أذكار صحيحة وطمأنينة القلب',
      'titleEn': 'Authentic Adhkar & Serenity',
      'descAr': 'أذكار الصباح والمساء والرقية الشرعية وجوامع الكلم مراجعة ومحققة من أصح كتب السنة النبوية الشريفة.',
      'descEn': 'Verified morning and evening adhkar, Ruqyah, and supplications from authenticated Sunnah sources.',
      'image': 'assets/images/onboarding_adhkar.jpg',
    },
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinished(_selectedLang);
    }
  }

  void _goToPrevious() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onFinished(_selectedLang);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _selectedLang == AppLanguage.arabic;
    final isLast = _currentPage == _slides.length - 1;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF040B08),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ─────────────────────────────────────────────────────────
            // 1. FULL-BLEED SLIDES WITH LUXURIOUS RELIGIOUS BACKGROUNDS
            // ─────────────────────────────────────────────────────────
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: _slides.length,
              itemBuilder: (context, idx) {
                final slide = _slides[idx];
                final title = isAr ? slide['titleAr']! : slide['titleEn']!;
                final desc = isAr ? slide['descAr']! : slide['descEn']!;
                final imgPath = slide['image']!;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // A. Background Artwork Image (Full Bleed)
                    Image.asset(
                      imgPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF0D241C),
                      ),
                    ),

                    // B. Rich Linear Gradient Overlay (Transparent top -> Deep dark bottom)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.20),
                              Colors.black.withValues(alpha: 0.65),
                              const Color(0xFF040B08).withValues(alpha: 0.95),
                              const Color(0xFF040B08),
                            ],
                            stops: const [0.0, 0.32, 0.60, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // C. Slide Text Overlay (Placed cleanly over linear gradient)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Spiritual Emblem Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF153B2E).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF4E9E80).withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isAr ? '«سَكِينَةٌ وَطُمَأْنِينَة»' : 'Serenity & Faith',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFA5E6C7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Main Title
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.25,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                desc,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.82),
                                  height: 1.6,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Reserved spacing for indicators & bottom buttons
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ─────────────────────────────────────────────────────────
            // 2. TOP BAR OVERLAY (Brand Logo + Title + Lang + Skip)
            // ─────────────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Brand with clean logo
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAr ? 'دُرَّةُ الْمُؤْمِن' : "Durrat Al-Mu'min",
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: isAr ? 24 : 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: isAr ? 0 : 0.5,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 10),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Actions: Language Toggle & Skip
                      Row(
                        children: [
                          // Language Toggle
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedLang = isAr
                                    ? AppLanguage.english
                                    : AppLanguage.arabic;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isAr ? 'EN' : 'عربي',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFA5E6C7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Skip Button
                          TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(alpha: 0.9),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isAr ? 'تخطي' : 'Skip',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────────────────────────
            // 3. BOTTOM CONTROLS (Dots Indicator + Action Button)
            // ─────────────────────────────────────────────────────────
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Smooth Dots Indicator
                    _buildPageIndicator(),
                    const SizedBox(height: 20),

                    // Action Button (Next / Start)
                    _buildBottomActions(isAr, isLast),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFA5E6C7)
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF4E9E80).withValues(alpha: 0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildBottomActions(bool isAr, bool isLast) {
    return Row(
      children: [
        if (_currentPage > 0) ...[
          IconButton(
            onPressed: _goToPrevious,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            icon: Icon(
              isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],

        Expanded(
          child: GestureDetector(
            onTap: _goToNext,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2E7D63),
                    Color(0xFF1E5B48),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA5E6C7).withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E5B48).withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast
                          ? (isAr ? 'ابدأ الآن' : 'Get Started')
                          : (isAr ? 'متابعة' : 'Continue'),
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLast
                          ? Icons.check_rounded
                          : (isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded),
                      color: Colors.white,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
