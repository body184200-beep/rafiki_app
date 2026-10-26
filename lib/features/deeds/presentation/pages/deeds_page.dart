import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/deeds/data/models/dhikr_entry.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_widgets.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_sheets.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_painters.dart';

class DeedsPage extends StatelessWidget {
  const DeedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        return Theme(
          data: ThemeData(
            brightness: isLight ? Brightness.light : Brightness.dark,
            fontFamily: 'serif',
            scaffoldBackgroundColor: isLight ? const Color(0xFFF8F6F0) : const Color(0xff060D12),
            colorScheme: isLight
                ? ColorScheme.light(primary: Color(0xFF0F4A39))
                : ColorScheme.dark(primary: Color(0xff059669)),
          ),
          child: const DeedsScreen(),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DeedsScreen – Modern Islamic Misbaha (المسبحة الإلكترونية المطورة)
// ═════════════════════════════════════════════════════════════════════════════
class DeedsScreen extends StatefulWidget {
  const DeedsScreen({super.key});
  @override
  State<DeedsScreen> createState() => _DeedsScreenState();
}

class _DeedsScreenState extends State<DeedsScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  late List<DhikrEntry> _adhkar;
  int _selectedIndex = 0;
  bool _showRecord = false;
  MisbahaTheme _theme = MisbahaTheme.emerald;
  int _hapticMode = 1; // 0: off, 1: each tap, 2: milestone only
  bool _soundEnabled = true;
  bool _fullScreenTap = false;

  DhikrEntry get _current => _adhkar[_selectedIndex];

  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _burstCtrl;
  late AnimationController _beadRotateCtrl;
  late AnimationController _pageCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _burstAnim;
  late Animation<double> _pageAnim;

  double _targetBeadRotation = 0.0;
  final List<Spark> _sparks = [];
  Timer? _sparkTimer;
  int _displayedCount = 0;
  final Random _rng = Random();

  // ── Default Authentic Adhkar ───────────────────────────────────────────────
  static final List<DhikrEntry> _defaultAdhkar = [
    DhikrEntry(
      text: "سُبْحَانَ اللَّهِ",
      target: 33,
      virtue: "تعدل صدقة عن كل عظم من عظامك، وهي من أحب الكلام إلى الله",
    ),
    DhikrEntry(
      text: "الْحَمْدُ لِلَّهِ",
      target: 33,
      virtue: "الحمد لله تملأ الميزان، وأفضل الدعاء الحمد لله",
    ),
    DhikrEntry(
      text: "اللَّهُ أَكْبَرُ",
      target: 34,
      virtue: "تملأ ما بين السماء والأرض عظمة وتوحيداً",
    ),
    DhikrEntry(
      text: "لَا إِلَهَ إِلَّا اللَّهُ",
      target: 100,
      virtue: "أفضل ما قاله النبي ﷺ والنبيون من قبله، وأعظم كلمة توحيد",
    ),
    DhikrEntry(
      text: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
      target: 100,
      virtue: "مفتاح الأرزاق ومغفرة الذنوب، كان النبي ﷺ يستغفر مائة مرة",
    ),
    DhikrEntry(
      text: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
      target: 100,
      virtue: "من صلى عليّ صلاة صلى الله عليه بها عشراً ورُفعت له عشر درجات",
    ),
    DhikrEntry(
      text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
      target: 100,
      virtue: "كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن",
    ),
    DhikrEntry(
      text: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
      target: 100,
      virtue: "كنزٌ عظيم من تحت عرش الرحمن ومن كنوز الجنة",
    ),
    DhikrEntry(
      text: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
      target: 100,
      virtue: "أمان الخائفين وملاذ المتوكلين في كل شدة وكرب",
    ),
    DhikrEntry(
      text: "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
      target: 40,
      virtue: "دعوة ذي النون، لم يدعُ بها مسلم في شيء قط إلا استجاب الله له",
    ),
  ];

  // ── Init & Lifecycle ───────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _adhkar = List.from(_defaultAdhkar);
    _displayedCount = _current.count;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _beadRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );

    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageAnim = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageCtrl.forward();

