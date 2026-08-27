import 'package:flutter/material.dart';
import 'package:rafiki_app/features/guide/data/models/reciter_model.dart';
import 'package:rafiki_app/features/guide/data/datasources/reciters_data.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════
//  MODELS
// ══════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════

const _kBg        = Color(0xff060B14);
const _kBg2       = Color(0xff0A1020);
const _kSurface   = Color(0xff0F1A2E);
const _kSurface2  = Color(0xff162238);
const _kBorder    = Color(0xff1C2E48);

const _kGold      = Color(0xffD4AF37);
const _kGoldLight = Color(0xffF0D060);
const _kGoldDim   = Color(0xffA08828);
const _kGoldGlow  = Color(0x22D4AF37);
const _kGoldGlow2 = Color(0x44D4AF37);

const _kEmerald   = Color(0xff2ECC71);
const _kSapphire  = Color(0xff4488CC);
const _kAmethyst  = Color(0xffCC88EE);
const _kRuby      = Color(0xffE74C6C);

const _kTextPrimary  = Color(0xffEEE8D8);
const _kTextSec      = Color(0xff6A7A90);
const _kTextTertiary = Color(0xff3A4A60);
const _kStoryText    = Color(0xffD8D0BC);
const _kDetailText   = Color(0xffC8C0B0);

Color _eraColor(String era) {
  switch (era) {
    case 'صحابي':  return _kEmerald;
    case 'تابعي':  return _kSapphire;
    case 'عالم':   return _kAmethyst;
    case 'ذهبي':   return _kGold;
    default:        return const Color(0xff44BBCC);
  }
}

// ══════════════════════════════════════════════════════════════════
//  CARD STATE
// ══════════════════════════════════════════════════════════════════

class _CardState {
  int activeTab;
  _CardState() : activeTab = 0;
}

// ══════════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════════

class RecitersPage extends StatefulWidget {
  const RecitersPage({super.key});

  @override
  State<RecitersPage> createState() => _RecitersPageState();
}

class _RecitersPageState extends State<RecitersPage> with TickerProviderStateMixin {
  String _activeCategory = kCategories.keys.first;
  String _searchText = '';

  final Map<String, _CardState> _expandedCards = {};
  final TextEditingController   _searchCtrl    = TextEditingController();

  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ──────────────────────────────────────────────

