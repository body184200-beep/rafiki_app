import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rafiki_app/core/services/media_notification_service.dart';

import 'package:rafiki_app/core/theme/theme_provider.dart';

// ─── RADIO STATION MODEL ─────────────────────────────────────────────────────

class RadioStation {
  final int id;
  final String name;
  final String subtitle;
  final String url;
  final IconData icon;

  const RadioStation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}

const List<RadioStation> kRadioStations = [
  RadioStation(
    id: 1,
    name: 'إذاعة القرآن الكريم - القاهرة',
    subtitle: 'البث المباشر الرسمي من القاهرة',
    url: 'https://radio.xecod.com/station/quran-cairo',
    icon: Icons.mosque_rounded,
  ),
  RadioStation(
    id: 2,
    name: 'إذاعة القرآن الكريم العامة',
    subtitle: 'تلاوات خاشعة على مدار ٢٤ ساعة',
    url: 'https://backup.qurango.net/radio/mix',
    icon: Icons.radio_rounded,
  ),
  RadioStation(
    id: 3,
    name: 'إذاعة تراتيل القرآن الكريم',
    subtitle: 'أجمل التراتيل لكبار قراء العالم الإسلامي',
    url: 'https://backup.qurango.net/radio/tarateel',
    icon: Icons.menu_book_rounded,
  ),
];

// ─── RADIO CONTROLLER ────────────────────────────────────────────────────────

class RadioController {
  static final RadioController instance = RadioController._internal();
  final AudioPlayer _player = AudioPlayer()..setVolume(1.0);

  RadioStation _currentStation = kRadioStations.first;
  RadioStation get currentStation => _currentStation;
  Timer? _progressTimer;

