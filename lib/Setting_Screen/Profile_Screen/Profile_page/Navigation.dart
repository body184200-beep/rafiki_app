import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Anbiaa/anbiaa_story_screen.dart';
import '../Radio/QuranRadioPage..dart';
import '../Salatey/PrayerSchedulePage.dart';
import '../Tahdey/TahadeyGame_Screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class _DT {
  static const bg         = Color(0xff060A10);
  static const surface    = Color(0xff0F1520);
  static const surfaceHi  = Color(0xff141C2A);

  static const border     = Color(0xff1C2438);
  static const borderHi   = Color(0xff263044);

  static const accent     = Color(0xff4ECCA3);
  static const accentMid  = Color(0xff2EB889);
  static const accentDark = Color(0xff1A9A6E);

  static const maleClr    = Color(0xff5BA4CF);
  static const femaleClr  = Color(0xffE88FC0);

  static const textPri    = Color(0xffEEF2F8);
  static const textSec    = Color(0xff7A879E);
  static const textDim    = Color(0xff2E3B4E);
  static const textHint   = Color(0xff3D4D60);
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENDER ENUM
// ═══════════════════════════════════════════════════════════════════════════════

enum Gender { none, male, female }

extension GenderExt on Gender {
  String get greeting {
    switch (this) {
      case Gender.male:   return 'أهلاً أخي';
      case Gender.female: return 'أهلاً أختي';
      case Gender.none:   return 'أهلاً بيك';
    }
  }

  String get savedKey => name;

  Color get color {
    switch (this) {
      case Gender.male:   return _DT.maleClr;
      case Gender.female: return _DT.femaleClr;
      case Gender.none:   return _DT.accent;
    }
  }

  IconData get icon {
    switch (this) {
      case Gender.male:   return Icons.person_rounded;
      case Gender.female: return Icons.person_2_rounded;
      case Gender.none:   return Icons.person_outline_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MENU ITEMS
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color gradStart;
  final Color gradEnd;
  final Color accentClr;
  final String badge;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradStart,
    required this.gradEnd,
    required this.accentClr,
    this.badge = '',
  });
}

