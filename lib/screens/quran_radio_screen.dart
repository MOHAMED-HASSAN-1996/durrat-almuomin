import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/quran_radio.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

/// Full-screen Quran Radio player with station list, mode switcher (Quran Radio vs Reciters),
/// and previous/next navigation.
class QuranRadioScreen extends StatefulWidget {
  const QuranRadioScreen({super.key});

  @override
  State<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends State<QuranRadioScreen>
    with SingleTickerProviderStateMixin {
  late final QuranRadioService _radio = QuranRadioService.instance;
  late final AnimationController _waveCtrl;
  PlayerState _state = PlayerState.stopped;
  bool _connecting = false;
  String? _station = 'إذاعة القرآن الكريم من القاهرة';
  StreamSubscription<PlayerState>? _sub;
  bool _showList = false;
  String _searchQuery = '';
  bool _loadingStations = true;

  /// 0 = إذاعة القرآن الكريم, 1 = القراء
  int _radioMode = 0;

  /// Reciter category filter: 0 = الكل, 1 = قراء عرب, 2 = مترجم, 3 = برامج وأذكار
  int _reciterCategory = 0;

  /// Guards against multiple simultaneous play attempts
  bool _isToggling = false;
  bool _isChangingStation = false;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Ensure audio context is set — CRITICAL for mobile before first play
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _radio.ensureAudioContext();
      // Re-emit current state to sync UI
      final current = _radio.isPlaying
          ? PlayerState.playing
          : PlayerState.stopped;
      if (mounted) {
        setState(() {
          _state = current;
          if (_state == PlayerState.playing) {
            _waveCtrl.repeat();
          }
        });
      }
    });

    // If already playing in background, seamlessly restore player state & animation
    if (_radio.isPlaying) {
      _state = PlayerState.playing;
      _station = _radio.stationName ?? 'إذاعة القرآن الكريم من القاهرة';
      _radioMode =
          (_radio.stationCategory == 'live' ||
              (_station?.contains('القاهرة') ?? false))
          ? 0
          : 1;
      _waveCtrl.repeat();
    } else {
      _station = _radio.stationName ?? 'إذاعة القرآن الكريم من القاهرة';
    }

    _sub = _radio.stateStream.listen((s) {
      if (mounted) {
        setState(() {
          _state = s;
          if (s == PlayerState.playing) {
            _connecting = false;
            _isToggling = false;
            _station = _radio.stationName;
            _waveCtrl.repeat();
          } else {
            _waveCtrl.stop();
            if (s == PlayerState.stopped && _connecting) {
              _connecting = false;
              _isToggling = false;
            }
          }
        });
      }
    });
    _loadStations();
  }

  Future<void> _loadStations() async {
    final stations = await _radio.buildStationList();
    if (mounted) {
      setState(() {
        if (!_radio.isPlaying) {
          if (_radioMode == 0) {
            _station = _radio.cairoStation.name;
          } else {
            _station =
                _radio.stationName ??
                (_radio.reciterStations.isNotEmpty
                    ? _radio.reciterStations.first.name
                    : (stations.isNotEmpty
                          ? stations.first.name
                          : 'إذاعة القرآن الكريم من القاهرة'));
          }
        }
        _loadingStations = false;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Do NOT dispose _radio here so background playback continues uninterrupted
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _switchRadioMode(int mode) async {
    if (_radioMode == mode) return;
    HapticFeedback.selectionClick();
    final wasPlaying = _state == PlayerState.playing;

    setState(() {
      _radioMode = mode;
      _connecting = wasPlaying;
    });

    if (mode == 0) {
      // Cairo Quran Radio
      final cairo = _radio.cairoStation;
      _station = cairo.name;
      if (wasPlaying) {
        await _radio.playCairo();
      }
    } else {
      // Reciters mode: pick first reciter
      final reciters = _radio.reciterStations;
      final target = reciters.isNotEmpty ? reciters.first : _radio.cairoStation;
      _station = target.name;
      if (wasPlaying) {
        await _radio.play(
          url: target.url,
          name: target.name,
          category: 'reciter',
        );
      }
    }

    if (mounted) {
      setState(() {
        _connecting = false;
        _station =
            _radio.stationName ??
            (mode == 0
                ? _radio.cairoStation.name
                : (_radio.reciterStations.isNotEmpty
                      ? _radio.reciterStations.first.name
                      : _radio.cairoStation.name));
      });
    }
  }


  /// Instant-feedback toggle method: zero lag on stop, reliable connect on play
  Future<void> _toggle() async {
    // Snapshot the toggling flag and immediately set it to prevent double-taps
    if (_isToggling) return;
    _isToggling = true;
    HapticFeedback.mediumImpact();

    // ── STOP PATH ────────────────────────────────────────────────────────────
    if (_state == PlayerState.playing || _connecting) {
      // Instant UI feedback — feel immediate
      if (mounted) {
        setState(() {
          _state = PlayerState.stopped;
          _connecting = false;
          _waveCtrl.stop();
          _waveCtrl.reset();
        });
      }
      // Always reset the guard before returning
      try {
        await _radio.stop();
      } catch (e) {
        debugPrint('Stop error: $e');
      }
      _isToggling = false;
      return;
    }

    // ── PLAY PATH ────────────────────────────────────────────────────────────
    if (mounted) setState(() => _connecting = true);

    bool success = false;
    try {
      _radio.ensureAudioContext();

      if (_radioMode == 0) {
        // Find which live station matches current name
        final live = _radio.liveStations;
        final match = live.where((s) => _station == s.name).toList();
        if (match.isNotEmpty) {
          success = await _radio.play(
            url: match.first.url,
            name: match.first.name,
            category: 'live',
          );
        } else {
          success = await _radio.playCairo();
        }
      } else {
        success = await _radio.play(
          url: _radio.currentUrl,
          name: _station,
          category: 'reciter',
        );
      }
    } catch (e) {
      debugPrint('Toggle play error: $e');
      success = false;
    }

    // Always reset guard + UI — even if an exception was thrown
    _isToggling = false;
    if (mounted) {
      setState(() {
        _connecting = false;
        _station = _radio.stationName ?? _station;
      });
      if (!success) {
        AppToast.show(context, 
          SnackBar(
            content: const Text(
              'تعذر تشغيل الإذاعة — تأكد من اتصالك بالإنترنت',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'إعادة المحاولة', onPressed: _toggle),
          ),
        );
      }
    }
  }

  Future<void> _next() async {
    if (_isChangingStation) return;
    _isChangingStation = true;
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _connecting = true);
    try {
      if (_radioMode == 0) {
        await _radio.nextLive();
      } else {
        await _radio.nextReciter();
      }
    } on TimeoutException {
      debugPrint('Next: timed out');
    } catch (_) {
    } finally {
      _isChangingStation = false;
      if (mounted) {
        setState(() {
          _connecting = false;
          _station = _radio.stationName;
        });
      }
    }
  }

  Future<void> _previous() async {
    if (_isChangingStation) return;
    _isChangingStation = true;
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _connecting = true);
    try {
      if (_radioMode == 0) {
        await _radio.previousLive();
      } else {
        await _radio.previousReciter();
      }
    } on TimeoutException {
      debugPrint('Previous: timed out');
    } catch (_) {
    } finally {
      _isChangingStation = false;
      if (mounted) {
        setState(() {
          _connecting = false;
          _station = _radio.stationName;
        });
      }
    }
  }

  Future<void> _switchLiveSource() async {
    await _radio.nextLive();
  }

  Future<void> _playStation(
    String url,
    String name, {
    String category = 'radio',
  }) async {
    HapticFeedback.selectionClick();
    setState(() {
      _connecting = true;
    });
    try {
      // Ensure audio context is set before playing (critical for mobile)
      _radio.ensureAudioContext();

      final ok = await _radio.play(url: url, name: name, category: category);
      if (mounted && ok) {
        setState(() {
          _station = name;
          _showList = false;
        });
      } else if (mounted && !ok) {
        // Play failed — show error
        AppToast.show(context, 
          SnackBar(
            content: Text(
              'تعذر تشغيل هذه الإذاعة',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Play station error: $e');
      if (mounted) {
        AppToast.show(context, 
          SnackBar(
            content: Text(
              'تعذر تشغيل هذه الإذاعة',
              style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isPlaying = _state == PlayerState.playing;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppBar(
              title: Text(AppStrings.t(lang, 'quran_radio')),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: _showList
                      ? (isAr ? 'المشغل' : 'Player')
                      : (isAr ? 'قائمة الإذاعات' : 'Stations'),
                  icon: Icon(
                    _showList
                        ? Icons.radio_rounded
                        : Icons.format_list_bulleted_rounded,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showList = !_showList);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // 1. التاب بار في أعلى الصفحة مباشرة
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF14201B)
                          : const Color(0xFFF0F6F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(
                          0xFF1E5243,
                        ).withValues(alpha: dark ? 0.35 : 0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSwitcherTab(
                            title: isAr
                                ? 'إذاعة القرآن الكريم'
                                : 'Cairo Quran Radio',
                            icon: Icons.radio_rounded,
                            selected: _radioMode == 0,
                            onTap: () => _switchRadioMode(0),
                            dark: dark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSwitcherTab(
                            title: isAr ? 'إذاعات القراء' : 'Reciters',
                            icon: Icons.record_voice_over_rounded,
                            selected: _radioMode == 1,
                            onTap: () => _switchRadioMode(1),
                            dark: dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. محتوى الصفحة: إما قائمة المحطات أو كارت المشغل الفاخر الجديد
                Expanded(
                  child: _showList
                      ? _buildStationList(context, lang, isAr, dark)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRedesignedPlayerCard(
                                context,
                                isAr,
                                dark,
                                isPlaying,
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  isAr
                                      ? 'البث المباشر شغال بجودة متوسطة عشان يحافظ على باقتك\n— حوالي 50 ميجا في الساعة'
                                      : 'Live stream at medium quality to save your data\n— around 50 MB per hour',
                                  textAlign: TextAlign.center,
                                  textDirection: isAr
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    height: 1.6,
                                    color: dark
                                        ? Colors.white38
                                        : DhikrColors.charcoalSoft.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// كارت المشغل المعاد تصميمه بالكامل — تصميم إسلامي فاخر Awwwards / Apple Music
  Widget _buildRedesignedPlayerCard(
    BuildContext context,
    bool isAr,
    bool dark,
    bool isPlaying,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF15231C), Color(0xFF0D1713)]
              : const [Colors.white, Color(0xFFF4F9F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1E5243).withValues(alpha: dark ? 0.35 : 0.16),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0xFF1E5243).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط علوي صغير داخل الكارت: نوع المحطة + زر القائمة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFC5A059,
                  ).withValues(alpha: dark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.surround_sound_rounded,
                      size: 14,
                      color: Color(0xFFC5A059),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _radioMode == 0
                          ? 'بث إذاعي حي • مباشر'
                          : 'تلاوة عطرة مباركة',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC5A059),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isAr ? 'قائمة القراء والمحطات' : 'Stations List',
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showList = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // مجسم مرئي فخم ومتناسق بأبعاد أنيقة وغير مبالغ فيها
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // هالة الأمواج الخارجية المتوهجة عند التشغيل
                if (isPlaying)
                  AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + (_waveCtrl.value * 0.12);
                      final opacity = (1.0 - _waveCtrl.value) * 0.35;
                      return Container(
                        width: 96 * scale,
                        height: 96 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF1E5243,
                            ).withValues(alpha: opacity),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),

                // القرص المركزي الفخم
                RotationTransition(
                  turns: isPlaying
                      ? _waveCtrl
                      : const AlwaysStoppedAnimation(0),
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: dark
                            ? const [Color(0xFF233B2F), Color(0xFF0F1A14)]
                            : const [Color(0xFFE2EFE7), Color(0xFFC6DFD3)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1E5243,
                          ).withValues(alpha: isPlaying ? 0.3 : 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E5243), Color(0xFF143B30)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1E5243,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          _radioMode == 0
                              ? Icons.radio_rounded
                              : Icons.record_voice_over_rounded,
                          size: 18,
                          color: const Color(0xFFC5A059),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // عنوان المحطة / القارئ
          Text(
            _station ??
                (_radioMode == 0
                    ? 'إذاعة القرآن الكريم من القاهرة'
                    : 'إذاعة القرآن الكريم'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 1.35,
              color: dark ? Colors.white : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),

          // وصف المحطة الفرعي
          Text(
            _radioMode == 0
                ? ((_station?.contains('مكة') ?? false) ||
                          (_station?.contains('المدينة') ?? false) ||
                          (_station?.contains('السعودية') ?? false)
                      ? (isAr
                            ? 'المملكة العربية السعودية — بث حي متواصل'
                            : 'Saudi Arabia — 24/7 Live Stream')
                      : (isAr
                            ? 'جمهورية مصر العربية — بث متواصل على مدار 24 ساعة'
                            : 'Egypt — 24/7 Live Stream'))
                : (isAr
                      ? 'تلاوات خاشعة بأعذب الأصوات'
                      : 'Reverent Recitations'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 12,
              color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 12),

          // أشرطة متذبذبة حية (Equalizer Visualizer)
          SizedBox(
            height: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(18, (i) {
                return AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (context, _) {
                    final phase = (i * 0.22) + (_waveCtrl.value * math.pi * 2);
                    final height = isPlaying
                        ? 6.0 + (math.sin(phase).abs() * 18.0)
                        : (i % 2 == 0 ? 5.0 : 8.0);
                    return Container(
                      width: 3.5,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? (i % 3 == 0
                                  ? const Color(0xFFC5A059)
                                  : const Color(0xFF1E5243))
                            : (dark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 22),

          // أزرار التحكم الرئيسية: Shuffle | Previous | Big Play/Pause | Next | Stations List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _radioMode == 0
                      ? Icons.swap_horiz_rounded
                      : Icons.shuffle_rounded,
                ),
                color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
                iconSize: 22,
                tooltip: _radioMode == 0
                    ? (isAr
                          ? 'التبديل بين المحطات الحية'
                          : 'Cycle live stations')
                    : (isAr ? 'محطة عشوائية' : 'Shuffle'),
                onPressed: _connecting
                    ? null
                    : () => _radioMode == 0 ? _switchLiveSource() : _next(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                color: dark ? Colors.white : DhikrColors.charcoal,
                iconSize: 34,
                tooltip: isAr ? 'المحطة التالية' : 'Next',
                onPressed: _isChangingStation ? null : _next,
              ),

              // زر التشغيل/الإيقاف المركزي الفخم
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Allow tapping even while connecting to cancel
                onTap: _isToggling ? null : _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isToggling
                          ? [const Color(0xFF2A4A3E), const Color(0xFF1A3028)]
                          : [const Color(0xFF1E5243), const Color(0xFF143B30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF1E5243,
                        ).withValues(alpha: isPlaying ? 0.45 : 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _connecting
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            color: Color(0xFFC5A059),
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                color: dark ? Colors.white : DhikrColors.charcoal,
                iconSize: 34,
                tooltip: isAr ? 'المحطة السابقة' : 'Previous',
                onPressed: _isChangingStation ? null : _previous,
              ),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
                iconSize: 22,
                tooltip: isAr ? 'عرض القائمة' : 'Queue',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showList = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ملاحظة: سرعة بدء البث
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: dark ? Colors.white38 : DhikrColors.charcoalSoft,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isAr
                      ? 'يبدأ البث بعد ~5 ثوانٍ من الضغط على التشغيل'
                      : 'Streaming starts after ~5 seconds',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11.5,
                    color: dark ? Colors.white38 : DhikrColors.charcoalSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // فاصل رقيق
          Divider(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
          const SizedBox(height: 16),

          // بث مباشر تحت خالص في كارت البلاي حسب طلب المستخدم بالضبط
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isPlaying
                  ? const Color(
                      0xFFE53935,
                    ).withValues(alpha: dark ? 0.15 : 0.08)
                  : (dark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPlaying
                    ? const Color(0xFFE53935).withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isPlaying ? const Color(0xFFE53935) : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 1.5,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isPlaying
                      ? (isAr
                            ? 'بث مباشر الآن • LIVE STREAM (128 kbps)'
                            : 'LIVE STREAM (128 kbps)')
                      : (isAr
                            ? 'البث متوقف مؤقتاً • اضغط تشغيل'
                            : 'Broadcast Paused • Tap Play'),
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isPlaying
                        ? const Color(0xFFE53935)
                        : (dark ? Colors.white54 : DhikrColors.charcoalSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E5243) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E5243).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : (dark ? Colors.white70 : DhikrColors.charcoalSoft),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: selected
                      ? (dark ? DhikrColors.darkBg : Colors.white)
                      : (dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _spotifyQuickPills = [
    {
      'name': 'إذاعة القاهرة',
      'url': 'https://stream.radiojar.com/8s5u5tpdtwzuv',
      'cat': 'live',
    },
    {
      'name': 'الحصري',
      'url': 'https://backup.qurango.net/radio/mahmoud_khalil_alhussary',
      'cat': 'reciter',
    },
    {
      'name': 'عبد الباسط',
      'url': 'https://backup.qurango.net/radio/abdelbasit_abdelsamad_mojawwad',
      'cat': 'reciter',
    },
    {
      'name': 'المنشاوي',
      'url': 'https://backup.qurango.net/radio/mohammed_siddiq_alminshawi',
      'cat': 'reciter',
    },
    {
      'name': 'مصطفى إسماعيل',
      'url': 'https://backup.qurango.net/radio/mustafa_ismail',
      'cat': 'reciter',
    },
    {
      'name': 'الطبلاوي',
      'url': 'https://backup.qurango.net/radio/mohammad_al_tablaway',
      'cat': 'reciter',
    },
    {
      'name': 'محمود البنا',
      'url': 'https://backup.qurango.net/radio/mahmoud_ali__albanna',
      'cat': 'reciter',
    },
    {
      'name': 'ماهر المعيقلي',
      'url': 'https://backup.qurango.net/radio/maher',
      'cat': 'reciter',
    },
    {
      'name': 'مشاري العفاسي',
      'url': 'https://backup.qurango.net/radio/mishary_alafasi',
      'cat': 'reciter',
    },
    {
      'name': 'سعد الغامدي',
      'url': 'https://Qurango.net/radio/saad_alghamdi',
      'cat': 'reciter',
    },
    {
      'name': 'سعود الشريم',
      'url': 'https://backup.qurango.net/radio/saud_alshuraim',
      'cat': 'reciter',
    },
    {
      'name': 'أحمد العجمي',
      'url': 'https://Qurango.net/radio/ahmad_alajmy',
      'cat': 'reciter',
    },
  ];

  // ignore: unused_element
  Widget _buildQuickReciterPills(bool isAr, bool dark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _spotifyQuickPills.map((pill) {
          final isSelected =
              _station != null &&
              (_station!.contains(pill['name']!) ||
                  pill['name']!.contains(_station!));
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => _playStation(
                pill['url']!,
                pill['name']!,
                category: pill['cat']!,
              ),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1DB954)
                      : (dark
                            ? const Color(0xFF18241C)
                            : const Color(0xFFE8F5EE)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1DB954)
                        : (dark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected && _state == PlayerState.playing) ...[
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      pill['name']!,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (dark ? Colors.white70 : DhikrColors.charcoal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isArabicReciter(String name) {
    final knownReciters = [
      'الحصري',
      'المنشاوي',
      'عبد الباسط',
      'العجمي',
      'الغامدي',
      'الشريم',
      'العفاسي',
      'الزين',
      'البنا',
      'الطبلاوي',
      'مصطفى إسماعيل',
      'عبدالرحمن',
      'سعد',
      'ماهر',
      'مشاري',
      'محمود',
      'أحمد',
      'محمد',
      'عبدالباسط',
      'حسين',
      'جودت',
      'خيري',
      'شحات',
      'أبوبكر',
      'عمر',
      'إبراهيم',
      'شعrawي',
    ];
    return knownReciters.any((r) => name.contains(r));
  }

  bool _isTranslator(String name) {
    final keywords = ['ترجم', 'translat', 'tarjuman', 'sahih', ' explains'];
    return keywords.any((k) => name.toLowerCase().contains(k));
  }

  bool _isProgram(String name) {
    final keywords = [
      'أذكار',
      'adkar',
      'إذكار',
      'دروس',
      'فتاوى',
      'تفسير',
      'تخش',
      'تلاوة',
      'تجويد',
      'حفظ',
      'سيرة',
      'سنن',
      'أحاديث',
      ' الحديث',
      'فقه',
      '%',
      'درر',
      'برنامج',
      'program',
    ];
    return keywords.any((k) => name.toLowerCase().contains(k));
  }

  Widget _buildStationList(
    BuildContext context,
    AppLanguage lang,
    bool isAr,
    bool dark,
  ) {
    // Always show all live stations in mode 0 (Cairo, Makkah, etc.)
    final sourceList = _radioMode == 0
        ? _radio.liveStations
        : _radio.reciterStations;

    // Filter by search query
    var filtered = sourceList.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply reciter category filter in mode 1
    if (_radioMode == 1 && _reciterCategory > 0) {
      filtered = filtered.where((s) {
        final name = s.name.toLowerCase();
        switch (_reciterCategory) {
          case 1: // قراء عرب (reciters with known Arabic names)
            return _isArabicReciter(name);
          case 2: // مترجم
            return _isTranslator(name);
          case 3: // برامج وأذكار
            return _isProgram(name);
          default:
            return true;
        }
      }).toList();
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: _radioMode == 0
                  ? (isAr ? 'ابحث في الإذاعات...' : 'Search radio...')
                  : (isAr ? 'ابحث عن قارئ...' : 'Search reciter...'),
              hintStyle: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 14,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
              filled: true,
              fillColor: dark ? DhikrColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : DhikrColors.charcoal.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : DhikrColors.charcoal.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ),

        // Reciter category chips (only in reciter mode)
        if (_radioMode == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(isAr ? 'الكل' : 'All', 0, dark),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    isAr ? 'قراء عرب' : 'Arab Reciters',
                    1,
                    dark,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(isAr ? 'مترجم' : 'Translator', 2, dark),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    isAr ? 'برامج وأذكار' : 'Programs & Adhkar',
                    3,
                    dark,
                  ),
                ],
              ),
            ),
          ),

        // Count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _radioMode == 0
                    ? (isAr ? 'إذاعة القرآن الكريم' : 'Live Radio')
                    : (isAr
                          ? 'قائمة القراء (${filtered.length})'
                          : 'Reciters (${filtered.length})'),
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? DhikrColors.darkMuted
                      : DhikrColors.charcoalSoft,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showList = false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(isAr ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        ),

        // Station list
        Expanded(
          child: _loadingStations
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لم يتم العثور على نتائج' : 'No stations found',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final station = filtered[index];
                    final isActive =
                        _station == station.name &&
                        _state == PlayerState.playing;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isActive
                          ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                .withValues(alpha: 0.12)
                          : (dark ? DhikrColors.darkSurface : Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isActive
                              ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                    .withValues(alpha: 0.35)
                              : (dark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : DhikrColors.charcoal.withValues(
                                        alpha: 0.06,
                                      )),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                (dark ? DhikrColors.sage : DhikrColors.forest)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _radioMode == 0
                                ? Icons.radio_rounded
                                : Icons.record_voice_over_rounded,
                            size: 22,
                            color: dark ? DhikrColors.sage : DhikrColors.forest,
                          ),
                        ),
                        title: Text(
                          station.name,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isActive
                                ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                : (dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal),
                          ),
                        ),
                        subtitle: Text(
                          _radioMode == 0
                              ? (isAr ? 'بث إذاعي مباشر' : 'Live stream')
                              : (isAr ? 'إذاعة قرآنية مخصصة' : 'Quran station'),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                        ),
                        trailing: isActive
                            ? Icon(
                                Icons.equalizer_rounded,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                              )
                            : Icon(
                                Icons.play_arrow_rounded,
                                color: dark
                                    ? DhikrColors.darkMuted
                                    : DhikrColors.charcoalSoft,
                              ),
                        onTap: () => _playStation(station.url, station.name),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, int index, bool dark) {
    final isSelected = _reciterCategory == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _reciterCategory = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E5243)
              : (dark ? const Color(0xFF18241C) : const Color(0xFFE8F5EE)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E5243)
                : (dark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (dark ? Colors.white70 : DhikrColors.charcoal),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _WavePainter extends CustomPainter {
  _WavePainter({required this.anim, required this.color});
  final double anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final midY = size.height / 2;
    for (int i = 0; i < 3; i++) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 1) {
        final y =
            midY +
            (10 + i * 3) *
                math.sin((x / 22) + anim * 6.28318530718 + i * 1.2) *
                (0.9 - i * 0.15);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        paint..color = color.withValues(alpha: 0.38 - i * 0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.anim != anim;
}
