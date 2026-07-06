import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

// ─── RADIO CONTROLLER ────────────────────────────────────────────────────────

class RadioController {
  static final RadioController instance = RadioController._internal();
  final AudioPlayer _player = AudioPlayer()..setVolume(1.0);

  RadioController._internal() {
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
  }

  static const String _streamUrl = 'https://stream.radiojar.com/8s5u5tpdtwzuv';

  /// True only when the player is actually outputting audio.
  bool get isPlaying =>
      _player.playerState.playing &&
          _player.playerState.processingState != ProcessingState.idle &&
          _player.playerState.processingState != ProcessingState.completed;

  /// Stream the UI can listen to for state changes.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<bool> play() async {
    try {
      // Already playing — don't reload the stream.
      if (isPlaying) return true;

      // If we're paused mid-stream try to resume first.
      if (_player.playerState.processingState == ProcessingState.ready &&
          !_player.playing) {
        await _player.play();
        return true;
      }

      // Fresh start (idle, completed, or first launch).
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(_streamUrl)));
      await _player.play();
      return true;
    } catch (e, st) {
      debugPrint('RadioController.play error: $e\n$st');
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      await _player.stop();
      return true;
    } catch (e, st) {
      debugPrint('RadioController.pause error: $e\n$st');
      return false;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

// ─── COLOUR TOKENS ───────────────────────────────────────────────────────────

class _C {
  const _C._();

  // Backgrounds
  static const Color bg         = Color(0xFF03060E);
  static const Color bgMid      = Color(0xFF060C18);
  static const Color surface    = Color(0xFF0A1220);
  static const Color surfaceAlt = Color(0xFF0D1828);
  static const Color glass      = Color(0xFF111E33);

  // Gold
  static const Color gold       = Color(0xFFD4A843);
  static const Color goldLight  = Color(0xFFEDD27A);
  static const Color goldBright = Color(0xFFFAE5A0);
  static const Color goldDim    = Color(0xFF8A6B28);
  static const Color goldGlow   = Color(0xFFB8892A);

  // Teal / Emerald
  static const Color teal       = Color(0xFF22D4BC);
  static const Color tealLight  = Color(0xFF50EBD6);
  static const Color tealDim    = Color(0xFF0B8A7A);
  static const Color tealDeep   = Color(0xFF044D45);
  static const Color tealGlow   = Color(0xFF0ECCA8);

  // Text
  static const Color onBg       = Color(0xFFF0E8D0);
  static const Color onBgDim    = Color(0xFFBAAD8A);
  static const Color onBgMuted  = Color(0xFF7A6F58);

  // UI
  static const Color muted      = Color(0xFF2E4455);
  static const Color mutedLight = Color(0xFF4A6070);
  static const Color border     = Color(0xFF1A2E45);
}

// ─── PAGE ────────────────────────────────────────────────────────────────────

class QuranRadioPage extends StatefulWidget {
  const QuranRadioPage({super.key});

  @override
  State<QuranRadioPage> createState() => _QuranRadioPageState();
}

class _QuranRadioPageState extends State<QuranRadioPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final _radio = RadioController.instance;
  bool _isLoading = false;
  bool _isPressed = false;
  bool _isPlaying = false; // driven by playerStateStream

  // ── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _rippleCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _tickerCtrl;
  late final AnimationController _geomRotCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _staggerCtrl;
  late final StreamSubscription<PlayerState> _playerSub;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _pulseSz;
  late final Animation<double> _shimmer;
  late final Animation<double> _pressScale;

  // Staggered entry animations
  late final Animation<double> _fadeOrb;
  late final Animation<double> _fadeTicker;
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeButton;
  late final Animation<double> _fadeBadge;
  late final Animation<double> _fadeInfo;

  late final Animation<Offset> _slideOrb;
  late final Animation<Offset> _slideTitle;
  late final Animation<Offset> _slideButton;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _staggerCtrl.forward();
    _geomRotCtrl.repeat();
    _shimmerCtrl.repeat();

    // React to player state changes so UI always reflects real playback state.
    _playerSub = _radio.playerStateStream.listen((state) {
      if (!mounted) return;
      final nowPlaying = state.playing &&
          state.processingState != ProcessingState.idle &&
          state.processingState != ProcessingState.completed;
      if (nowPlaying == _isPlaying) return;
      setState(() => _isPlaying = nowPlaying);
      if (nowPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    });
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseSz = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _geomRotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    );

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _shimmer = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    // Staggered entry
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Animation<double> _interval(double start, double end) =>
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

    _fadeOrb    = _interval(0.00, 0.45);
    _fadeTicker = _interval(0.20, 0.55);
    _fadeTitle  = _interval(0.30, 0.65);
    _fadeButton = _interval(0.45, 0.75);
    _fadeBadge  = _interval(0.55, 0.82);
    _fadeInfo   = _interval(0.65, 1.00);

    _slideOrb = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));
    _slideTitle = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));
    _slideButton = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _pulseCtrl.repeat(reverse: true);
    _rotateCtrl.repeat();
    _rippleCtrl.repeat();
    _tickerCtrl.repeat();
  }

  void _stopAnimations() {
    _pulseCtrl.animateBack(0.0,
        duration: const Duration(milliseconds: 700), curve: Curves.easeOut);
    _rotateCtrl.stop();
    _rippleCtrl..stop()..reset();
    _tickerCtrl..stop()..reset();
  }

  Future<void> _toggle() async {
    // Guard: only block if loading AND not yet playing (i.e. mid-connect).
    // If already playing, always allow pause even during loading.
    if (_isLoading && !_isPlaying) return;

    final shouldPause = _isPlaying;

    // Lock immediately so rapid double-taps can't fire two ops.
    setState(() => _isLoading = true);

    HapticFeedback.mediumImpact();
    _pressCtrl.forward().then((_) => _pressCtrl.reverse());

    if (shouldPause) {
      await _radio.pause();
    } else {
      await _radio.play();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerSub.cancel();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _rippleCtrl.dispose();
    _entryCtrl.dispose();
    _tickerCtrl.dispose();
    _geomRotCtrl.dispose();
    _shimmerCtrl.dispose();
    _pressCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_geomRotCtrl.isAnimating) _geomRotCtrl.repeat();
      if (!_shimmerCtrl.isAnimating) _shimmerCtrl.repeat();
      if (_isPlaying) _startAnimations();
    } else if (state == AppLifecycleState.paused) {
      _geomRotCtrl.stop();
      _shimmerCtrl.stop();
      _stopAnimations();
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.bg,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Animated background
            _BackgroundPainterWidget(rotateCtrl: _geomRotCtrl),

            // Shimmer overlay on background
            _ShimmerOverlay(shimmer: _shimmer),

            // Main content
            SafeArea(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _C.bg.withValues(alpha: 0.55),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF1A2E45), width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IslamicStar(size: 14, color: _C.gold.withValues(alpha: 0.6)),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_C.goldLight, _C.onBg],
                      ).createShader(bounds),
                      child: const Text(
                        'إذاعة القرآن الكريم',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _IslamicStar(size: 14, color: _C.gold.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Orb
            FadeTransition(
              opacity: _fadeOrb,
              child: SlideTransition(
                position: _slideOrb,
                child: _buildOrb(),
              ),
            ),
            const SizedBox(height: 10),
            // Ticker
            FadeTransition(
              opacity: _fadeTicker,
              child: _buildNowPlayingTicker(),
            ),
            const SizedBox(height: 24),
            // Title
            FadeTransition(
              opacity: _fadeTitle,
              child: SlideTransition(
                position: _slideTitle,
                child: _buildTitle(),
              ),
            ),
            const SizedBox(height: 28),
            // Play Button
            FadeTransition(
              opacity: _fadeButton,
              child: SlideTransition(
                position: _slideButton,
                child: _buildPlayButton(),
              ),
            ),
            const SizedBox(height: 24),
            // Status Badge
            FadeTransition(
              opacity: _fadeBadge,
              child: _buildStatusBadge(),
            ),
            const SizedBox(height: 18),
            // Info Row
            FadeTransition(
              opacity: _fadeInfo,
              child: _buildInfoRow(),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _fadeInfo,
              child: _buildBottomOrnament(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── ORB ───────────────────────────────────────────────────────────────────

  Widget _buildOrb() {
    final playing = _isPlaying;
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost slow geom halo
          AnimatedBuilder(
            animation: _geomRotCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _geomRotCtrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(290, 290),
                painter: _IslamicGeomPainter(
                  opacity: playing ? 0.18 : 0.10,
                  primaryColor: _C.gold,
                  secondaryColor: _C.teal,
                ),
              ),
            ),
          ),

          // Counter-rotating inner geom
          AnimatedBuilder(
            animation: _geomRotCtrl,
            builder: (_, __) => Transform.rotate(
              angle: -_geomRotCtrl.value * 2 * math.pi * 0.6,
              child: CustomPaint(
                size: const Size(240, 240),
                painter: _IslamicGeomPainter(
                  opacity: playing ? 0.10 : 0.05,
                  primaryColor: _C.teal,
                  secondaryColor: _C.gold,
                ),
              ),
            ),
          ),

          // Ripple rings
          if (playing) ...[
            _Ripple(controller: _rippleCtrl, delay: 0.00, maxRadius: 136, color: _C.teal),
            _Ripple(controller: _rippleCtrl, delay: 0.33, maxRadius: 136, color: _C.tealLight),
            _Ripple(controller: _rippleCtrl, delay: 0.66, maxRadius: 136, color: _C.gold),
          ],

          // Decorative rings
          _DecoRing(radius: 200, color: _C.gold, opacity: 0.07, width: 1.0),
          _DecoRing(radius: 180, color: _C.teal, opacity: 0.06, width: 0.5),
          _DecoRing(radius: 160, color: _C.gold, opacity: 0.04, width: 0.5),

          // Rotating dashed arc ring
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * math.pi,
              child: const CustomPaint(
                size: Size(196, 196),
                painter: _ArcPainter(color: _C.gold, segments: 16, opacity: 0.22),
              ),
            ),
          ),

          // Counter-rotating arc
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, __) => Transform.rotate(
              angle: -_rotateCtrl.value * 2 * math.pi * 0.38,
              child: const CustomPaint(
                size: Size(216, 216),
                painter: _ArcPainter(color: _C.teal, segments: 8, opacity: 0.14),
              ),
            ),
          ),

          // Glow layer (behind orb)
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: playing ? 165 : 140,
            height: playing ? 165 : 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withValues(alpha: playing ? 0.55 : 0.08),
                  blurRadius: playing ? 70 : 25,
                  spreadRadius: playing ? 18 : 0,
                ),
                BoxShadow(
                  color: _C.gold.withValues(alpha: playing ? 0.22 : 0.05),
                  blurRadius: 100,
                  spreadRadius: playing ? 5 : 0,
                ),
              ],
            ),
          ),

          // Core orb
          ScaleTransition(
            scale: _pulseSz,
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    playing ? const Color(0xFF30FFE6) : const Color(0xFF1ACAB0),
                    _C.teal,
                    _C.tealDim,
                    _C.tealDeep,
                    const Color(0xFF011510),
                  ],
                  stops: const [0.0, 0.28, 0.58, 0.82, 1.0],
                ),
              ),
              child: Center(
                child: playing
                    ? const _WaveBars()
                    : const _IslamicStar(size: 54, color: Color(0xFF001510)),
              ),
            ),
          ),

          // Multi-layer rim
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.goldBright.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.gold.withValues(alpha: 0.10),
                width: 1.0,
              ),
            ),
          ),
          Container(
            width: 162,
            height: 162,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.teal.withValues(alpha: 0.07),
                width: 0.5,
              ),
            ),
          ),

          // Inner glass highlight
          Positioned(
            top: 72,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOW PLAYING TICKER ────────────────────────────────────────────────────

  Widget _buildNowPlayingTicker() {
    final playing = _isPlaying;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: 270,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: playing
            ? _C.teal.withValues(alpha: 0.09)
            : _C.muted.withValues(alpha: 0.05),
        border: Border.all(
          color: playing
              ? _C.teal.withValues(alpha: 0.20)
              : _C.border.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: playing
            ? _ScrollingTicker(controller: _tickerCtrl)
            : Center(
          child: Text(
            '•  القرآن الكريم  •',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _C.mutedLight.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── TITLE ─────────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    final playing = _isPlaying;
    return Column(
      children: [
        const _OrnamentalDivider(),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_C.goldBright, _C.goldLight, _C.onBg],
            stops: const [0.0, 0.45, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'إذاعة القرآن الكريم',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: playing
              ? Row(
            key: const ValueKey('live'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.tealLight,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'يتم بث القرآن الكريم الآن',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: _C.tealLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          )
              : Text(
            key: const ValueKey('idle'),
            'اضغط للاستماع إلى القرآن الكريم',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _C.onBgMuted.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ── PLAY BUTTON ───────────────────────────────────────────────────────────

  Widget _buildPlayButton() {
    final playing = _isPlaying;
    return GestureDetector(
      onTap: (_isLoading && !_isPlaying) ? null : _toggle,
      onTapDown: (_) {
        if (!_isLoading) _pressCtrl.forward();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) => Transform.scale(
          scale: _pressScale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          width: playing ? 96.0 : 84.0,
          height: playing ? 96.0 : 84.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: playing
                  ? [_C.tealLight, _C.teal, _C.tealDim]
                  : [_C.goldBright, _C.gold, _C.goldGlow, _C.goldDim],
              stops: playing
                  ? const [0.0, 0.5, 1.0]
                  : const [0.0, 0.35, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: (playing ? _C.teal : _C.gold).withValues(alpha: 0.50),
                blurRadius: playing ? 40 : 28,
                spreadRadius: playing ? 6 : 2,
              ),
              BoxShadow(
                color: (playing ? _C.tealGlow : _C.goldLight)
                    .withValues(alpha: 0.18),
                blurRadius: 80,
              ),
            ],
          ),
          child: Center(
            child: _isLoading && !_isPlaying
                ? const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFF001A14),
                strokeWidth: 2.5,
              ),
            )
                : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(_isPlaying),
                size: 52,
                color: const Color(0xFF001410),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── STATUS BADGE ──────────────────────────────────────────────────────────

  Widget _buildStatusBadge() {
    final live = _isPlaying;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: live
            ? _C.teal.withValues(alpha: 0.07)
            : _C.muted.withValues(alpha: 0.06),
        border: Border.all(
          color: live
              ? _C.teal.withValues(alpha: 0.25)
              : _C.muted.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LiveDot(isLive: live),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              live ? 'مباشر  •  LIVE' : 'غير متصل  •  OFFLINE',
              key: ValueKey(live),
              style: TextStyle(
                color: live ? _C.tealLight : _C.muted,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO ROW ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _InfoChip(icon: Icons.radio_rounded, label: 'بث مباشر'),
        SizedBox(width: 8),
        _InfoChip(icon: Icons.language_rounded, label: 'عربي'),
        SizedBox(width: 8),
        _InfoChip(icon: Icons.high_quality_rounded, label: 'جودة عالية'),
      ],
    );
  }

  Widget _buildBottomOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final isCenter = i == 3;
        final distFromCenter = (i - 3).abs();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: isCenter
              ? _IslamicStar(
            size: 13,
            color: _C.gold.withValues(alpha: 0.55),
          )
              : Container(
            width: distFromCenter == 1 ? 5 : 3.5,
            height: distFromCenter == 1 ? 5 : 3.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.gold.withValues(alpha: 0.15 + (3 - distFromCenter) * 0.07),
            ),
          ),
        );
      }),
    );
  }
}

// ─── SCROLLING TICKER ─────────────────────────────────────────────────────────

class _ScrollingTicker extends StatelessWidget {
  final AnimationController controller;

  const _ScrollingTicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Full text width is wider than the container — translate it across.
    const text = 'بسم الله الرحمن الرحيم  •  القرآن الكريم  •  إذاعة مباشرة  •  استمع وتدبر  •';
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        // Content row is ~450px wide; scroll it fully in then out.
        const contentW = 450.0;
        return AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            // t: 0 → start off right edge, 1 → end off left edge
            final dx = containerW + contentW - controller.value * (containerW + contentW * 2);
            return OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: Offset(dx - containerW, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded, size: 11,
                        color: _C.teal.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: _C.teal.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── SHIMMER OVERLAY ─────────────────────────────────────────────────────────

class _ShimmerOverlay extends StatelessWidget {
  final Animation<double> shimmer;

  const _ShimmerOverlay({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) => Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _ShimmerPainter(progress: shimmer.value),
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  const _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * ((progress + 2) / 4);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFFCFA84C).withValues(alpha: 0.015),
          const Color(0xFF26C6B0).withValues(alpha: 0.01),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(x - 80, 0, 160, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

// ─── ORNAMENTAL DIVIDER ───────────────────────────────────────────────────────

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _GoldLine(reversed: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _IslamicStar(size: 10, color: _C.gold.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              _IslamicStar(size: 18, color: _C.gold.withValues(alpha: 0.85)),
              const SizedBox(height: 4),
              _IslamicStar(size: 10, color: _C.gold.withValues(alpha: 0.4)),
            ],
          ),
        ),
        const _GoldLine(reversed: false),
      ],
    );
  }
}

