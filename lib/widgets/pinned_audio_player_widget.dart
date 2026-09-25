import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../screens/quran_radio_screen.dart';
import '../services/quran_radio.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Luxury Pinned Waveform Audio Player Widget — matching modern Live Notification
/// and dynamic media widget design language (as requested by the user).
class PinnedAudioPlayerWidget extends StatefulWidget {
  const PinnedAudioPlayerWidget({super.key});

  @override
  State<PinnedAudioPlayerWidget> createState() =>
      _PinnedAudioPlayerWidgetState();
}

class _PinnedAudioPlayerWidgetState extends State<PinnedAudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  final QuranRadioService _radio = QuranRadioService.instance;
  late final AnimationController _waveAnim;
  StreamSubscription<PlayerState>? _stateSub;
  bool _isPlaying = false;
  bool _buffering = false;
  String _stationName = 'إذاعة القرآن الكريم من القاهرة';
  final double _sliderProgress = 0.42;

  @override
  void initState() {
    super.initState();
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _isPlaying = _radio.isPlaying;
    _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم من القاهرة';

    if (_isPlaying) {
      _waveAnim.repeat();
    }

    _stateSub = _radio.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم من القاهرة';
        _buffering = false;
      });

      if (_isPlaying) {
        if (!_waveAnim.isAnimating) _waveAnim.repeat();
      } else {
        _waveAnim.stop();
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _waveAnim.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    HapticFeedback.lightImpact();
    setState(() => _buffering = true);

    if (_isPlaying) {
      await _radio.pause();
    } else {
      await _radio.play();
    }

    if (mounted) {
      setState(() {
        _buffering = false;
        _isPlaying = _radio.isPlaying;
        _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم من القاهرة';
      });
    }
  }

  Future<void> _onNext() async {
    HapticFeedback.selectionClick();
    setState(() => _buffering = true);
    await _radio.nextStation();
    if (mounted) {
      setState(() {
        _buffering = false;
        _isPlaying = _radio.isPlaying;
        _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم';
      });
    }
  }

  Future<void> _onPrevious() async {
    HapticFeedback.selectionClick();
    setState(() => _buffering = true);
    await _radio.previousStation();
    if (mounted) {
      setState(() {
        _buffering = false;
        _isPlaying = _radio.isPlaying;
        _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم';
      });
    }
  }

  void _openStationPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final isAr = context.read<AppState>().language == AppLanguage.arabic;
    final stations = _radio.stations;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFF0F201B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'محطات وقراء درة المؤمن' : "Durrat Al-Mu'min Radios",
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowUpRight, color: DhikrColors.sand),
                      tooltip: isAr ? 'فتح المشغل الكامل' : 'Open Full Player',
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const QuranRadioScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: stations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = stations[index];
                    final isCurrent = _radio.currentUrl == s.url ||
                        (_radio.currentUrl == null && index == 0);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          setState(() => _buffering = true);
                          await _radio.play(
                            url: s.url,
                            name: s.name,
                            category: s.category,
                          );
                          if (mounted) {
                            setState(() {
                              _buffering = false;
                              _isPlaying = true;
                              _stationName = s.name;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? DhikrColors.sand.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? DhikrColors.sand.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrent
                                      ? DhikrColors.sand
                                      : Colors.white10,
                                ),
                                child: Icon(
                                  isCurrent && _isPlaying
                                      ? LucideIcons.volume2
                                      : LucideIcons.radio,
                                  size: 18,
                                  color: isCurrent
                                      ? const Color(0xFF0D1D18)
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 14.5,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isCurrent
                                            ? DhikrColors.sand
                                            : Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.category == 'live'
                                          ? (isAr ? 'بث حي مباشر' : 'Live Stream')
                                          : (isAr ? 'تلاوات مسجلة' : 'Recitation'),
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 11.5,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent && _isPlaying)
                                const Icon(
                                  LucideIcons.activity,
                                  color: DhikrColors.sand,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061410).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: DhikrColors.sand.withValues(alpha: _isPlaying ? 0.12 : 0.04),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF132A23),
                Color(0xFF0B1915),
                Color(0xFF08120F),
              ],
            ),
            border: Border.all(
              color: _isPlaying
                  ? DhikrColors.sand.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Subtle background artistic ambiance
              Positioned(
                left: -30,
                top: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1E5243).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DhikrColors.sand.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP BAR: Music Tag + Live badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DhikrColors.sand.withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                LucideIcons.music,
                                size: 13,
                                color: DhikrColors.sand,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr
                                  ? 'تلاوة وبث مباشر — درة المؤمن'
                                  : "Durrat Al-Mu'min Live Audio",
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),

                        // Live indicator badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isPlaying
                                ? const Color(0xFF10B981).withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: _isPlaying
                                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isPlaying
                                      ? const Color(0xFF10B981)
                                      : Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isPlaying
                                    ? (isAr ? 'مباشر الآن' : 'LIVE')
                                    : (isAr ? 'جاهز للتشغيل' : 'READY'),
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isPlaying
                                      ? const Color(0xFF34D399)
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // TRACK TITLE & RECITERS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stationName,
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isAr
                                    ? 'بث صوتي عالي النقاء • تلاوات خاشعة على مدار الساعة'
                                    : 'Ultra HD Audio • Continuous Peaceful Recitation',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Station Selector Quick Button
                        InkWell(
                          onTap: () => _openStationPicker(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.listMusic,
                              size: 19,
                              color: DhikrColors.sand,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ANIMATED DYNAMIC WAVEFORM (Exact reference design)
                    AnimatedBuilder(
                      animation: _waveAnim,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(double.infinity, 28),
                          painter: _WaveformPainter(
                            progress: _isPlaying ? _waveAnim.value : 0.0,
                            isPlaying: _isPlaying,
                            sliderProgress: _sliderProgress,
                            primaryColor: const Color(0xFFF0BD85),
                            secondaryColor: Colors.white24,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 6),

                    // DURATION TIMESTAMPS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isPlaying ? '02:17' : '00:00',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isPlaying
                              ? (isAr ? 'بث مستمر 🔴' : 'LIVE 🔴')
                              : '02:35',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: _isPlaying
                                ? const Color(0xFFF0BD85)
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // CONTROLS ROW: Mode, Prev, Play/Pause, Next, Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mode switch / Shuffle
                        IconButton(
                          icon: const Icon(LucideIcons.shuffle),
                          iconSize: 20,
                          color: Colors.white70,
                          tooltip: isAr ? 'تبديل القارئ' : 'Shuffle Reciter',
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            setState(() => _buffering = true);
                            await _radio.nextReciter();
                            if (mounted) {
                              setState(() {
                                _buffering = false;
                                _isPlaying = true;
                                _stationName = _radio.stationName ?? 'إذاعة القرآن الكريم';
                              });
                            }
                          },
                        ),

                        // Previous button
                        IconButton(
                          icon: Icon(
                            isAr
                                ? LucideIcons.skipForward
                                : LucideIcons.skipBack,
                          ),
                          iconSize: 24,
                          color: Colors.white,
                          tooltip: isAr ? 'المحطة السابقة' : 'Previous Station',
                          onPressed: _onPrevious,
                        ),

                        // Glow Play / Pause Main Button
                        GestureDetector(
                          onTap: _togglePlay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isPlaying
                                    ? [
                                        const Color(0xFFF3C793),
                                        const Color(0xFFD49E5D),
                                      ]
                                    : [
                                        const Color(0xFF1E5243),
                                        const Color(0xFF0F2B23),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isPlaying
                                          ? const Color(0xFFF3C793)
                                          : const Color(0xFF1E5243))
                                      .withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: _buffering
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? LucideIcons.pause
                                          : LucideIcons.play,
                                      size: 26,
                                      color: _isPlaying
                                          ? const Color(0xFF0F1E19)
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),

                        // Next button
                        IconButton(
                          icon: Icon(
                            isAr
                                ? LucideIcons.skipBack
                                : LucideIcons.skipForward,
                          ),
                          iconSize: 24,
                          color: Colors.white,
                          tooltip: isAr ? 'المحطة التالية' : 'Next Station',
                          onPressed: _onNext,
                        ),

                        // Full player launcher
                        IconButton(
                          icon: const Icon(LucideIcons.maximize2),
                          iconSize: 19,
                          color: Colors.white70,
                          tooltip: isAr ? 'تكبير المشغل' : 'Full Screen Player',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const QuranRadioScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Waveform Painter that draws an organic audio wave matching the reference design
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.sliderProgress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final bool isPlaying;
  final double sliderProgress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    const barCount = 42;
    final spacing = size.width / barCount;
    final barWidth = spacing * 0.55;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final normX = i / barCount;
      final x = i * spacing + (spacing - barWidth) / 2;

      // Calculate dynamic wave amplitude
      double waveHeight;
      if (isPlaying) {
        final phase = progress * 2 * math.pi;
        final s1 = math.sin(normX * 4 * math.pi + phase);
        final s2 = math.cos(normX * 6 * math.pi - phase * 0.7);
        final normalized = ((s1 + s2) / 2).abs();
        waveHeight = math.max(4.0, normalized * (size.height * 0.9));
      } else {
        // Resting natural audio contour
        final s = math.sin(normX * math.pi);
        waveHeight = math.max(3.0, s * (size.height * 0.6));
      }

      final top = centerY - waveHeight / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, waveHeight),
        Radius.circular(barWidth / 2),
      );

      if (normX <= sliderProgress) {
        canvas.drawRRect(rect, activePaint);
      } else {
        canvas.drawRRect(rect, inactivePaint);
      }
    }

    // Glowing seeker thumb
    final thumbX = sliderProgress * size.width;
    final thumbPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(thumbX, centerY), 6.5, glowPaint);
    canvas.drawCircle(Offset(thumbX, centerY), 4.5, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.sliderProgress != sliderProgress;
  }
}
