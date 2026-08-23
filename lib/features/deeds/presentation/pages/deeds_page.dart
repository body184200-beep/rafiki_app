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
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'serif',
        scaffoldBackgroundColor: _C.bg,
        colorScheme: const ColorScheme.dark(primary: _C.jade),
      ),
      child: const DeedsScreen(),
    );
  }
}

// ── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const Color bg        = Color(0xff060D12);

  static const Color gold      = Color(0xffC9A84C);
  static const Color goldLight = Color(0xffF0CC7A);
  static const Color goldDim   = Color(0xff8A6E2A);
  static const Color jade      = Color(0xff2EB88A);
  static const Color jadeLight = Color(0xff5EFACC);
  static const Color jadeDim   = Color(0xff1A7A5C);
  static const Color textMain  = Color(0xffEEE8D5);
  static const Color textSub   = Color(0xff7A8F98);
  static const Color textHint  = Color(0xff3E5260);
  static const Color red       = Color(0xffE05252);

}

// ── Data model ────────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════════════════
class DeedsScreen extends StatefulWidget {
  const DeedsScreen({super.key});
  @override
  State<DeedsScreen> createState() => _DeedsPageState();
}

class _DeedsPageState extends State<DeedsScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  late List<DhikrEntry> _adhkar;
  int _selectedIndex = 0;
  bool _showRecord = false;

  DhikrEntry get _current => _adhkar[_selectedIndex];

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _burstCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _pageCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _burstAnim;
  // ignore: unused_field
  late Animation<double> _counterAnim;
  late Animation<double> _pageAnim;

  // Particles
  final List<Spark> _sparks = [];
  int _displayedCount = 0;
  final Random _rng = Random();

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _adhkar = [
      DhikrEntry(text: "سبحان الله",            target: 33),
      DhikrEntry(text: "الحمد لله",             target: 33),
      DhikrEntry(text: "الله أكبر",             target: 34),
      DhikrEntry(text: "لا إله إلا الله",       target: 100),
      DhikrEntry(text: "أستغفر الله",           target: 100),
      DhikrEntry(text: "اللهم صل وسلم على محمد ﷺ", target: 10),
      DhikrEntry(text: "سبحان الله وبحمده",    target: 100),
      DhikrEntry(text: "سبحان الله العظيم",    target: 100),
    ];
    _displayedCount = _current.count;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.97), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);

    _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _counterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut);

    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _pageAnim = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageCtrl.forward();

    _loadState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _adhkar.map((e) => e.toJson()).toList();
      await prefs.setString('deeds_adhkar_list', jsonEncode(jsonList));
      await prefs.setInt('deeds_selected_index', _selectedIndex);
    } catch (_) {}
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getString('deeds_adhkar_list');
      final savedIndex = prefs.getInt('deeds_selected_index');
      
      if (rawList != null) {
        final List<dynamic> decoded = jsonDecode(rawList);
        final loadedAdhkar = decoded.map((e) => DhikrEntry.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _adhkar = loadedAdhkar;
          if (savedIndex != null && savedIndex < _adhkar.length) {
            _selectedIndex = savedIndex;
          }
          _displayedCount = _current.count;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    _burstCtrl.dispose();
    _counterCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int get _totalHasanat => _adhkar.fold(0, (s, e) => s + e.count);

  double get _progressPct {
    if (_current.target <= 0) return 0;
    return (_current.count / _current.target).clamp(0.0, 1.0);
  }

  bool get _hasTarget => _current.target > 0;

  // ── Tap action ─────────────────────────────────────────────────────────────
  void _tap() {
    HapticFeedback.lightImpact();
    _pulseCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0);

    final prevCount = _current.count;
    setState(() {
      _current.count++;
      _displayedCount = _current.count;
    });
    _saveState();

    _spawnSparks(isGold: false);

    // Check for milestone
    if (_hasTarget && prevCount < _current.target && _current.count >= _current.target) {
      _triggerCompletion();
    }
  }

  void _longPress() {
    if (_current.count <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _current.count--;
      _displayedCount = _current.count;
    });
    _saveState();
    _pulseCtrl.forward(from: 0);
  }

  void _triggerCompletion() {
    HapticFeedback.heavyImpact();
    _burstCtrl.forward(from: 0);
    _spawnSparks(isGold: true, count: 24);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  void _spawnSparks({bool isGold = false, int count = 8}) {
    setState(() {
      for (int i = 0; i < count; i++) {
        _sparks.add(Spark(
          angle:    _rng.nextDouble() * 2 * pi,
          speed:    50 + _rng.nextDouble() * 90,
          radius:   isGold ? (4 + _rng.nextDouble() * 5) : (3 + _rng.nextDouble() * 4),
          isGold:   isGold,
        ));
      }
    });
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _sparks.clear());
    });
  }

  void _resetCurrent() {
    HapticFeedback.mediumImpact();
    setState(() {
      _current.count = 0;
      _displayedCount = 0;
    });
    _saveState();
  }

  void _resetAll() {
    HapticFeedback.heavyImpact();
    _showConfirm(
      message: "تصفير جميع الأذكار؟",
      onConfirm: () {
        setState(() {
          for (final e in _adhkar) e.count = 0;
          _displayedCount = 0;
        });
        _saveState();
      },
    );
  }

  void _selectDhikr(int idx) {
    setState(() {
      _selectedIndex = idx;
      _displayedCount = _current.count;
    });
    _saveState();
    _pageCtrl.forward(from: 0);
  }

  void _addDhikr(String text, int target) {
    setState(() {
      _adhkar.add(DhikrEntry(text: text, target: target));
      _selectedIndex = _adhkar.length - 1;
      _displayedCount = 0;
    });
    _saveState();
  }

  void _deleteCustomDhikr(int idx) {
    if (idx < 8) return; // protect defaults
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
        onSelect: (idx) {
          Navigator.pop(context);
          _selectDhikr(idx);
        },
        onDelete: _deleteCustomDhikr,
        onAdd: (text, target) => _addDhikr(text, target),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        // Ambient blobs
        Positioned(top: -100, left: -80,
            child: GlowBlob(color: _C.jade.withValues(alpha: 0.07), size: 380)),
        Positioned(bottom: 0, right: -100,
            child: GlowBlob(color: _C.gold.withValues(alpha: 0.06), size: 320)),

        SafeArea(
          child: FadeTransition(
            opacity: _pageAnim,
            child: Column(children: [
              _buildHeader(),
              _buildStatsBanner(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    _buildDhikrSelector(),
                    const SizedBox(height: 32),
                    _buildCounterArea(),
                    const SizedBox(height: 12),
                    if (_hasTarget) _buildProgressLabel(),
                    const SizedBox(height: 28),
                    _buildButtons(),
                    const SizedBox(height: 28),
                    _buildRecordToggle(),
                    if (_showRecord) ...[
                      const SizedBox(height: 16),
                      _buildRecordList(),
                    ],
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_C.gold, _C.goldLight],
                  ).createShader(r),
                  child: const Text("حَسَنَاتِي",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.1)),
                ),
                const SizedBox(height: 4),
                const Text("سبّح واذكر الله",
                    style: TextStyle(fontSize: 12.5, color: _C.textSub)),
              ]),
              Row(children: [
                GlassIconBtn(
                  icon: Icons.track_changes_rounded,
                  color: _C.goldLight,
                  tooltip: "تعديل الهدف",
                  onTap: _openTargetEdit,
                ),
                const SizedBox(width: 10),
                GlassIconBtn(
                  icon: Icons.restart_alt_rounded,
                  color: _C.red,
                  tooltip: "تصفير الكل",
                  onTap: _resetAll,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _C.gold.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats banner ───────────────────────────────────────────────────────────
  Widget _buildStatsBanner() {
    final total = _totalHasanat;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _C.gold.withValues(alpha: 0.07),
        border: Border.all(color: _C.gold.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        StatItem(label: "إجمالي الحسنات", value: total.toString(), color: _C.goldLight),
        Container(width: 1, height: 28, color: _C.textHint),
        StatItem(label: "عدد الأذكار", value: _adhkar.length.toString(), color: _C.jadeLight),
        Container(width: 1, height: 28, color: _C.textHint),
        StatItem(label: "اكتملت", value: _adhkar.where((e) => e.target > 0 && e.count >= e.target).length.toString(), color: _C.jade),
      ]),
    );
  }

  // ── Dhikr selector ─────────────────────────────────────────────────────────
  Widget _buildDhikrSelector() {
    return GestureDetector(
      onTap: _openDhikrSheet,
      child: GlassCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("الذكر الحالي",
                  style: TextStyle(fontSize: 11, color: _C.textSub, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              Text(_current.text,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _C.textMain, height: 1.3),
                  overflow: TextOverflow.ellipsis),
              if (_hasTarget)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("الهدف: ${_current.target}",
                      style: const TextStyle(fontSize: 12, color: _C.textSub)),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _C.jade.withValues(alpha: 0.12),
              border: Border.all(color: _C.jade.withValues(alpha: 0.25)),
            ),
            child: const Row(children: [
              Text("تغيير", style: TextStyle(color: _C.jadeLight, fontSize: 13,
                  fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: _C.jade, size: 18),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Counter area ───────────────────────────────────────────────────────────
  Widget _buildCounterArea() {
    return Center(
      child: Stack(alignment: Alignment.center, children: [
        // Progress arc (behind everything)
        if (_hasTarget)
          SizedBox(
            width: 250, height: 250,
            child: AnimatedBuilder(
              animation: _rippleAnim,
              builder: (_, __) => CustomPaint(
                painter: ArcPainter(_progressPct, _C.gold, _C.textHint),
              ),
            ),
          ),

        // Ripple rings
        AnimatedBuilder(
          animation: _rippleAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(250, 250),
            painter: RipplePainter(_rippleAnim.value, _burstAnim.value, _C.jade, _C.gold),
          ),
        ),

        // Sparks
        AnimatedBuilder(
          animation: _rippleAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(250, 250),
            painter: SparkPainter(_sparks, _rippleAnim.value, _burstAnim.value, jade: _C.jade, gold: _C.gold),
          ),
        ),

        // Main button
        GestureDetector(
          onTap: _tap,
          onLongPress: _longPress,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hasTarget && _progressPct >= 1.0
                      ? [_C.gold, _C.goldDim]
                      : [_C.jade, _C.jadeDim],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_hasTarget && _progressPct >= 1.0 ? _C.gold : _C.jade)
                        .withValues(alpha: 0.30),
                    blurRadius: 50,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3), end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    "$_displayedCount",
                    key: ValueKey(_displayedCount),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "اضغط للذكر",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.50),
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "اضغط مطولاً للتراجع",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.30),
                    letterSpacing: 0.8,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Progress label ─────────────────────────────────────────────────────────
  Widget _buildProgressLabel() {
    final remaining = (_current.target - _current.count).clamp(0, _current.target);
    final done = _current.count >= _current.target;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          done ? "✓ اكتمل الهدف!" : "تبقّى $remaining",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: done ? _C.goldLight : _C.textSub,
          ),
        ),
        if (!done) ...[
          const SizedBox(width: 6),
          Text("من ${_current.target}",
              style: const TextStyle(fontSize: 13, color: _C.textHint)),
        ],
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _progressPct),
          duration: const Duration(milliseconds: 400),
          builder: (_, val, __) => LinearProgressIndicator(
            value: val,
            minHeight: 5,
            backgroundColor: _C.textHint.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(
                done ? _C.gold : _C.jade),
          ),
        ),
      ),
    ]);
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Row(children: [
      Expanded(
        child: ActionBtn(
          label: "تصفير هذا",
          icon: Icons.refresh_rounded,
          color: _C.red,
          onTap: _resetCurrent,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ActionBtn(
          label: "تعديل الهدف",
          icon: Icons.flag_outlined,
          color: _C.gold,
          onTap: _openTargetEdit,
        ),
      ),
    ]);
  }

  // ── Record toggle + list ───────────────────────────────────────────────────
  Widget _buildRecordToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showRecord = !_showRecord),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          _showRecord ? "إخفاء السجل" : "عرض السجل الكامل",
          style: const TextStyle(color: _C.jade, fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        AnimatedRotation(
          turns: _showRecord ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(Icons.keyboard_arrow_down_rounded, color: _C.jade, size: 18),
        ),
      ]),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(entry.text,
                      style: const TextStyle(color: _C.textMain, fontSize: 14,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                if (done)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("✓", style: TextStyle(color: _C.goldLight, fontSize: 11)),
                  ),
                Text("${entry.count}",
                    style: const TextStyle(color: _C.goldLight, fontSize: 16,
                        fontWeight: FontWeight.w800)),
                if (entry.target > 0)
                  Text(" / ${entry.target}",
                      style: const TextStyle(color: _C.textSub, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(done ? _C.gold : _C.jade),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
