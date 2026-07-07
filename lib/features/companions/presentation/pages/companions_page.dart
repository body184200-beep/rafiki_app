import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:rafiki_app/features/companions/presentation/pages/companion_details_page.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static const bg        = Color(0xFF07090F);
  static const surface   = Color(0xFF0D1120);
  static const gold      = Color(0xFFD4A843);
  static const goldLight = Color(0xFFF0C870);
  static const onCard    = Color(0xFFF5EDD8);
  static const muted     = Color(0xFF4A5568);
}

// ─── SAHABA DATA ──────────────────────────────────────────────────────────────

class _Sahabi {
  final String name;
  final String title;
  final String initial;
  final Color accent;
  final List<String> categories;

  const _Sahabi({
    required this.name,
    required this.title,
    required this.initial,
    required this.accent,
    required this.categories,
  });
}

const List<_Sahabi> _sahabaList = [
  _Sahabi(name: "أبو بكر الصديق",      title: "الصدّيق",         initial: "أ", accent: Color(0xFFD4A843), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  _Sahabi(name: "عمر بن الخطاب",       title: "الفاروق",         initial: "ع", accent: Color(0xFF8B2020), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  _Sahabi(name: "عثمان بن عفان",       title: "ذو النورين",      initial: "ع", accent: Color(0xFF1A6B50), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "آل البيت", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  _Sahabi(name: "علي بن أبي طالب",     title: "باب مدينة العلم", initial: "ع", accent: Color(0xFF4A6BD4), categories: ["الخلفاء الراشدون", "العشرة المبشرون", "آل البيت", "المهاجرون", "أهل بدر", "أهل الرضوان", "رواة الحديث", "القادة والفرسان"]),
  _Sahabi(name: "خالد بن الوليد",      title: "سيف الله المسلول",initial: "خ", accent: Color(0xFFB85C20), categories: ["المهاجرون", "القادة والفرسان"]),
  _Sahabi(name: "عمرو بن العاص",       title: "فاتح مصر",        initial: "ع", accent: Color(0xFF6B3FA0), categories: ["المهاجرون", "القادة والفرسان"]),
  _Sahabi(name: "عبدالرحمن بن عوف",    title: "من العشرة المبشرين", initial: "ع", accent: Color(0xFF2D8A6B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر"]),
  _Sahabi(name: "سعد بن أبي وقاص",    title: "أسد الإسلام",     initial: "س", accent: Color(0xFF8B6020), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "القادة والفرسان"]),
  _Sahabi(name: "معاذ بن جبل",         title: "أعلم الحلال والحرام", initial: "م", accent: Color(0xFF1A5C8B), categories: ["الأنصار", "أهل بدر", "رواة الحديث"]),
  _Sahabi(name: "مصعب بن عمير",        title: "أول سفير في الإسلام",  initial: "م", accent: Color(0xFF6B2D5E), categories: ["المهاجرون", "أهل بدر", "الشهداء"]),
  _Sahabi(name: "بلال بن رباح",        title: "مؤذّن الرسول ﷺ", initial: "ب", accent: Color(0xFF8B4020), categories: ["المهاجرون", "أهل بدر"]),
  _Sahabi(name: "حذيفة بن اليمان",     title: "صاحب السر",       initial: "ح", accent: Color(0xFF2D5C8B), categories: ["الأنصار", "رواة الحديث", "القادة والفرسان"]),
  _Sahabi(name: "طلحة بن عبيد الله",    title: "الشهيد الحي",     initial: "ط", accent: Color(0xFFE2A732), categories: ["العشرة المبشرون", "المهاجرون", "الشهداء"]),
  _Sahabi(name: "الزبير بن العوام",     title: "حواري الرسول ﷺ",  initial: "ز", accent: Color(0xFF9E2A2B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "القادة والفرسان"]),
  _Sahabi(name: "أبو عبيدة بن الجراح",  title: "أمين الأمة",      initial: "أ", accent: Color(0xFF355E3B), categories: ["العشرة المبشرون", "المهاجرون", "أهل بدر", "القادة والفرسان"]),
  _Sahabi(name: "سلمان الفارسي",      title: "الباحث عن الحقيقة",  initial: "س", accent: Color(0xFF3F51B5), categories: ["المهاجرون", "رواة الحديث"]),
  _Sahabi(name: "أبو هريرة",          title: "حافظ الأمة",      initial: "أ", accent: Color(0xFF8D6E63), categories: ["المهاجرون", "رواة الحديث"]),
  _Sahabi(name: "عبد الله بن مسعود",   title: "فقيه الأمة",       initial: "ع", accent: Color(0xFF7E57C2), categories: ["المهاجرون", "أهل بدر", "رواة الحديث"]),
  _Sahabi(name: "سعيد بن زيد", title: "مستجاب الدعوة", initial: "س", accent: Color(0xFF5D4037), categories: ["العشرة المبشرون", "المهاجرون", "القادة والفرسان"]),
  _Sahabi(name: "خديجة بنت خويلد", title: "أم المؤمنين", initial: "خ", accent: Color(0xFFC2185B), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "عائشة بنت أبي بكر", title: "الفقيهة المحدثة", initial: "ع", accent: Color(0xFF7B1FA2), categories: ["آل البيت", "رواة الحديث", "الصحابيات"]),
  _Sahabi(name: "حفصة بنت عمر", title: "حارسة المصحف", initial: "ح", accent: Color(0xFF303F9F), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "أم سلمة", title: "المستشارة الحكيمة", initial: "أ", accent: Color(0xFF00796B), categories: ["آل البيت", "رواة الحديث", "الصحابيات"]),
  _Sahabi(name: "أنس بن مالك", title: "خادم رسول الله ﷺ", initial: "أ", accent: Color(0xFF388E3C), categories: ["الأنصار", "أهل الرضوان", "رواة الحديث"]),
  _Sahabi(name: "عبد الله بن عمر", title: "المتتبع للأثر", initial: "ع", accent: Color(0xFFFBC02D), categories: ["المهاجرون", "أهل الرضوان", "رواة الحديث"]),
  _Sahabi(name: "عبد الله بن عباس", title: "ترجمان القرآن", initial: "ع", accent: Color(0xFFE64A19), categories: ["آل البيت", "المهاجرون", "رواة الحديث"]),
  _Sahabi(name: "أبو أيوب الأنصاري", title: "مضيف الرسول ﷺ", initial: "أ", accent: Color(0xFF512DA8), categories: ["الأنصار", "أهل بدر", "القادة والفرسان"]),
  _Sahabi(name: "فاطمة الزهراء", title: "بضعة الرسول ﷺ", initial: "ف", accent: Color(0xFFD81B60), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "أسماء بنت أبي بكر", title: "ذات النطاقين", initial: "أ", accent: Color(0xFF0288D1), categories: ["المهاجرون", "الصحابيات"]),
  _Sahabi(name: "نسيبة بنت كعب", title: "المجاهدة الفدائية", initial: "ن", accent: Color(0xFF689F38), categories: ["الأنصار", "أهل الرضوان", "الصحابيات"]),
  _Sahabi(name: "حمزة بن عبد المطلب", title: "سيد الشهداء", initial: "ح", accent: Color(0xFFD32F2F), categories: ["آل البيت", "المهاجرون", "أهل بدر", "الشهداء"]),
  _Sahabi(name: "جعفر بن أبي طالب", title: "جعفر الطيار", initial: "ج", accent: Color(0xFF1976D2), categories: ["آل البيت", "المهاجرون", "الشهداء", "القادة والفرسان"]),
  
  // Wives of the Prophet ﷺ (أمهات المؤمنين المتبقيات)
  _Sahabi(name: "سودة بنت زمعة", title: "أم المؤمنين", initial: "س", accent: Color(0xFFEC407A), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "زينب بنت خزيمة", title: "أم المساكين", initial: "ز", accent: Color(0xFFAB47BC), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "زينب بنت جحش", title: "أم المؤمنين", initial: "ز", accent: Color(0xFF7E57C2), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "جويرية بنت الحارث", title: "العابدة الذاكرة", initial: "ج", accent: Color(0xFF5C6BC0), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "أم حبيبة", title: "المهاجرة الصابرة", initial: "أ", accent: Color(0xFF26A69A), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "صفية بنت حيي", title: "سليلة الأنبياء", initial: "ص", accent: Color(0xFF9CCC65), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "ميمونة بنت الحارث", title: "آخر زوجاته", initial: "م", accent: Color(0xFFD4E157), categories: ["آل البيت", "الصحابيات"]),

  // Children of the Prophet ﷺ (أبناء وبنات الرسول ﷺ)
  _Sahabi(name: "القاسم بن محمد", title: "صاحب الكنية", initial: "ق", accent: Color(0xFFFFA726), categories: ["آل البيت"]),
  _Sahabi(name: "عبد الله بن محمد", title: "الطيب الطاهر", initial: "ع", accent: Color(0xFFFF7043), categories: ["آل البيت"]),
  _Sahabi(name: "إبراهيم بن محمد", title: "الابن الأصغر", initial: "إ", accent: Color(0xFF8D6E63), categories: ["آل البيت"]),
  _Sahabi(name: "زينب بنت محمد", title: "الابنة الكبرى", initial: "ز", accent: Color(0xFF26C6DA), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "رقية بنت محمد", title: "ذات الهجرتين", initial: "ر", accent: Color(0xFF29B6F6), categories: ["آل البيت", "الصحابيات"]),
  _Sahabi(name: "أم كلثوم بنت محمد", title: "زوجة ذي النورين", initial: "أ", accent: Color(0xFF66BB6A), categories: ["آل البيت", "الصحابيات"]),
];

const List<_Sahabi> _tabiList = [
  _Sahabi(name: "أويس القرني", title: "خير التابعين", initial: "أ", accent: Color(0xFF1E88E5), categories: ["الكل"]),
  _Sahabi(name: "سعيد بن المسيب", title: "عالم أهل المدينة", initial: "س", accent: Color(0xFF43A047), categories: ["الكل"]),
  _Sahabi(name: "الحسن البصري", title: "واعظ الأمة", initial: "ح", accent: Color(0xFF8E24AA), categories: ["الكل"]),
  _Sahabi(name: "علي بن الحسين (زين العابدين)", title: "السجاد", initial: "ع", accent: Color(0xFFD81B60), categories: ["الكل", "آل البيت"]),
  _Sahabi(name: "عمر بن عبد العزيز", title: "الخليفة العادل", initial: "ع", accent: Color(0xFFF4511E), categories: ["الكل"]),
];

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class HomeGrid extends StatefulWidget {
  const HomeGrid({super.key});

  @override
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  int _selectedTab = 0; // 0 = الصحابة الكرام, 1 = كبار التابعين
  String _selectedCategory = "الكل";

  final List<String> _categories = [
    "الكل",
    "الخلفاء الراشدون",
    "العشرة المبشرون",
    "آل البيت",
    "المهاجرون",
    "الأنصار",
    "أهل بدر",
    "أهل الرضوان",
    "رواة الحديث",
    "القادة والفرسان",
    "الشهداء",
    "الصحابيات"
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedTab == 0 ? _sahabaList : _tabiList;
    final filteredList = _selectedCategory == "الكل"
        ? activeList
        : activeList.where((s) => s.categories.contains(_selectedCategory)).toList();

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildHeader(),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverHeaderDelegate(
                      height: 66.0,
                      child: _buildSegmentedControl(),
                    ),
                  ),
                  if (_selectedTab == 0)
                    SliverToBoxAdapter(
                      child: _buildCategoryRow(),
                    ),
                ];
              },
              body: _buildGrid(filteredList),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEGMENTED CONTROL ──────────────────────────────────────────────────────

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _C.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Future.microtask(() {
                if (mounted) setState(() { _selectedTab = 0; _selectedCategory = "الكل"; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "الصحابة الكرام",
                    style: TextStyle(
                      color: _selectedTab == 0 ? _C.bg : _C.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => Future.microtask(() {
                if (mounted) setState(() { _selectedTab = 1; _selectedCategory = "الكل"; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "كبار التابعين",
                    style: TextStyle(
                      color: _selectedTab == 1 ? _C.bg : _C.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? _C.bg : _C.goldLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              selectedColor: _C.gold,
              backgroundColor: _C.surface,
              checkmarkColor: _C.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _C.gold.withOpacity(isSelected ? 1.0 : 0.2)),
              ),
              onSelected: (selected) {
                if (selected) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: (_entryCtrl.value * 2).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _entryCtrl.value) * -16),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Column(
          children: [
            Row(
              children: [
                _GoldLine(leftToRight: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "✦",
                    style: TextStyle(
                      color: _C.gold,
                      fontSize: 16,
                      shadows: [Shadow(color: _C.gold.withOpacity(0.6), blurRadius: 14)],
                    ),
                  ),
                ),
                _GoldLine(leftToRight: true),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "الموسوعة الإسلامية",
              style: TextStyle(
                color: _C.goldLight,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                shadows: [Shadow(color: Color(0x55D4A843), blurRadius: 18)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "سير الأعلام والشخصيات الإسلامية",
              style: TextStyle(color: _C.muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _C.gold.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GRID ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<_Sahabi> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد عناصر في هذا التصنيف",
          style: TextStyle(color: _C.muted, fontSize: 15),
        ),
      );
    }
    return GridView.builder(
      key: ValueKey("$_selectedTab-$_selectedCategory"),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return _SahabiCard(
          sahabi: list[index],
          index: index,
          entryController: _entryCtrl,
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: SahabiDetails.fromName(list[index].name),
              ),
              transitionDuration: const Duration(milliseconds: 320),
            ),
          ),
        );
      },
    );
  }
}

// ─── SAHABI CARD ─────────────────────────────────────────────────────────────

class _SahabiCard extends StatefulWidget {
  final _Sahabi sahabi;
  final int index;
  final AnimationController entryController;
  final VoidCallback onTap;

  const _SahabiCard({
    required this.sahabi,
    required this.index,
    required this.entryController,
    required this.onTap,
  });

  @override
  State<_SahabiCard> createState() => _SahabiCardState();
}

class _SahabiCardState extends State<_SahabiCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _entryFade;
  late final Animation<double> _entrySlide;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.04,
    );

    final start = (widget.index * 0.065).clamp(0.0, 0.82);
    final end   = (start + 0.30).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _entryFade  = curve;
    _entrySlide = Tween<double>(begin: 28, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.entryController, _pressCtrl]),
      builder: (_, __) => Opacity(
        opacity: _entryFade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _entrySlide.value),
          child: Transform.scale(
            scale: 1.0 - _pressCtrl.value,
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final s = widget.sahabi;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: Hero(
        tag: s.name,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: _C.surface,
            border: Border.all(color: s.accent.withOpacity(0.28), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: s.accent.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: -24,
                  right: -24,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent.withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          s.accent.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.accent.withOpacity(0.12),
                          border: Border.all(color: s.accent.withOpacity(0.45), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: s.accent.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            s.initial,
                            style: TextStyle(
                              color: s.accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.accent.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: _C.muted, size: 9),
                          const SizedBox(width: 4),
                          const Text(
                            "اقرأ السيرة",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: _C.muted, fontSize: 10),
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
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _GoldLine extends StatelessWidget {
  final bool leftToRight;
  const _GoldLine({required this.leftToRight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: leftToRight
                ? [_C.gold.withOpacity(0.4), Colors.transparent]
                : [Colors.transparent, _C.gold.withOpacity(0.4)],
          ),
        ),
      ),
    );
  }
}

// ─── BACKGROUND ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BgPainter()),
    );
  }
}

class _BgPainter extends CustomPainter {
  static final _stars = List.generate(60, (i) {
    final r = math.Random(i * 37 + 11);
    return (
    x: r.nextDouble(),
    y: r.nextDouble(),
    rad: r.nextDouble() * 1.2 + 0.2,
    o: r.nextDouble() * 0.28 + 0.05,
    );
  });

  @override
  void paint(Canvas canvas, Size sz) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080A12), Color(0xFF07090F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.75, -0.75),
          radius: 0.55,
          colors: [const Color(0xFFD4A843).withOpacity(0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withOpacity(s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF07090F),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}