  List<Reciter> get _filtered {
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      return kCategories.values
          .expand((l) => l)
          .where((r) =>
      r.name.contains(q) ||
          r.country.contains(q) ||
          r.specialty.contains(q) ||
          r.story.toLowerCase().contains(q) ||
          r.famousQuote.toLowerCase().contains(q))
          .toList();
    }
    return kCategories[_activeCategory] ?? [];
  }

  void _selectCategory(String cat) {
    setState(() {
      _activeCategory = cat;
      _searchText = '';
      _searchCtrl.clear();
      _expandedCards.clear();
    });
  }

  void _toggleCard(String key) {
    HapticFeedback.selectionClick().ignore();
    setState(() {
      if (_expandedCards.containsKey(key)) {
        _expandedCards.remove(key);
      } else {
        _expandedCards[key] = _CardState();
      }
    });
  }

  void _setCardTab(String key, int tab) {
    setState(() => _expandedCards[key]?.activeTab = tab);
  }

  // ── Ornament ──────────────────────────────────────────────────

  Widget _ornamentDivider({double opacity = 0.35}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _kGold.withAlpha((opacity * 255).round()),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('✦✦✦',
              style: TextStyle(
                color: _kGold.withAlpha((opacity * 255).round()),
                fontSize: 8, letterSpacing: 3,
              )),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _kGold.withAlpha((opacity * 255).round()),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _header() {
    final total = kCategories.values.expand((l) => l).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xff0D0830), Color(0xff08122A), _kBg],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withAlpha(76), width: 0.8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kGoldLight,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) => Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: const [_kGold, _kGoldLight, _kGoldDim, _kGold],
                  transform: GradientRotation(_shimmerCtrl.value * 6.28),
                ),
                boxShadow: [BoxShadow(
                  color: _kGold.withAlpha(102), blurRadius: 30, spreadRadius: 4,
                )],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xff0D0830),
                ),
                child: const Center(child: Text('📖', style: TextStyle(fontSize: 38))),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_kGoldDim, _kGold, _kGoldLight, _kGold, _kGoldDim],
            ).createShader(b),
            child: const Text(
              'مجتمع قراء القرآن الكريم',
              style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'من الصحابة الكرام إلى الجيل الرقمي\nكل واحد منهم رحلة مع كتاب الله',
            style: TextStyle(color: _kTextSec, fontSize: 12, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatPill(value: '$total', label: 'قارئ', icon: '👤'),
              _StatPill(value: '${kCategories.length}', label: 'حقبة', icon: '📅'),
              const _StatPill(value: '14', label: 'قرناً', icon: '⏳'),
              const _StatPill(value: '4', label: 'قارات', icon: '🌍'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category tabs ─────────────────────────────────────────────

  Widget _tabs() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: kCategories.keys.length,
        itemBuilder: (_, i) {
          final cat    = kCategories.keys.elementAt(i);
          final active = cat == _activeCategory && _searchText.isEmpty;
          final count  = kCategories[cat]!.length;
          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [_kGold, _kGoldDim]) : null,
                color: active ? null : _kSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? Colors.transparent : _kBorder, width: 0.8,
                ),
                boxShadow: active
                    ? [BoxShadow(color: _kGold.withAlpha(76), blurRadius: 12)]
                    : const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat,
                      style: TextStyle(
                        color: active ? _kBg : _kTextSec, fontSize: 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.normal,
                      )),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: active ? _kBg.withAlpha(76) : _kGoldGlow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                          color: active ? _kBg : _kGold,
                          fontSize: 9, fontWeight: FontWeight.w800,
                        )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _kTextPrimary, fontSize: 13),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو التخصص أو الدولة...',
          hintStyle: const TextStyle(color: _kTextSec, fontSize: 11.5),
          prefixIcon: Icon(
            _searchText.isEmpty ? Icons.search_rounded : Icons.close_rounded,
            color: _kGold, size: 20,
          ),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _kGold.withAlpha(51)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _kGold.withAlpha(38)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _kGold.withAlpha(127), width: 1.5),
          ),
        ),
        onChanged: (v) => setState(() {
          _searchText = v;
          _expandedCards.clear();
        }),
      ),
    );
  }

  // ── Section heading ───────────────────────────────────────────

  Widget _sectionTitle() {
    final count = _filtered.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGoldGlow2, borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                  color: _kGold, fontSize: 13, fontWeight: FontWeight.w900,
                )),
          ),
          const SizedBox(width: 8),
          Text(
            _searchText.isNotEmpty ? 'نتائج البحث' : _activeCategory,
            style: const TextStyle(
              color: _kGold, fontSize: 15, fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────

  Widget _card(Reciter r) {
    final key       = r.stableKey;
    final cardState = _expandedCards[key];
    final expanded  = cardState != null;
    final eraColor  = _eraColor(r.era);

    return AnimatedContainer(
      key: ValueKey(key),
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: expanded
              ? const [Color(0xff14102C), Color(0xff0E1C40)]
              : [_kSurface, _kSurface2],
        ),
        border: Border.all(
          color: expanded ? _kGold.withAlpha(127) : _kBorder,
          width: expanded ? 1.2 : 0.6,
        ),
        boxShadow: expanded
            ? [BoxShadow(color: _kGold.withAlpha(30), blurRadius: 24, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _toggleCard(key),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: expanded ? _kGold : _kTextSec, size: 22,
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kGold.withAlpha(
                                  (127 + (_pulseCtrl.value * 127)).round()),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${r.emoji}  ${r.name}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: expanded ? _kGold : _kTextPrimary,
                              fontSize: 16, fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 3),
                        Text(r.specialty,
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: _kTextSec, fontSize: 10.5)),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 6, runSpacing: 4,
                          children: [
                            _Badge(label: r.birth, color: _kSapphire),
                            _Badge(label: r.country, color: _kSapphire),
                            _Badge(label: r.era, color: eraColor),
                            _Badge(
                              label: '${r.yearsWithQuran} سنة مع القرآن',
                              color: _kGold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [
                          eraColor.withAlpha(51),
                          eraColor.withAlpha(10),
                        ],
                      ),
                      border: Border.all(
                        color: eraColor.withAlpha(expanded ? 140 : 51),
                        width: expanded ? 1.5 : 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _firstGrapheme(r.name),
                        style: TextStyle(
                          color: eraColor, fontSize: 26, fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            _ornamentDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _InnerTab(
                    label: 'تفاصيل', icon: Icons.info_outline_rounded,
                    active: cardState.activeTab == 2,
                    onTap: () => _setCardTab(key, 2),
                  ),
                  const SizedBox(width: 8),
                  _InnerTab(
                    label: 'المسيرة', icon: Icons.timeline_rounded,
                    active: cardState.activeTab == 1,
                    onTap: () => _setCardTab(key, 1),
                  ),
                  const SizedBox(width: 8),
                  _InnerTab(
                    label: 'القصة', icon: Icons.auto_stories_rounded,
                    active: cardState.activeTab == 0,
                    onTap: () => _setCardTab(key, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (cardState.activeTab == 0) _StoryTab(reciter: r),
            if (cardState.activeTab == 1) _TimelineTab(reciter: r, eraColor: eraColor),
            if (cardState.activeTab == 2) _DetailsTab(reciter: r, eraColor: eraColor),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text('لا توجد نتائج لـ"$_searchText"',
                style: const TextStyle(color: _kTextSec, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('جرّب كلمة أخرى أو اختر فئة مختلفة',
                style: TextStyle(color: _kTextTertiary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reciters = _filtered;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _ornamentDivider(opacity: 0.5)),
            SliverToBoxAdapter(child: _tabs()),
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _sectionTitle()),
            if (reciters.isEmpty)
              SliverToBoxAdapter(child: _empty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _card(reciters[i]),
                  childCount: reciters.length,
                  findChildIndexCallback: (Key key) {
                    final ValueKey<String> valueKey = key as ValueKey<String>;
                    final index = reciters.indexWhere((r) => r.stableKey == valueKey.value);
                    return index == -1 ? null : index;
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  final String value, label, icon;
  const _StatPill({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kGoldGlow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withAlpha(76), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _kTextSec, fontSize: 9)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(64), width: 0.6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String text;
  const _HighlightChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_kGoldGlow, Color(0x11D4AF37)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withAlpha(56), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('◆', style: TextStyle(color: _kGold, fontSize: 7)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: _kTextPrimary, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _InnerTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _InnerTab({
    required this.label, required this.icon,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kGoldGlow2 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _kGold.withAlpha(127) : _kBorder, width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? _kGold : _kTextSec),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: active ? _kGold : _kTextSec, fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Story Tab — NO "يحكي بلسانه" badge ────────────────────────────

class _StoryTab extends StatelessWidget {
  final Reciter reciter;
  const _StoryTab({required this.reciter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8, runSpacing: 6,
            children: reciter.highlights
                .map((h) => _HighlightChip(text: h))
                .toList(),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border(
                  right: BorderSide(color: _kGold.withAlpha(140), width: 3),
                  top:   BorderSide(color: _kBorder, width: 0.5),
                  bottom: BorderSide(color: _kBorder, width: 0.5),
                  left:  BorderSide(color: _kBorder, width: 0.5),
                ),
              ),
              child: Text(
                reciter.story,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _kStoryText, fontSize: 13.5,
                  height: 2.15, fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Tab ──────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final Reciter reciter;
  final Color   eraColor;
  const _TimelineTab({required this.reciter, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    final events = reciter.timeline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++) ...[
            _TimelineItem(event: events[i], isLast: i == events.length - 1, eraColor: eraColor),
            if (i < events.length - 1)
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Container(width: 1.5, height: 20, color: eraColor.withAlpha(51)),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final LifeEvent event;
  final bool isLast;
  final Color eraColor;
  const _TimelineItem({required this.event, required this.isLast, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBg2, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(event.event,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: _kTextPrimary, fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 4),
                Text(event.year,
                    style: TextStyle(
                      color: eraColor, fontSize: 10.5, fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLast ? eraColor.withAlpha(51) : _kBg2,
            border: Border.all(
              color: isLast ? eraColor : eraColor.withAlpha(102),
              width: isLast ? 1.5 : 0.8,
            ),
          ),
          child: Center(child: Text(event.icon, style: const TextStyle(fontSize: 14))),
        ),
      ],
    );
  }
}

// ── Details Tab ───────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final Reciter reciter;
  final Color   eraColor;
  const _DetailsTab({required this.reciter, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [eraColor.withAlpha(20), Colors.transparent]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: eraColor.withAlpha(64), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('أشهر قوله',
                        style: TextStyle(color: eraColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Icon(Icons.format_quote_rounded, color: eraColor, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Text('«${reciter.famousQuote}»',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _kTextPrimary, fontSize: 13, height: 1.8, fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailBlock(
            title: 'علاقته بالقرآن', content: reciter.quranRelation,
            icon: Icons.favorite_border_rounded, color: _kRuby,
          ),
          const SizedBox(height: 10),
          _DetailBlock(
            title: 'أسلوبه في التعليم', content: reciter.teachingStyle,
            icon: Icons.school_outlined, color: _kEmerald,
          ),
          if (reciter.students.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg2, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('أبرز تلاميذه',
                          style: TextStyle(color: _kAmethyst, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.people_outline_rounded, color: _kAmethyst, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6, runSpacing: 5,
                    children: reciter.students.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kAmethyst.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kAmethyst.withAlpha(64), width: 0.7),
                      ),
                      child: Text(s, style: const TextStyle(color: _kTextPrimary, fontSize: 11)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title, content;
  final IconData icon;
  final Color color;
  const _DetailBlock({
    required this.title, required this.content,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title,
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _kDetailText, fontSize: 12.5, height: 1.8)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════════

String _firstGrapheme(String s) {
  if (s.isEmpty) return '';
  final runes = s.runes.iterator;
  if (runes.moveNext()) return String.fromCharCode(runes.current);
  return s[0];
}