  RadioController._internal() {
    _initSession();
    MediaNotificationService.instance.registerHandlers(
      type: ActiveMediaType.radio,
      onPlay: () async {
        await _player.play();
        _startProgressTimer();
      },
      onPause: () async {
        _stopProgressTimer();
        await _player.pause();
      },
      onStop: () async {
        await stop();
      },
    );

    _player.playerStateStream.listen((state) {
      if (MediaNotificationService.instance.activeType == ActiveMediaType.radio) {
        if (state.processingState == ProcessingState.completed) {
          _stopProgressTimer();
          MediaNotificationService.instance.dismiss();
        } else if (state.processingState != ProcessingState.idle) {
          if (!state.playing) {
            _stopProgressTimer();
          } else {
            _startProgressTimer();
          }
          MediaNotificationService.instance.updatePlaybackState(state.playing);
        }
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isPlaying && MediaNotificationService.instance.activeType == ActiveMediaType.radio) {
        MediaNotificationService.instance.show(
          type: ActiveMediaType.radio,
          title: _currentStation.name,
          subtitle: _currentStation.subtitle.isNotEmpty ? _currentStation.subtitle : 'بث مباشر لإذاعة القرآن الكريم',
          isPlaying: true,
        );
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
  }

  bool get isPlaying =>
      _player.playerState.playing &&
      _player.playerState.processingState != ProcessingState.idle &&
      _player.playerState.processingState != ProcessingState.completed;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<double> get volumeStream => _player.volumeStream;

  Future<bool> setStation(RadioStation station) async {
    _currentStation = station;
    if (isPlaying) {
      return await playStation(station);
    }
    return true;
  }

  Future<bool> playStation(RadioStation station) async {
    _currentStation = station;
    try {
      await MediaNotificationService.instance.ensureExclusivePlayback(ActiveMediaType.radio);
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(station.url)));
      await _player.play();
      _startProgressTimer();
      await MediaNotificationService.instance.show(
        type: ActiveMediaType.radio,
        title: station.name,
        subtitle: station.subtitle.isNotEmpty ? station.subtitle : 'بث مباشر لإذاعة القرآن الكريم',
        isPlaying: true,
      );
      return true;
    } catch (e) {
      debugPrint('Radio play error for ${station.name}: $e');
      for (final s in kRadioStations) {
        if (s.id == station.id) continue;
        try {
          await _player.stop();
          await _player.setAudioSource(AudioSource.uri(Uri.parse(s.url)));
          await _player.play();
          _currentStation = s;
          _startProgressTimer();
          await MediaNotificationService.instance.show(
            type: ActiveMediaType.radio,
            title: s.name,
            subtitle: s.subtitle.isNotEmpty ? s.subtitle : 'بث مباشر لإذاعة القرآن الكريم',
            isPlaying: true,
          );
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  Future<bool> togglePlayPause() async {
    if (isPlaying) {
      _stopProgressTimer();
      await _player.pause();
      await MediaNotificationService.instance.updatePlaybackState(false);
      return false;
    } else {
      return await playStation(_currentStation);
    }
  }

  Future<void> stop() async {
    _stopProgressTimer();
    try {
      await _player.stop();
    } catch (_) {}
    if (MediaNotificationService.instance.activeType == ActiveMediaType.radio) {
      await MediaNotificationService.instance.dismiss();
    }
  }

  Future<void> setVolume(double val) async {
    await _player.setVolume(val.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    _stopProgressTimer();
    await _player.dispose();
  }
}

// ─── RADIO PAGE (Fast, Lightweight, Modern) ──────────────────────────────────

class QuranRadioPage extends StatefulWidget {
  const QuranRadioPage({super.key});

  @override
  State<QuranRadioPage> createState() => _QuranRadioPageState();
}

class _QuranRadioPageState extends State<QuranRadioPage> with WidgetsBindingObserver {
  final _radio = RadioController.instance;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 1.0;
  late StreamSubscription<PlayerState> _playerSub;

  static bool get _l => ThemeProvider.instance.isLight;
  static Color get _bg => _l ? const Color(0xFFF8F6F0) : const Color(0xff060A12);
  static Color get _cardBg => _l ? const Color(0xFFFFFFFF) : const Color(0xff0E1626);
  static Color get _teal => _l ? const Color(0xFF0F4A39) : const Color(0xff2EB88A);
  static Color get _tealLt => _l ? const Color(0xFF1D5A46) : const Color(0xff5EFACC);
  static Color get _gold => _l ? const Color(0xFF8D5B18) : const Color(0xffC9A84C);
  static Color get _textMain => _l ? const Color(0xFF111827) : const Color(0xffEDE8D8);
  static Color get _textSub => _l ? const Color(0xFF6B7280) : const Color(0xff7E93A8);
  static Color get _border => _l ? const Color(0xFFE5E7EB) : const Color(0xff162238);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isPlaying = _radio.isPlaying;

    _playerSub = _radio.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing &&
          state.processingState != ProcessingState.idle &&
          state.processingState != ProcessingState.completed;
      final loading = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      setState(() {
        _isPlaying = playing;
        _isLoading = loading;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerSub.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await _radio.togglePlayPause();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _switchStation(RadioStation station) async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await _radio.setStation(station);
    if (_isPlaying) {
      await _radio.playStation(station);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final station = _radio.currentStation;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'إذاعة القرآن الكريم',
            style: TextStyle(
              color: _textMain,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ── Hero Radio Station Card ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _isPlaying
                            ? _teal.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Radio Emblem Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPlaying
                              ? _teal.withValues(alpha: 0.16)
                              : (_l ? const Color(0xFFF3F4F6) : const Color(0xFF131F34)),
                          border: Border.all(
                            color: _isPlaying ? _teal : _border,
                            width: _isPlaying ? 2.5 : 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            station.icon,
                            color: _isPlaying ? _teal : _textSub,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Station Name
                      Text(
                        station.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Station Subtitle
                      Text(
                        station.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Live Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : (_isLoading
                                  ? _gold.withValues(alpha: 0.15)
                                  : (_l ? const Color(0xFFF3F4F6) : const Color(0xFF131D30))),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isPlaying
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : (_isLoading ? _gold.withValues(alpha: 0.4) : Colors.transparent),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'جاري الاتصال بالإذاعة...',
                                style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ] else if (_isPlaying) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'بث حي ومباشر الآن',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Icon(Icons.play_arrow_rounded, color: _textSub, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'انقر لتشغيل الإذاعة',
                                style: TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Main Play/Pause Button
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isPlaying
                                  ? [_teal, _tealLt]
                                  : [const Color(0xFF0F4A39), const Color(0xFF1D5A46)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _teal.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Station Switcher ─────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المحطات الإذاعية المتاحة',
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                for (final s in kRadioStations) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _switchStation(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: s.id == station.id
                                ? _teal.withValues(alpha: 0.12)
                                : _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: s.id == station.id ? _teal : _border,
                              width: s.id == station.id ? 1.4 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: s.id == station.id
                                      ? _teal.withValues(alpha: 0.2)
                                      : (_l ? const Color(0xFFF3F4F6) : const Color(0xFF131D30)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  s.icon,
                                  color: s.id == station.id ? _teal : _textSub,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        color: s.id == station.id ? _teal : _textMain,
                                        fontSize: 14,
                                        fontWeight: s.id == station.id ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.subtitle,
                                      style: TextStyle(color: _textSub, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (s.id == station.id)
                                Icon(Icons.check_circle_rounded, color: _teal, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Volume Control ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: _textSub,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _teal,
                            inactiveTrackColor: _l ? const Color(0xFFE5E7EB) : const Color(0xFF1E2C44),
                            thumbColor: _teal,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: _volume,
                            onChanged: (val) {
                              setState(() => _volume = val);
                              _radio.setVolume(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
