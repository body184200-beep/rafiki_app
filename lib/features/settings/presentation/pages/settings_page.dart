import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';

import 'package:rafiki_app/features/prophet_stories/presentation/pages/prophet_stories_page.dart';
import 'package:rafiki_app/features/quran_radio/presentation/pages/quran_radio_page.dart';
import 'package:rafiki_app/features/prayer/presentation/pages/prayer_schedule_page.dart';
import 'package:rafiki_app/features/gamification/presentation/pages/companion_challenge_page.dart';
import 'package:rafiki_app/features/gamification/presentation/pages/loot_box_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class _DT {
  static const bg = Color(0xFF060910);
  static const surface = Color(0xFF0C1320);
  static const surfaceHi = Color(0xFF131D30);

  static const border = Color(0xFF19253B);
  static const borderHi = Color(0xFF263857);

  static const accent = Color(0xFF34D399);
  static const accentMid = Color(0xFF10B981);
  static const accentDark = Color(0xFF059669);

  static const maleClr = Color(0xFF4FA8DE);
  static const femaleClr = Color(0xFFF472B6);

  static const textPri = Color(0xFFF8FAFC);
  static const textSec = Color(0xFF94A3B8);
  static const textDim = Color(0xFF475569);
  static const textHint = Color(0xFF4B5B75);
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENDER ENUM
// ═══════════════════════════════════════════════════════════════════════════════

enum Gender { none, male, female }

extension GenderExt on Gender {
  String greeting(AppLocalizations loc) {
    switch (this) {
      case Gender.male:
        return loc.greeting_male;
      case Gender.female:
        return loc.greeting_female;
      case Gender.none:
        return loc.greeting_neutral;
    }
  }

  String get savedKey => name;

  String badge(AppLocalizations loc) {
    switch (this) {
      case Gender.male:
        return loc.greeting_male_badge;
      case Gender.female:
        return loc.greeting_female_badge;
      case Gender.none:
        return '';
    }
  }

  String label(AppLocalizations loc) {
    switch (this) {
      case Gender.male:
        return loc.profile_gender_male;
      case Gender.female:
        return loc.profile_gender_female;
      case Gender.none:
        return '';
    }
  }

  String sublabel(AppLocalizations loc) {
    switch (this) {
      case Gender.male:
        return loc.profile_gender_male_label;
      case Gender.female:
        return loc.profile_gender_female_label;
      case Gender.none:
        return '';
    }
  }

  Color get color {
    switch (this) {
      case Gender.male:
        return _DT.maleClr;
      case Gender.female:
        return _DT.femaleClr;
      case Gender.none:
        return _DT.accent;
    }
  }