const List<_MenuItem> _items = [
  _MenuItem(
    title:     'إذاعة القرآن',
    subtitle:  'استمع للقرآن الكريم',
    icon:      Icons.graphic_eq_rounded,
    gradStart: Color(0xff0E2E22),
    gradEnd:   Color(0xff071A14),
    accentClr: Color(0xff4ECCA3),
    badge:     'مباشر',
  ),
  _MenuItem(
    title:     'جدول الصلاة',
    subtitle:  'مواقيت الصلاة اليومية',
    icon:      Icons.mosque_rounded,
    gradStart: Color(0xff0E2030),
    gradEnd:   Color(0xff07131E),
    accentClr: Color(0xff60C8E8),
  ),
  _MenuItem(
    title:     'تحدي الصحابة',
    subtitle:  'اختبر معلوماتك الإسلامية',
    icon:      Icons.military_tech_rounded,
    gradStart: Color(0xff2A1E08),
    gradEnd:   Color(0xff181205),
    accentClr: Color(0xffF0C060),
    badge:     'جديد',
  ),
  _MenuItem(
    title:     'قصص الأنبياء',
    subtitle:  'سير وقصص مباركة',
    icon:      Icons.auto_stories_rounded,
    gradStart: Color(0xff1E0E2E),
    gradEnd:   Color(0xff12071A),
    accentClr: Color(0xffC080F0),
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();

  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final List<Animation<double>> _cardAnimations;
  late final Animation<double> _pulseAnim;

  String _username    = '';
  bool   _editingName = false;
  Gender _gender      = Gender.none;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // [0]=header  [1]=stats  [2-5]=cards
    _cardAnimations = List.generate(6, (i) {
      final start = (i * 0.10).clamp(0.0, 0.65);
      final end   = (start + 0.42).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _loadPrefs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString('username') ?? '';
    final gKey  = prefs.getString('gender')   ?? 'none';
    final g     = Gender.values.firstWhere(
          (e) => e.savedKey == gKey,
      orElse: () => Gender.none,
    );
    if (!mounted) return;
    setState(() {
      _username            = name;
      _gender              = g;
      _nameController.text = name;
    });
    _entranceCtrl.forward();
  }

  Future<void> _saveName(String name) async {
    final trimmed = name.trim();
    final prefs   = await SharedPreferences.getInstance();
    await prefs.setString('username', trimmed);
    if (!mounted) return;
    setState(() {
      _username    = trimmed;
      _editingName = false;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _saveGender(Gender g) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', g.savedKey);
    if (!mounted) return;
    setState(() => _gender = g);
    HapticFeedback.mediumImpact();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigate(int index) {
    HapticFeedback.selectionClick();
    final pages = [
      const QuranRadioPage(),
      const PrayerSchedulePage(),
      const Tahdey(),
      const Anbiaa(),
    ];
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => pages[index],
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _glass({
    required Widget child,
    double radius = 24,
    EdgeInsets? padding,
    Color? bg,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg ?? Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? _DT.border, width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _avatar() {
    final clr    = _gender.color;
    final letter = _username.isNotEmpty
        ? _username.trimLeft().characters.first
        : (_gender == Gender.none ? '؟' : (_gender == Gender.male ? 'أ' : 'أ'));

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [clr.withOpacity(0.85), clr.withOpacity(0.45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: clr.withOpacity(0.32), blurRadius: 22, spreadRadius: 2),
              BoxShadow(color: clr.withOpacity(0.10), blurRadius: 42, spreadRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: _DT.bg,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final greet = _username.isEmpty
        ? '${_gender.greeting} 👋'
        : '${_gender.greeting}، $_username 👋';

    return _glass(
      padding: const EdgeInsets.all(20),
      borderColor: _DT.borderHi,
      bg: _DT.surfaceHi.withOpacity(0.7),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greet,
                  style: const TextStyle(
                    color: _DT.textPri,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_gender != Gender.none) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _gender.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _gender.color.withOpacity(0.28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_gender.icon, size: 11, color: _gender.color),
                            const SizedBox(width: 4),
                            Text(
                              _gender == Gender.male ? 'أخ' : 'أخت',
                              style: TextStyle(
                                color: _gender.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        _username.isEmpty ? 'اضغط تعديل لإضافة اسمك' : 'يسعدنا وجودك معنا ✨',
                        style: const TextStyle(color: _DT.textSec, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _EditButton(
            isEditing: _editingName,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _editingName = !_editingName);
            },
          ),
        ],
      ),
    );
  }

  Widget _profileEditor() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _editingName
          ? Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _glass(
          bg: _DT.surface.withOpacity(0.95),
          borderColor: _DT.borderHi,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name row ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _DT.surfaceHi,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _DT.borderHi, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _DT.textPri, fontSize: 15),
                        cursorColor: _DT.accent,
                        onSubmitted: _saveName,
                        decoration: const InputDecoration(
                          hintText: 'اكتب اسمك...',
                          hintStyle: TextStyle(color: _DT.textHint, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SaveButton(onTap: () => _saveName(_nameController.text)),
                ],
              ),

              const SizedBox(height: 16),

              // ── Gender label ──────────────────────────────────────
              const Text(
                'النوع',
                style: TextStyle(
                  color: _DT.textSec,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              // ── Gender tiles ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _GenderTile(
                      gender: Gender.male,
                      selected: _gender == Gender.male,
                      onTap: () => _saveGender(Gender.male),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GenderTile(
                      gender: Gender.female,
                      selected: _gender == Gender.female,
                      onTap: () => _saveGender(Gender.female),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
    child: Text(
      text,
      style: const TextStyle(
        color: _DT.textSec,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );


  Widget _menuCard(int index) {
    final anim = _cardAnimations[index + 2];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(anim),
        child: _MenuCardTile(item: _items[index], onTap: () => _navigate(index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _DT.bg,
        body: Stack(
          children: [
            // Ambient background orbs
            Positioned(
              top: -80, right: -60,
              child: _AmbientOrb(color: _DT.accent, size: 260),
            ),
            Positioned(
              top: 180, left: -80,
              child: const _AmbientOrb(color: Color(0xff5060C8), size: 200),
            ),
            Positioned(
              bottom: 120, right: 10,
              child: const _AmbientOrb(color: Color(0xff8040A0), size: 160),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── AppBar ─────────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    floating: false,
                    centerTitle: true,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(color: _DT.bg.withOpacity(0.65)),
                      ),
                    ),
                    title: const Text(
                      'الإعدادات',
                      style: TextStyle(
                        color: _DT.textPri,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _GlassIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── Profile header ─────────────────────────────
                        FadeTransition(
                          opacity: _cardAnimations[0],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.08),
                              end: Offset.zero,
                            ).animate(_cardAnimations[0]),
                            child: Column(
                              children: [
                                _header(),
                                _profileEditor(),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Stats row ──────────────────────────────────
                        FadeTransition(
                          opacity: _cardAnimations[1],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(_cardAnimations[1]),
                          ),
                        ),

                        const SizedBox(height: 28),

                        _sectionLabel('الأقسام'),

                        // ── Menu cards ─────────────────────────────────
                        ...List.generate(
                          _items.length,
                              (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _menuCard(i),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Footer ─────────────────────────────────────
                        FadeTransition(
                          opacity: _cardAnimations.last,
                          child: Column(
                            children: [
                              Container(height: 0.5, color: _DT.border),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.favorite_rounded, color: Color(0xffE8506A), size: 13),
                                  const SizedBox(width: 5),
                                  Text(
                                    'صُنع بحب للمسلمين',
                                    style: TextStyle(color: _DT.textDim, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENDER TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _GenderTile extends StatefulWidget {
  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  const _GenderTile({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GenderTile> createState() => _GenderTileState();
}

class _GenderTileState extends State<_GenderTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clr      = widget.gender.color;
    final selected = widget.selected;
    final isMale   = widget.gender == Gender.male;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown:   (_) => _ctrl.reverse(),
        onTapUp:     (_) => _ctrl.forward(),
        onTapCancel: ()  => _ctrl.forward(),
        onTap:       widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? clr.withOpacity(0.1) : _DT.surfaceHi,
            border: Border.all(
              color: selected ? clr.withOpacity(0.45) : _DT.border,
              width: selected ? 1.2 : 0.8,
            ),
            boxShadow: selected
                ? [BoxShadow(color: clr.withOpacity(0.12), blurRadius: 18, spreadRadius: 0)]
                : [],
          ),
          child: Column(
            children: [
              // Icon circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? clr.withOpacity(0.18) : _DT.surface,
                  border: Border.all(
                    color: selected ? clr.withOpacity(0.38) : _DT.borderHi,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  widget.gender.icon,
                  size: 20,
                  color: selected ? clr : _DT.textSec,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isMale ? 'ذكر' : 'أنثى',
                style: TextStyle(
                  color: selected ? clr : _DT.textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMale ? 'أخ' : 'أخت',
                style: TextStyle(
                  color: selected ? clr.withOpacity(0.6) : _DT.textSec,
                  fontSize: 11,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: clr),
                  child: const Icon(Icons.check_rounded, size: 13, color: Colors.black),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.18), width: 0.8),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(sub, style: const TextStyle(color: _DT.textSec, fontSize: 10.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _EditButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onTap;

  const _EditButton({required this.isEditing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isEditing ? _DT.accentDark.withOpacity(0.22) : _DT.surfaceHi,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isEditing ? _DT.accentMid : _DT.border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEditing ? Icons.close_rounded : Icons.edit_rounded,
              size: 13,
              color: isEditing ? _DT.accent : _DT.textSec,
            ),
            const SizedBox(width: 5),
            Text(
              isEditing ? 'إغلاق' : 'تعديل',
              style: TextStyle(
                color: isEditing ? _DT.accent : _DT.textSec,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SAVE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_DT.accentMid, _DT.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _DT.accent.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.black, size: 21),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLASS ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DT.border, width: 0.8),
            ),
            child: Icon(icon, color: _DT.textSec, size: 17),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AMBIENT ORB
// ═══════════════════════════════════════════════════════════════════════════════

class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.07), Colors.transparent],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MENU CARD TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuCardTile extends StatefulWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuCardTile({required this.item, required this.onTap});

  @override
  State<_MenuCardTile> createState() => _MenuCardTileState();
}

class _MenuCardTileState extends State<_MenuCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.reverse(),
        onTapUp:     (_) => _pressCtrl.forward(),
        onTapCancel: ()  => _pressCtrl.forward(),
        onTap:       widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [item.gradStart, item.gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _DT.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: item.accentClr.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: item.accentClr.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: item.accentClr.withOpacity(0.22), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: item.accentClr.withOpacity(0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.accentClr, size: 23),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: _DT.textPri,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (item.badge.isNotEmpty) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: item.accentClr.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: item.accentClr.withOpacity(0.32), width: 0.8),
                                  ),
                                  child: Text(
                                    item.badge,
                                    style: TextStyle(
                                      color: item.accentClr,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(color: _DT.textSec, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: item.accentClr.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: item.accentClr.withOpacity(0.5),
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}