    _loadState();
  }

  @override
  void dispose() {
    _sparkTimer?.cancel();
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    _burstCtrl.dispose();
    _beadRotateCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _adhkar.map((e) => e.toJson()).toList();
      await prefs.setString('deeds_adhkar_list', jsonEncode(jsonList));
      await prefs.setInt('total_tasbihat_count', _totalHasanat);
      await prefs.setInt('deeds_selected_index', _selectedIndex);
      await prefs.setString('misbaha_theme_id', _theme.id);
      await prefs.setInt('misbaha_haptic_mode', _hapticMode);
      await prefs.setBool('misbaha_sound_enabled', _soundEnabled);
      await prefs.setBool('misbaha_fullscreen_tap', _fullScreenTap);
    } catch (e) {
      debugPrint('[DeedsPage] Error saving state: $e');
    }
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getString('deeds_adhkar_list');
      final savedIndex = prefs.getInt('deeds_selected_index');
      final themeId = prefs.getString('misbaha_theme_id');
      final haptic = prefs.getInt('misbaha_haptic_mode');
      final sound = prefs.getBool('misbaha_sound_enabled');
      final fullScreen = prefs.getBool('misbaha_fullscreen_tap');

      setState(() {
        if (themeId != null) _theme = MisbahaTheme.getTheme(themeId);
        if (haptic != null) _hapticMode = haptic;
        if (sound != null) _soundEnabled = sound;
        if (fullScreen != null) _fullScreenTap = fullScreen;

        if (rawList != null) {
          final List<dynamic> decoded = jsonDecode(rawList);
          final loaded = decoded
              .map((e) => DhikrEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          // Merge virtues into existing default adhkar if missing
          for (int i = 0; i < loaded.length && i < _defaultAdhkar.length; i++) {
            if (loaded[i].virtue == null || loaded[i].virtue!.isEmpty) {
              loaded[i].virtue = _defaultAdhkar[i].virtue;
            }
          }

          _adhkar = loaded;
          if (savedIndex != null && savedIndex < _adhkar.length) {
            _selectedIndex = savedIndex;
          }
          _displayedCount = _current.count;
        }
      });
    } catch (e) {
      debugPrint('[DeedsPage] Error loading state: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int get _totalHasanat => _adhkar.fold(0, (s, e) => s + e.count);

  double get _progressPct {
    if (_current.target <= 0) {
      // Free loop mode: loop every 33 counts for the bead ring
      return (_current.count % 33) / 33.0;
    }
    return (_current.count / _current.target).clamp(0.0, 1.0);
  }

  bool get _hasTarget => _current.target > 0;

  // ── Tap & Gesture Actions ──────────────────────────────────────────────────
  void _tap() {
    // Sound feedback
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    // Haptics
    if (_hapticMode == 1) {
      HapticFeedback.lightImpact();
    }

    // Pulse & Ripple
    _pulseCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0);

    // Rotate beads
    _targetBeadRotation += (2 * pi / 33);
    _beadRotateCtrl.forward(from: 0);

    final prevCount = _current.count;
    setState(() {
      _current.count++;
      _displayedCount = _current.count;
      if (_hasTarget && _current.count % _current.target == 0) {
        _current.cycle++;
      }
    });
    _saveState();

    _spawnSparks(isGold: false);

    // Check target completion
    if (_hasTarget && prevCount < _current.target && _current.count >= _current.target) {
      _triggerCompletion();
    }
  }

  void _undo() {
    if (_current.count <= 0) return;
    if (_hapticMode != 0) HapticFeedback.mediumImpact();
    _pulseCtrl.forward(from: 0);

    // Rotate beads backwards
    _targetBeadRotation -= (2 * pi / 33);
    _beadRotateCtrl.forward(from: 0);

    setState(() {
      _current.count--;
      _displayedCount = _current.count;
    });
    _saveState();
  }

  void _triggerCompletion() {
    if (_hapticMode != 0) {
      HapticFeedback.heavyImpact();
    }
    _burstCtrl.forward(from: 0);
    _spawnSparks(isGold: true, count: 28);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _hapticMode != 0) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _spawnSparks({bool isGold = false, int count = 10}) {
    setState(() {
      for (int i = 0; i < count; i++) {
        _sparks.add(Spark(
          angle: _rng.nextDouble() * 2 * pi,
          speed: 60 + _rng.nextDouble() * 100,
          radius: isGold ? (4 + _rng.nextDouble() * 5) : (3 + _rng.nextDouble() * 4),
          isGold: isGold,
        ));
      }
    });
    _sparkTimer?.cancel();
    _sparkTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _sparks.clear());
    });
  }

  void _resetCurrent() {
    if (_hapticMode != 0) HapticFeedback.mediumImpact();
    _showConfirm(
      message: "هل تريد تصفير عداد «${_current.text}»؟",
      onConfirm: () {
        setState(() {
          _current.count = 0;
          _current.cycle = 0;
          _displayedCount = 0;
        });
        _saveState();
      },
    );
  }

  void _resetAll() {
    if (_hapticMode != 0) HapticFeedback.heavyImpact();
    _showConfirm(
      message: "هل تريد تصفير جميع أذكار المسبحة؟",
      onConfirm: () {
        setState(() {
          for (final e in _adhkar) {
            e.count = 0;
            e.cycle = 0;
          }
          _displayedCount = 0;
        });
        _saveState();
      },
    );
  }

  void _selectDhikr(int idx) {
    if (idx < 0 || idx >= _adhkar.length) return;
    if (_hapticMode != 0) HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = idx;
      _displayedCount = _current.count;
    });
    _saveState();
    _pageCtrl.forward(from: 0);
  }

  void _quickSetTarget(int target) {
    if (_hapticMode != 0) HapticFeedback.selectionClick();
    setState(() {
      _current.target = target;
    });
    _saveState();
  }

  void _addDhikr(String text, int target, String? virtue) {
    setState(() {
      _adhkar.add(DhikrEntry(text: text, target: target, virtue: virtue));
      _selectedIndex = _adhkar.length - 1;
      _displayedCount = 0;
    });
    _saveState();
  }

  void _deleteCustomDhikr(int idx) {
    if (idx < 10) return; // Protect default authentic adhkar
    setState(() {
      if (_selectedIndex == idx) _selectedIndex = 0;
      if (_selectedIndex > idx) _selectedIndex--;
      _adhkar.removeAt(idx);
      _displayedCount = _current.count;
    });
    _saveState();
  }

  void _showConfirm({required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmDialog(message: message, onConfirm: onConfirm),
    );
  }

  void _openDhikrSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DhikrPickerSheet(
        adhkar: _adhkar,
        selectedIndex: _selectedIndex,
        theme: _theme,
        onSelect: (idx) {
          Navigator.pop(context);
          _selectDhikr(idx);
        },
        onDelete: _deleteCustomDhikr,
        onAdd: (text, target, virtue) => _addDhikr(text, target, virtue),
      ),
    );
  }

  void _openThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MisbahaThemeSheet(
        currentTheme: _theme,
        onSelect: (t) {
          setState(() => _theme = t);
          _saveState();
        },
      ),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MisbahaSettingsSheet(
        hapticMode: _hapticMode,
        soundEnabled: _soundEnabled,
        fullScreenTap: _fullScreenTap,
        onHapticChanged: (val) {
          setState(() => _hapticMode = val);
          _saveState();
        },
        onSoundChanged: (val) {
          setState(() => _soundEnabled = val);
          _saveState();
        },
        onFullScreenChanged: (val) {
          setState(() => _fullScreenTap = val);
          _saveState();
        },
      ),
    );
  }

  void _openTargetEdit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TargetEditorSheet(
        current: _current,
        onSave: (t) {
          setState(() => _current.target = t);
          _saveState();
        },
      ),
    );
  }

  // ── Build Screen ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider.instance.isLight ? const Color(0xFFF8F6F0) : const Color(0xff060D12),
      body: Stack(
        children: [
          // Background ambient glows matching theme
          Positioned(
            top: -120,
            left: -80,
            child: GlowBlob(color: _theme.primary.withValues(alpha: 0.12), size: 400),
          ),
          Positioned(
            bottom: 40,
            right: -100,
            child: GlowBlob(color: _theme.accent.withValues(alpha: 0.10), size: 360),
          ),

          // Main Tap detector (if full screen tap is enabled)
          if (_fullScreenTap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _tap,
              ),
            ),

          SafeArea(
            child: FadeTransition(
              opacity: _pageAnim,
              child: Column(
                children: [
                  _buildTopHeader(),
                  SizedBox(height: 4),
                  _buildDhikrCarousel(),
                  SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        children: [
                          _buildActiveDhikrCard(),
                          SizedBox(height: 24),
                          _buildInteractiveMisbaha(),
                          SizedBox(height: 22),
                          _buildTargetPill(),
                          SizedBox(height: 20),
                          _buildActionButtons(),
                          SizedBox(height: 24),
                          _buildRecordToggle(),
                          if (_showRecord) ...[
                            SizedBox(height: 16),
                            _buildRecordList(),
                          ],
                          SizedBox(height: 16),
                        ],
                      ),
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

  // ── Top Header Bar ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: _theme.accentLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _theme.accentLight.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (r) => LinearGradient(
                          colors: [_theme.accentLight, Colors.white],
                        ).createShader(r),
                        child: Text(
                          "المِسْبَحَةُ الإِلِكْتُرُونِيَّة",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
                    style: TextStyle(
                      fontSize: 12,
                      color: DeedsColors.textSub,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Theme switch
                  GlassIconBtn(
                    icon: Icons.palette_outlined,
                    color: _theme.primaryLight,
                    tooltip: "خامة المسبحة (${_theme.name})",
                    onTap: _openThemeSheet,
                  ),
                  SizedBox(width: 8),
                  // Settings
                  GlassIconBtn(
                    icon: Icons.tune_rounded,
                    color: _theme.accentLight,
                    tooltip: "إعدادات الصوت والاهتزاز",
                    onTap: _openSettingsSheet,
                  ),
                  SizedBox(width: 8),
                  // Reset all
                  GlassIconBtn(
                    icon: Icons.restart_alt_rounded,
                    color: DeedsColors.red,
                    tooltip: "تصفير الكل",
                    onTap: _resetAll,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          // Total Hasanat Badge Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _theme.primary.withValues(alpha: 0.10),
              border: Border.all(color: _theme.primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: _theme.accentLight, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "إجمالي التسبيحات",
                      style: TextStyle(color: DeedsColors.textSub, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  "$_totalHasanat",
                  style: TextStyle(
                    color: _theme.accentLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dhikr Carousel ─────────────────────────────────────────────────────────
  Widget _buildDhikrCarousel() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _adhkar.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == _adhkar.length) {
            // Add custom dhikr chip
            return GestureDetector(
              onTap: _openDhikrSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, color: _theme.accentLight, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "المزيد...",
                      style: TextStyle(color: _theme.accentLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final ep = _adhkar[i];
          final sel = i == _selectedIndex;
          return DhikrCapsuleChip(
            text: ep.text,
            count: ep.count,
            target: ep.target,
            isSelected: sel,
            theme: _theme,
            onTap: () => _selectDhikr(i),
          );
        },
      ),
    );
  }

  // ── Active Dhikr Card with Virtue ──────────────────────────────────────────
  Widget _buildActiveDhikrCard() {
    return GestureDetector(
      onTap: _openDhikrSheet,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _theme.primary.withValues(alpha: 0.16),
                    border: Border.all(color: _theme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _hasTarget ? "الهدف: ${_current.target}" : "تسبيح مفتوح",
                    style: TextStyle(
                      color: _theme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "تغيير الذكر",
                      style: TextStyle(color: DeedsColors.textSub, fontSize: 11),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded, color: DeedsColors.textSub, size: 16),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _current.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DeedsColors.textMain,
                height: 1.35,
              ),
            ),
            if (_current.virtue != null && _current.virtue!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _theme.accent.withValues(alpha: 0.10),
                  border: Border.all(color: _theme.accent.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _theme.accentLight, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _current.virtue!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _theme.accentLight,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── The Grand 33-Bead Interactive Misbaha ───────────────────────────────────
  Widget _buildInteractiveMisbaha() {
    const size = 290.0;
    final remaining = _hasTarget
        ? (_current.target - _current.count).clamp(0, _current.target)
        : null;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Ripple waves on tap
            AnimatedBuilder(
              animation: _rippleAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(size, size),
                painter: RipplePainter(
                  _rippleAnim.value,
                  _burstAnim.value,
                  _theme.primary,
                  _theme.accentLight,
                ),
              ),
            ),

            // 2. Spark particles
            AnimatedBuilder(
              animation: _rippleAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(size, size),
                painter: SparkPainter(
                  _sparks,
                  _rippleAnim.value,
                  _burstAnim.value,
                  jade: _theme.primaryLight,
                  gold: _theme.accentLight,
                ),
              ),
            ),

            // 3. The 33 3D Rotating Beads Ring
            AnimatedBuilder(
              animation: Listenable.merge([_beadRotateCtrl, _pulseCtrl]),
              builder: (_, __) {
                final rotation = _targetBeadRotation -
                    (1.0 - _beadRotateCtrl.value) * (2 * pi / 33);
                return CustomPaint(
                  size: const Size(size, size),
                  painter: MisbahaBeadRingPainter(
                    rotation: rotation,
                    progress: _progressPct,
                    count: _current.count,
                    theme: _theme,
                    pulse: _pulseCtrl.value,
                  ),
                );
              },
            ),

            // 4. Circular Progress Arc Track
            SizedBox(
              width: size - 44,
              height: size - 44,
              child: CustomPaint(
                painter: ArcPainter(
                  _progressPct,
                  _theme.accentLight,
                  _theme.primaryDark,
                  glowColor: _theme.accent,
                ),
              ),
            ),

            // 5. Central Counter Dial Button
            GestureDetector(
              onTap: _tap,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: size - 96,
                  height: size - 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _theme.dialBg,
                    border: Border.all(
                      color: _hasTarget && _current.count >= _current.target
                          ? _theme.accentLight
                          : _theme.primaryLight.withValues(alpha: 0.45),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_hasTarget && _current.count >= _current.target
                                ? _theme.accent
                                : _theme.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Eight-pointed Islamic Star Watermark
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: IslamicStarPainter(
                          color: _theme.primaryLight.withValues(alpha: 0.10),
                          radius: 46,
                        ),
                      ),

                      // Counter Display Content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Round / Milestone badge
                          if (_hasTarget && _current.cycle > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _theme.accent.withValues(alpha: 0.2),
                              ),
                              child: Text(
                                "الدورة ${_current.cycle + 1}",
                                style: TextStyle(
                                  color: _theme.accentLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                          // Large animated count number
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            transitionBuilder: (child, anim) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(anim),
                              child: FadeTransition(opacity: anim, child: child),
                            ),
                            child: Text(
                              "$_displayedCount",
                              key: ValueKey(_displayedCount),
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),

                          SizedBox(height: 4),

                          // Remaining or open state
                          Text(
                            _hasTarget
                                ? (remaining! <= 0
                                    ? "✓ تم الهدف"
                                    : "متبقي $remaining")
                                : "سبّح لله",
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasTarget && remaining! <= 0
                                  ? _theme.accentLight
                                  : _theme.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 2),
                          Text(
                            "انقر للتسبيح",
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.white.withValues(alpha: 0.35),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Target Selector Pill ─────────────────────────────────────────────
  Widget _buildTargetPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TargetCapsuleChip(
            label: "٣٣",
            isSelected: _current.target == 33,
            theme: _theme,
            onTap: () => _quickSetTarget(33),
          ),
          SizedBox(width: 6),
          TargetCapsuleChip(
            label: "١٠٠",
            isSelected: _current.target == 100,
            theme: _theme,
            onTap: () => _quickSetTarget(100),
          ),
          SizedBox(width: 6),
          TargetCapsuleChip(
            label: "١٠٠٠",
            isSelected: _current.target == 1000,
            theme: _theme,
            onTap: () => _quickSetTarget(1000),
          ),
          SizedBox(width: 6),
          TargetCapsuleChip(
            label: "مفتوح ∞",
            isSelected: _current.target == 0,
            theme: _theme,
            onTap: () => _quickSetTarget(0),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons (Undo, Reset, Custom Target) ────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ActionBtn(
            label: "تراجع -١",
            icon: Icons.undo_rounded,
            color: _theme.accentLight,
            onTap: _undo,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ActionBtn(
            label: "تصفير",
            icon: Icons.refresh_rounded,
            color: DeedsColors.red,
            onTap: _resetCurrent,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ActionBtn(
            label: "تعديل الهدف",
            icon: Icons.flag_outlined,
            color: _theme.primaryLight,
            onTap: _openTargetEdit,
          ),
        ),
      ],
    );
  }

  // ── Record Toggle & Detailed History List ──────────────────────────────────
  Widget _buildRecordToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showRecord = !_showRecord),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showRecord ? "إخفاء سجل الأذكار" : "عرض سجل الأذكار الكامل",
              style: TextStyle(
                color: _theme.primaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            AnimatedRotation(
              turns: _showRecord ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _theme.primaryLight,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    final entries = List<DhikrEntry>.from(_adhkar)
      ..sort((a, b) => b.count.compareTo(a.count));
    final max = entries.isEmpty ? 1 : (entries.first.count == 0 ? 1 : entries.first.count);

    return GlassCard(
      child: Column(
        children: entries.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final pct = entry.count / max;
          final done = entry.target > 0 && entry.count >= entry.target;

          return Padding(
            padding: EdgeInsets.only(top: idx == 0 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.text,
                        style: TextStyle(
                          color: DeedsColors.textMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (done)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _theme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "✓ اكتمل",
                          style: TextStyle(color: _theme.accentLight, fontSize: 10),
                        ),
                      ),
                    Text(
                      "${entry.count}",
                      style: TextStyle(
                        color: _theme.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (entry.target > 0)
                      Text(
                        " / ${entry.target}",
                        style: TextStyle(
                          color: DeedsColors.textSub,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 4.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                      done ? _theme.accentLight : _theme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
