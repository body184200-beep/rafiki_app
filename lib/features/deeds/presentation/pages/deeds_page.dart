import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';

void main() => runApp(const Hasanatey());

class Hasanatey extends StatelessWidget {
  const Hasanatey({super.key});
  @override
  Widget build(BuildContext context) {
    final hasParent = Localizations.of<AppLocalizations>(context, AppLocalizations) != null;
    if (hasParent) {
      return Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'serif',
          scaffoldBackgroundColor: _C.bg,
          colorScheme: const ColorScheme.dark(primary: _C.jade),
        ),
        child: const HasanateyScreen(),
      );
    }

    return MaterialApp(
      title: 'حسناتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'serif',
        scaffoldBackgroundColor: _C.bg,
        colorScheme: const ColorScheme.dark(primary: _C.jade),
      ),
      home: const HasanateyScreen(),
    );
  }
}

// ── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const Color bg        = Color(0xff060D12);
  static const Color surface   = Color(0xff0E1A22);

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
class DhikrEntry {
  String text;
  int count;
  int target;     // 0 = no target
  DhikrEntry({required this.text, this.count = 0, this.target = 0});

  Map<String, dynamic> toJson() => {
    'text': text,
    'count': count,
    'target': target,
  };

  factory DhikrEntry.fromJson(Map<String, dynamic> json) => DhikrEntry(
    text: json['text'] as String,
    count: json['count'] as int? ?? 0,
    target: json['target'] as int? ?? 0,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
class HasanateyScreen extends StatefulWidget {
  const HasanateyScreen({super.key});
  @override
  State<HasanateyScreen> createState() => _HasanateyScreenState();
}

class _HasanateyScreenState extends State<HasanateyScreen>
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
  final List<_Spark> _sparks = [];
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
        _sparks.add(_Spark(
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
      builder: (_) => _ConfirmDialog(message: message, onConfirm: onConfirm),
    );
  }

  void _openDhikrSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DhikrPickerSheet(
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
      builder: (_) => _TargetEditorSheet(
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
            child: _GlowBlob(color: _C.jade.withValues(alpha: 0.07), size: 380)),
        Positioned(bottom: 0, right: -100,
            child: _GlowBlob(color: _C.gold.withValues(alpha: 0.06), size: 320)),

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
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [_C.gold, _C.goldLight],
              ).createShader(r),
              child: const Text("حَسَنَاتِي",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.1)),
            ),
            const SizedBox(height: 3),
            const Text("سبّح واذكر الله",
                style: TextStyle(fontSize: 11, color: _C.textSub,
                    letterSpacing: 1.4)),
          ]),
          Row(children: [
            _GlassIconBtn(
              icon: Icons.track_changes_rounded,
              color: _C.goldLight,
              tooltip: "تعديل الهدف",
              onTap: _openTargetEdit,
            ),
            const SizedBox(width: 10),
            _GlassIconBtn(
              icon: Icons.restart_alt_rounded,
              color: _C.red,
              tooltip: "تصفير الكل",
              onTap: _resetAll,
            ),
          ]),
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
        _StatItem(label: "إجمالي الحسنات", value: total.toString(), color: _C.goldLight),
        Container(width: 1, height: 28, color: _C.textHint),
        _StatItem(label: "عدد الأذكار", value: _adhkar.length.toString(), color: _C.jadeLight),
        Container(width: 1, height: 28, color: _C.textHint),
        _StatItem(label: "اكتملت", value: _adhkar.where((e) => e.target > 0 && e.count >= e.target).length.toString(), color: _C.jade),
      ]),
    );
  }

  // ── Dhikr selector ─────────────────────────────────────────────────────────
  Widget _buildDhikrSelector() {
    return GestureDetector(
      onTap: _openDhikrSheet,
      child: _GlassCard(
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
                painter: _ArcPainter(_progressPct, _C.gold, _C.textHint),
              ),
            ),
          ),

        // Ripple rings
        AnimatedBuilder(
          animation: _rippleAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(250, 250),
            painter: _RipplePainter(_rippleAnim.value, _burstAnim.value, _C.jade, _C.gold),
          ),
        ),

        // Sparks
        AnimatedBuilder(
          animation: _rippleAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(250, 250),
            painter: _SparkPainter(_sparks, _rippleAnim.value, _burstAnim.value),
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
        child: _ActionBtn(
          label: "تصفير هذا",
          icon: Icons.refresh_rounded,
          color: _C.red,
          onTap: _resetCurrent,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ActionBtn(
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

    return _GlassCard(
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
//  Bottom Sheets
// ═════════════════════════════════════════════════════════════════════════════

class _DhikrPickerSheet extends StatefulWidget {
  final List<DhikrEntry> adhkar;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;
  final void Function(String, int) onAdd;

  const _DhikrPickerSheet({
    required this.adhkar,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<_DhikrPickerSheet> createState() => _DhikrPickerSheetState();
}

class _DhikrPickerSheetState extends State<_DhikrPickerSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: _C.textHint,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text("اختر ذكرًا",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: _C.textMain)),
        ),

        // List
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.40,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.adhkar.length,
            itemBuilder: (_, idx) {
              final e = widget.adhkar[idx];
              final selected = idx == widget.selectedIndex;
              final isCustom = idx >= 8;
              return Dismissible(
                key: ValueKey(e.text + idx.toString()),
                direction: isCustom
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: _C.red.withValues(alpha: 0.2),
                  child: const Icon(Icons.delete_outline_rounded, color: _C.red),
                ),
                onDismissed: (_) => widget.onDelete(idx),
                child: ListTile(
                  onTap: () => widget.onSelect(idx),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: selected
                      ? Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.jade.withValues(alpha: 0.15),
                      border: Border.all(color: _C.jade.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.check_rounded, color: _C.jade, size: 18),
                  )
                      : Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  title: Text(e.text,
                      style: TextStyle(
                        color: selected ? _C.jadeLight : _C.textMain,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 16,
                      )),
                  trailing: e.count > 0
                      ? Text("${e.count}",
                      style: const TextStyle(color: _C.goldLight,
                          fontSize: 13, fontWeight: FontWeight.bold))
                      : null,
                ),
              );
            },
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // Add new
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: _SheetInput(
                controller: _textCtrl,
                hint: "ذكر جديد...",
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _SheetInput(
                controller: _targetCtrl,
                hint: "الهدف",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _textCtrl.text.trim();
                if (text.isEmpty) return;
                final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
                widget.onAdd(text, target);
                Navigator.pop(context);
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_C.gold, _C.goldLight]),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Target editor sheet ───────────────────────────────────────────────────────
class _TargetEditorSheet extends StatefulWidget {
  final DhikrEntry current;
  final ValueChanged<int> onSave;
  const _TargetEditorSheet({required this.current, required this.onSave});

  @override
  State<_TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<_TargetEditorSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final List<int> _presets = [10, 33, 34, 100, 300, 1000];

  @override
  void initState() {
    super.initState();
    if (widget.current.target > 0) {
      _ctrl.text = widget.current.target.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: _C.textHint,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text(widget.current.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: _C.textMain),
            textDirection: TextDirection.rtl),
        const SizedBox(height: 4),
        const Text("حدد الهدف",
            style: TextStyle(fontSize: 12, color: _C.textSub)),
        const SizedBox(height: 20),

        // Presets
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _presets.map((p) {
            final sel = _ctrl.text == p.toString();
            return GestureDetector(
              onTap: () => setState(() => _ctrl.text = p.toString()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sel ? _C.jade.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: sel ? _C.jade : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text("$p",
                    style: TextStyle(
                      color: sel ? _C.jadeLight : _C.textSub,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 16,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Manual input
        _SheetInput(
          controller: _ctrl,
          hint: "أو أدخل رقمًا مخصصًا",
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // Save button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              final val = int.tryParse(_ctrl.text.trim()) ?? 0;
              widget.onSave(val);
              Navigator.pop(context);
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [_C.jade, Color(0xff1A7A5C)]),
              ),
              child: const Center(
                child: Text("حفظ الهدف",
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.onSave(0);
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text("إزالة الهدف",
                style: TextStyle(color: _C.red, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Reusable widgets
// ═════════════════════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback onTap;
  const _GlassIconBtn({required this.icon, required this.color,
    required this.onTap, this.tooltip});
  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
    required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 14,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18,
          fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _C.textSub, fontSize: 10,
          letterSpacing: 0.5)),
    ]);
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const _SheetInput({
    required this.controller,
    required this.hint,
    this.textDirection,
    this.keyboardType,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Directionality(
        textDirection: textDirection ?? TextDirection.ltr,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: _C.textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.textHint, fontSize: 13),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.message, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      title: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: _C.textMain, fontSize: 16)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: _C.textSub)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () { Navigator.pop(context); onConfirm(); },
          child: const Text("تأكيد"),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Custom Painters
// ═════════════════════════════════════════════════════════════════════════════

// ── Arc painter (goal progress ring) ─────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  _ArcPainter(this.progress, this.activeColor, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 6;
    const startAngle = -pi / 2;
    const sweepFull = 2 * pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull, false,
      Paint()
        ..color = trackColor.withValues(alpha: 0.18)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull * progress, false,
      Paint()
        ..color = activeColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip glow dot
    final angle = startAngle + sweepFull * progress;
    final dx = cx + radius * cos(angle);
    final dy = cy + radius * sin(angle);
    canvas.drawCircle(Offset(dx, dy), 6,
        Paint()..color = activeColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(dx, dy), 4, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Ripple painter ────────────────────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final double burst;
  final Color jade;
  final Color gold;
  _RipplePainter(this.progress, this.burst, this.jade, this.gold);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.width * 0.41;

    // Static glow
    canvas.drawCircle(center, baseR + 6,
        Paint()
          ..color = jade.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    if (progress > 0) {
      // Expanding ring
      final ringR = baseR + 20 + progress * 70;
      canvas.drawCircle(center, ringR,
          Paint()
            ..color = jade.withValues(alpha: (1 - progress) * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * (1 - progress));

      if (progress > 0.15) {
        final r2 = baseR + 6 + (progress - 0.15) * 45;
        canvas.drawCircle(center, r2,
            Paint()
              ..color = jade.withValues(alpha: (1 - progress) * 0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2 * (1 - progress));
      }
    }

    // Gold burst rings when target hit
    if (burst > 0) {
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.15;
        final p = (burst - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final r = baseR + 10 + p * (80 + i * 20);
        canvas.drawCircle(center, r,
            Paint()
              ..color = gold.withValues(alpha: (1 - p) * 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (2.5 - i * 0.5) * (1 - p));
      }
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.burst != burst;
}

// ── Spark painter ─────────────────────────────────────────────────────────────
class _Spark {
  final double angle;
  final double speed;
  final double radius;
  final bool isGold;
  _Spark({required this.angle, required this.speed,
    required this.radius, required this.isGold});
}

class _SparkPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double tapProg;
  final double burstProg;
  _SparkPainter(this.sparks, this.tapProg, this.burstProg);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in sparks) {
      final prog = s.isGold ? burstProg : tapProg;
      if (prog <= 0) continue;
      final dist = s.speed * prog;
      final dx = cos(s.angle) * dist;
      final dy = sin(s.angle) * dist;
      final opacity = (1 - prog).clamp(0.0, 1.0);
      final color = s.isGold ? _C.gold : _C.jade;
      canvas.drawCircle(
        center + Offset(dx, dy),
        s.radius * opacity,
        Paint()..color = color.withValues(alpha: opacity * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.tapProg != tapProg || old.burstProg != burstProg ||
          old.sparks.length != sparks.length;
}