  IconData get icon {
    switch (this) {
      case Gender.male:
        return Icons.person_rounded;
      case Gender.female:
        return Icons.person_2_rounded;
      case Gender.none:
        return Icons.person_outline_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MENU ITEM DATA MODEL
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

/// Builds the locale-aware menu items list from [loc].
List<_MenuItem> _buildMenuItems(AppLocalizations loc) => [
      _MenuItem(
        title: loc.settings_menu_rewards_title,
        subtitle: loc.settings_menu_rewards_subtitle,
        icon: Icons.stars_rounded,
        gradStart: const Color(0xFF281C06),
        gradEnd: const Color(0xFF130D03),
        accentClr: const Color(0xFFF5C052),
        badge: loc.settings_menu_rewards_badge,
      ),
      _MenuItem(
        title: loc.settings_menu_quran_radio_title,
        subtitle: loc.settings_menu_quran_radio_subtitle,
        icon: Icons.graphic_eq_rounded,
        gradStart: const Color(0xFF092B1F),
        gradEnd: const Color(0xFF04160F),
        accentClr: const Color(0xFF34D399),
        badge: loc.settings_menu_quran_radio_badge,
      ),
      _MenuItem(
        title: loc.settings_menu_prayer_schedule_title,
        subtitle: loc.settings_menu_prayer_schedule_subtitle,
        icon: Icons.mosque_rounded,
        gradStart: const Color(0xFF0B2135),
        gradEnd: const Color(0xFF05111C),
        accentClr: const Color(0xFF38BDF8),
      ),
      _MenuItem(
        title: loc.settings_menu_challenge_title,
        subtitle: loc.settings_menu_challenge_subtitle,
        icon: Icons.military_tech_rounded,
        gradStart: const Color(0xFF271A06),
        gradEnd: const Color(0xFF130C02),
        accentClr: const Color(0xFFFBBF24),
        badge: loc.settings_menu_challenge_badge,
      ),
      _MenuItem(
        title: loc.settings_menu_prophets_title,
        subtitle: loc.settings_menu_prophets_subtitle,
        icon: Icons.auto_stories_rounded,
        gradStart: const Color(0xFF1F0C30),
        gradEnd: const Color(0xFF0F0419),
        accentClr: const Color(0xFFC084FC),
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

class _SettingState extends State<Setting>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  late final FocusNode _nameFocusNode;

  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _ambientCtrl;
  late final List<Animation<double>> _cardAnimations;
  late final Animation<double> _pulseAnim;

  String _username = '';
  bool _editingName = false;
  bool _isNameFocused = false;
  Gender _gender = Gender.none;

  late final List<_AmbientDot> _ambientDots;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isNameFocused = _nameFocusNode.hasFocus;
        });
      }
    });

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _cardAnimations = List.generate(8, (i) {
      final start = (i * 0.08).clamp(0.0, 0.65);
      final end = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    final rng = Random(65);
    _ambientDots = List.generate(
      28,
      (_) => _AmbientDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.3,
        opacity: 0.08 + rng.nextDouble() * 0.22,
      ),
    );

    _loadPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _nameFocusNode.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (!_ambientCtrl.isAnimating) _ambientCtrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _pulseCtrl.stop();
      _ambientCtrl.stop();
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? '';
    final gKey = prefs.getString('gender') ?? 'none';
    final g = Gender.values.firstWhere(
      (e) => e.savedKey == gKey,
      orElse: () => Gender.none,
    );
    if (!mounted) return;
    setState(() {
      _username = name;
      _gender = g;
      _nameController.text = name;
    });
    _entranceCtrl.forward();
  }

  Future<void> _saveName(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', trimmed);
    if (!mounted) return;
    setState(() {
      _username = trimmed;
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
      const LootBoxScreen(),
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
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI BUILDERS
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
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg ?? _DT.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? _DT.border, width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _avatar() {
    final clr = _gender.color;
    final letter = _username.isNotEmpty
        ? _username.trimLeft().characters.first
        : (_gender == Gender.none ? '؟' : (_gender == Gender.male ? 'أ' : 'أ'));

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [clr, clr.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: clr.withValues(alpha: 0.45),
                blurRadius: 22,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: clr.withValues(alpha: 0.15),
                blurRadius: 44,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Color(0xFF030712),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations loc) {
    final greet = _username.isEmpty
        ? '${_gender.greeting(loc)} 👋'
        : '${_gender.greeting(loc)}، $_username 👋';

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      borderColor: _DT.borderHi,
      bg: _DT.surfaceHi.withValues(alpha: 0.8),
      child: Column(
        children: [
          Row(
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
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_gender != Gender.none) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _gender.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _gender.color.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_gender.icon, size: 12, color: _gender.color),
                                const SizedBox(width: 4),
                                Text(
                                  _gender.badge(loc),
                                  style: TextStyle(
                                    color: _gender.color,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            _username.isEmpty
                                ? loc.settings_no_username_hint
                                : loc.settings_welcome_back,
                            style: const TextStyle(
                              color: _DT.textSec,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _EditButton(
                isEditing: _editingName,
                label: _editingName
                    ? loc.profile_close_button
                    : loc.profile_edit_button,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _editingName = !_editingName);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileEditor(AppLocalizations loc) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: _editingName
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _glass(
                bg: _DT.surface.withValues(alpha: 0.95),
                borderColor: _DT.borderHi,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative top highlight
                    Center(
                      child: Container(
                        width: 36,
                        height: 3.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _DT.borderHi,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Name input field
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: _isNameFocused
                            ? _DT.surfaceHi
                            : _DT.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isNameFocused ? _DT.accent : _DT.borderHi,
                          width: _isNameFocused ? 1.5 : 0.9,
                        ),
                        boxShadow: _isNameFocused
                            ? [
                                BoxShadow(
                                  color: _DT.accent.withValues(alpha: 0.15),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.badge_rounded,
                            color: _isNameFocused ? _DT.accent : _DT.textSec,
                            size: 20,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              style: const TextStyle(
                                color: _DT.textPri,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              cursorColor: _DT.accent,
                              onSubmitted: _saveName,
                              decoration: InputDecoration(
                                hintText: loc.profile_name_hint,
                                hintStyle: const TextStyle(
                                  color: _DT.textHint,
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_nameController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: _DT.textSec,
                                size: 18,
                              ),
                              onPressed: () {
                                _nameController.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Gender label
                    Text(
                      loc.profile_gender_label,
                      style: const TextStyle(
                        color: _DT.textSec,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Gender tiles
                    Row(
                      children: [
                        Expanded(
                          child: _GenderTile(
                            gender: Gender.male,
                            selected: _gender == Gender.male,
                            loc: loc,
                            onTap: () => _saveGender(Gender.male),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GenderTile(
                            gender: Gender.female,
                            selected: _gender == Gender.female,
                            loc: loc,
                            onTap: () => _saveGender(Gender.female),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Continue / Save button
                    GestureDetector(
                      onTap: () => _saveName(_nameController.text),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_DT.accentMid, _DT.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _DT.accent.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'متابعة',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 14),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_DT.accent, _DT.accentDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: _DT.textSec,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _DT.borderHi,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _menuCard(int index, List<_MenuItem> items) {
    final anim = _cardAnimations[(index + 1).clamp(0, _cardAnimations.length - 1)];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: _MenuCardTile(item: items[index], onTap: () => _navigate(index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = _buildMenuItems(loc);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _DT.bg,
        body: Stack(
          children: [
            // Ambient background lighting & particles
            AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            0.2 - _ambientCtrl.value * 0.4,
                            -0.6 + _ambientCtrl.value * 0.3,
                          ),
                          radius: 1.5,
                          colors: const [
                            Color(0xFF0C1628),
                            Color(0xFF070D18),
                            _DT.bg,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AmbientDotsPainter(_ambientDots),
                    ),
                  ),
                  Positioned(
                    top: -90,
                    right: -70,
                    child: _AmbientOrb(
                      color: _DT.accent.withValues(alpha: 0.1),
                      size: 300,
                    ),
                  ),
                  Positioned(
                    top: 240,
                    left: -90,
                    child: const _AmbientOrb(
                      color: Color(0xFF4338CA),
                      size: 240,
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    right: -40,
                    child: const _AmbientOrb(
                      color: Color(0xFF7E22CE),
                      size: 200,
                    ),
                  ),
                ],
              ),
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
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _DT.bg.withValues(alpha: 0.72),
                            border: const Border(
                              bottom: BorderSide(
                                color: _DT.border,
                                width: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFF1F5F9),
                          Color(0xFFE2E8F0),
                          Color(0xFFCBD5E1),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        loc.settings_title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Profile header & editor ───────────────────────
                        FadeTransition(
                          opacity: _cardAnimations[0],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.08),
                              end: Offset.zero,
                            ).animate(_cardAnimations[0]),
                            child: Column(
                              children: [
                                _header(loc),
                                _profileEditor(loc),
                              ],
                            ),
                          ),
                        ),

                        _sectionLabel(loc.settings_sections_label),

                        // ── Menu cards ─────────────────────────────────────
                        ...List.generate(
                          items.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _menuCard(i, items),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Footer ─────────────────────────────────────────
                        FadeTransition(
                          opacity: _cardAnimations.last,
                          child: Column(
                            children: [
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _DT.borderHi,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFF43F5E),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    loc.settings_footer,
                                    style: const TextStyle(
                                      color: _DT.textDim,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
  final AppLocalizations loc;

  const _GenderTile({
    required this.gender,
    required this.selected,
    required this.onTap,
    required this.loc,
  });

  @override
  State<_GenderTile> createState() => _GenderTileState();
}

class _GenderTileState extends State<_GenderTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

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
    final clr = widget.gender.color;
    final selected = widget.selected;
    final loc = widget.loc;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) => _ctrl.forward(),
        onTapCancel: () => _ctrl.forward(),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? clr.withValues(alpha: 0.12) : _DT.surfaceHi,
            border: Border.all(
              color: selected ? clr.withValues(alpha: 0.6) : _DT.border,
              width: selected ? 1.4 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: clr.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? clr.withValues(alpha: 0.22)
                      : _DT.surface,
                  border: Border.all(
                    color: selected
                        ? clr.withValues(alpha: 0.45)
                        : _DT.borderHi,
                    width: 0.9,
                  ),
                ),
                child: Icon(
                  widget.gender.icon,
                  size: 22,
                  color: selected ? clr : _DT.textSec,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.gender.label(loc),
                style: TextStyle(
                  color: selected ? clr : _DT.textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.gender.sublabel(loc),
                style: TextStyle(
                  color: selected ? clr.withValues(alpha: 0.75) : _DT.textSec,
                  fontSize: 11,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: clr),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.black,
                  ),
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
// EDIT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _EditButton extends StatelessWidget {
  final bool isEditing;
  final String label;
  final VoidCallback onTap;

  const _EditButton({
    required this.isEditing,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isEditing
              ? _DT.accentDark.withValues(alpha: 0.25)
              : _DT.surfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing ? _DT.accentMid : _DT.borderHi,
            width: 0.9,
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
              label,
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
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _DT.borderHi, width: 0.9),
            ),
            child: Icon(icon, color: _DT.textSec, size: 17),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AMBIENT ORB & DOTS
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
          colors: [color.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
    );
  }
}

class _AmbientDot {
  final double x;
  final double y;
  final double radius;
  final double opacity;

  const _AmbientDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

class _AmbientDotsPainter extends CustomPainter {
  final List<_AmbientDot> dots;

  _AmbientDotsPainter(this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final d in dots) {
      paint.color = Colors.white.withValues(alpha: d.opacity);
      canvas.drawCircle(
        Offset(d.x * size.width, d.y * size.height),
        d.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientDotsPainter oldDelegate) => false;
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
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.965,
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
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) => _pressCtrl.forward(),
        onTapCancel: () => _pressCtrl.forward(),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [item.gradStart, item.gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _DT.border, width: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: item.accentClr.withValues(alpha: 0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Shimmer top light edge
                  Container(
                    height: 1.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          item.accentClr.withValues(alpha: 0.6),
                          item.accentClr.withValues(alpha: 0.85),
                          item.accentClr.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.25, 0.5, 0.75, 1],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        // Icon with glow & border
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.accentClr.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.accentClr.withValues(alpha: 0.28),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.accentClr.withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, color: item.accentClr, size: 24),
                        ),
                        const SizedBox(width: 15),
                        // Title & Subtitle
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
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  if (item.badge.isNotEmpty) ...[
                                    const SizedBox(width: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.5,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.accentClr.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: item.accentClr.withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
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
                                style: const TextStyle(
                                  color: _DT.textSec,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Trailing chevron
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: item.accentClr.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: item.accentClr.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: item.accentClr.withValues(alpha: 0.55),
                            size: 13,
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
      ),
    );
  }
}