class _GoldLine extends StatelessWidget {
  final bool reversed;
  const _GoldLine({required this.reversed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reversed
                ? [Colors.transparent, _C.gold.withValues(alpha: 0.55)]
                : [_C.gold.withValues(alpha: 0.55), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ─── ISLAMIC STAR ─────────────────────────────────────────────────────────────

class _IslamicStar extends StatelessWidget {
  final double size;
  final Color color;

  const _IslamicStar({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IslamicStarPainter(color: color),
    );
  }
}

class _IslamicStarPainter extends CustomPainter {
  final Color color;
  const _IslamicStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int points = 8;
    const double innerRatio = 0.40;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : r * innerRatio;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarPainter old) => old.color != color;
}

// ─── LIVE DOT ─────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final bool isLive;
  const _LiveDot({required this.isLive});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isLive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LiveDot old) {
    super.didUpdateWidget(old);
    if (widget.isLive && !old.isLive) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isLive && old.isLive) {
      _ctrl.stop();
      _ctrl.animateTo(0.3);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.muted),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.teal.withValues(alpha: _anim.value * 0.15),
            ),
          ),
          // Inner dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.tealLight.withValues(alpha: _anim.value),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withValues(alpha: _anim.value * 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DECO RING ────────────────────────────────────────────────────────────────

class _DecoRing extends StatelessWidget {
  final double radius;
  final Color color;
  final double opacity;
  final double width;

  const _DecoRing({
    required this.radius,
    required this.color,
    required this.opacity,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: width,
        ),
      ),
    );
  }
}

// ─── INFO CHIP ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: _C.surface,
        border: Border.all(
          color: _C.gold.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _C.gold.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _C.onBgDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RIPPLE ───────────────────────────────────────────────────────────────────

class _Ripple extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final double maxRadius;
  final Color color;

  const _Ripple({
    required this.controller,
    required this.delay,
    required this.maxRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + delay) % 1.0;
        // Ease-out expansion feels more natural
        final easedT = 1.0 - math.pow(1.0 - t, 2.5);
        final radius = maxRadius * easedT;
        final opacity = (1 - t) * 0.32;
        return SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── WAVE BARS ────────────────────────────────────────────────────────────────

class _WaveBars extends StatefulWidget {
  const _WaveBars();

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars> with TickerProviderStateMixin {
  static const int _count = 11;

  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 420 + i * 65),
      );
      _ctrls.add(ctrl);
      _anims.add(
        Tween<double>(begin: 5, end: 38).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
        ),
      );
      Future.delayed(Duration(milliseconds: i * 55), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_count, (i) {
        final center = (_count - 1) / 2;
        final distFromCenter = (i - center).abs();
        final edgeFactor = 1.0 - (distFromCenter / (_count / 2)) * 0.35;
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            width: 3.0,
            height: _anims[i].value * edgeFactor,
            margin: const EdgeInsets.symmetric(horizontal: 1.6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF001A17).withValues(alpha: 0.5),
                  const Color(0xFF001A17),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ─── ARC PAINTER ─────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  final int segments;
  final double opacity;

  const _ArcPainter({
    required this.color,
    required this.segments,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segments; i++) {
      final startAngle = (i / segments) * 2 * math.pi;
      final sweepAngle = (1 / segments) * 2 * math.pi * 0.45;
      final varOpacity = opacity * (0.6 + (i % 3) * 0.2);
      paint.color = color.withValues(alpha: varOpacity.clamp(0.0, 1.0));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── ISLAMIC GEOMETRY PAINTER ─────────────────────────────────────────────────

class _IslamicGeomPainter extends CustomPainter {
  final double opacity;
  final Color primaryColor;
  final Color secondaryColor;

  const _IslamicGeomPainter({
    required this.opacity,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 * 0.92;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const int n = 12;
    final pts = List.generate(n, (i) {
      final a = (i / n) * 2 * math.pi - math.pi / 2;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    });

    // Outer polygon
    paint.color = primaryColor.withValues(alpha: opacity);
    final poly = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < n; i++) poly.lineTo(pts[i].dx, pts[i].dy);
    poly.close();
    canvas.drawPath(poly, paint);

    // Every 5th point star pattern
    paint.color = primaryColor.withValues(alpha: opacity * 0.65);
    for (int i = 0; i < n; i++) {
      canvas.drawLine(pts[i], pts[(i + 5) % n], paint);
    }

    // Every 4th point pattern
    paint.color = secondaryColor.withValues(alpha: opacity * 0.45);
    for (int i = 0; i < n; i++) {
      canvas.drawLine(pts[i], pts[(i + 4) % n], paint);
    }

    // Every 3rd point inner pattern
    paint.color = primaryColor.withValues(alpha: opacity * 0.30);
    for (int i = 0; i < n; i++) {
      canvas.drawLine(pts[i], pts[(i + 3) % n], paint);
    }

    // Inner circles
    paint.color = primaryColor.withValues(alpha: opacity * 0.55);
    canvas.drawCircle(Offset(cx, cy), r * 0.22, paint);
    paint.color = secondaryColor.withValues(alpha: opacity * 0.25);
    canvas.drawCircle(Offset(cx, cy), r * 0.48, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicGeomPainter old) =>
      old.opacity != opacity ||
          old.primaryColor != primaryColor ||
          old.secondaryColor != secondaryColor;
}

// ─── BACKGROUND PAINTER ───────────────────────────────────────────────────────

class _BackgroundPainterWidget extends StatelessWidget {
  final AnimationController rotateCtrl;
  const _BackgroundPainterWidget({required this.rotateCtrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: rotateCtrl,
        builder: (_, __) => CustomPaint(
          painter: _BgPainter(geomAngle: rotateCtrl.value * 2 * math.pi),
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double geomAngle;
  const _BgPainter({required this.geomAngle});

  static final List<({double x, double y, double r, double o})> _stars =
  List.generate(120, (i) {
    final rng = math.Random(i * 41 + 7);
    return (
    x: rng.nextDouble(),
    y: rng.nextDouble(),
    r: rng.nextDouble() * 1.2 + 0.15,
    o: rng.nextDouble() * 0.40 + 0.04,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Rich deep background
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF070E1C),
            Color(0xFF03060E),
            Color(0xFF020408),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Gold nebula top-right
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.80, -0.65),
          radius: 0.75,
          colors: [
            const Color(0xFFD4A843).withValues(alpha: 0.07),
            const Color(0xFFD4A843).withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect),
    );

    // Teal nebula bottom-left
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.70, 0.85),
          radius: 0.65,
          colors: [
            const Color(0xFF22D4BC).withValues(alpha: 0.06),
            const Color(0xFF22D4BC).withValues(alpha: 0.015),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(rect),
    );

    // Subtle center glow
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.55,
          colors: [
            const Color(0xFF0B1A30).withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Stars — two layers: faint background and brighter foreground
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final twinkle = (math.sin(geomAngle * 0.5 + s.x * 8.0) * 0.15 + 0.85)
          .clamp(0.0, 1.0);
      starPaint.color = Colors.white.withValues(alpha: s.o * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        starPaint,
      );
    }

    // Corner Islamic geometry motifs
    final geomPaint = Paint()
      ..color = _C.gold.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    void drawGeomAt(Offset center, double r) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(geomAngle * 0.08);

      const int n = 8;
      final pts = List.generate(n, (i) {
        final a = (i / n) * 2 * math.pi;
        return Offset(r * math.cos(a), r * math.sin(a));
      });

      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < n; i++) path.lineTo(pts[i].dx, pts[i].dy);
      path.close();

      for (int i = 0; i < n; i++) {
        canvas.drawLine(pts[i], pts[(i + 3) % n], geomPaint);
      }
      canvas.drawPath(path, geomPaint);
      canvas.drawCircle(Offset.zero, r * 0.5, geomPaint);
      canvas.drawCircle(Offset.zero, r * 0.85, geomPaint);
      canvas.restore();
    }

    drawGeomAt(Offset(size.width * 0.05, size.height * 0.07), 60);
    drawGeomAt(Offset(size.width * 0.94, size.height * 0.10), 48);
    drawGeomAt(Offset(size.width * 0.07, size.height * 0.92), 52);
    drawGeomAt(Offset(size.width * 0.93, size.height * 0.88), 44);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.geomAngle != geomAngle;
}