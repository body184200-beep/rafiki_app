import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF070D1A);
const _kCard    = Color(0xFF131F33);
const _kGold    = Color(0xFFD4A853);
const _kGoldDim = Color(0xFF8A6A2A);
const _kTeal    = Color(0xFF1A7F7A);
const _kText    = Color(0xFFEEE8D8);
const _kMuted   = Color(0xFF8A9BB0);
const _kSurface = Color(0xFF0F1929);

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class HadithModel {
  final int    number;
  final String arab;
  final String id;

  const HadithModel({
    required this.number,
    required this.arab,
    required this.id,
  });

  factory HadithModel.fromJson(Map<String, dynamic> j) => HadithModel(
    number: j['number'] as int,
    arab:   j['arab']   as String,
    id:     j['id']     as String,
  );
}

// ─────────────────────────────────────────────────────────────
//  HADITH SCREEN  –  self-contained, zero required args
//  يُستخدم كـ destination من Qu.dart:
//    destination: () => HadithScreen()
// ─────────────────────────────────────────────────────────────
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  List<HadithModel> _all      = [];
  List<HadithModel> _filtered = [];
  Set<int>          _favNums  = {};
  bool              _loading  = true;
  String?           _error;
  String            _query    = '';
  int               _tab      = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _favNums = (prefs.getStringList('hadith_fav') ?? []).map(int.parse).toSet();

      const url = 'https://hadith-api.vercel.app/books/muslim?range=1-150';
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data']['hadiths'] as List;
        _all      = data.map((e) => HadithModel.fromJson(e as Map<String, dynamic>)).toList();
        _filtered = _all;
      } else {
        _error = 'فشل تحميل البيانات (${res.statusCode})';
      }
    } catch (_) {
      _error = 'تعذّر الاتصال بالخادم';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFav(int number) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favNums.contains(number) ? _favNums.remove(number) : _favNums.add(number);
    });
    await prefs.setStringList(
      'hadith_fav', _favNums.map((e) => e.toString()).toList(),
    );
  }

  void _search(String q) {
    _query = q;
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((h) =>
      h.arab.contains(q) ||
          h.id.contains(q)   ||
          h.number.toString().contains(q)).toList();
    });
  }

  List<HadithModel> get _favList =>
      _all.where((h) => _favNums.contains(h.number)).toList();

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _tab,
        children: [_hadithTab(), _favTab()],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: Color(0xFF1E2D45), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor:   _kGold,
        unselectedItemColor: _kMuted,
        items: [
          const BottomNavigationBarItem(
            icon:  Icon(Icons.menu_book_rounded),
            label: 'الأحاديث',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _favNums.isNotEmpty,
              backgroundColor: _kGold,
              textColor: _kBg,
              label: Text('${_favNums.length}'),
              child: const Icon(Icons.bookmark_rounded),
            ),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Hadith list ───────────────────────────────────────
  Widget _hadithTab() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildSearch()),
        if (_loading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, __) => const _ShimmerCard(),
              childCount: 8,
            ),
          )
        else if (_error != null)
          SliverFillRemaining(child: _buildError())
        else if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _HadithCard(
                    hadith:   _filtered[i],
                    isFav:    _favNums.contains(_filtered[i].number),
                    onToggle: _toggleFav,
                    onTap: () => Navigator.push(ctx, _slideRoute(
                      _DetailScreen(
                        list:     _filtered,
                        index:    i,
                        favNums:  _favNums,
                        onToggle: _toggleFav,
                      ),
                    )),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
      ],
    );
  }

  // ── Tab 1: Favorites ─────────────────────────────────────────
  Widget _favTab() {
    final list = _favList;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        automaticallyImplyLeading: false,
        title: Text(
          list.isEmpty ? 'المفضلة' : 'المفضلة  (${list.length})',
          style: const TextStyle(
            color: _kGold, fontSize: 18, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: list.isEmpty
          ? _buildFavEmpty()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final h = list[i];
          return Dismissible(
            key: ValueKey(h.number),
            direction: DismissDirection.startToEnd,
            background: _dismissBg(),
            onDismissed: (_) => _toggleFav(h.number),
            child: _HadithCard(
              hadith:   h,
              isFav:    true,
              onToggle: _toggleFav,
              onTap: () => Navigator.push(ctx, _slideRoute(
                _DetailScreen(
                  list:     list,
                  index:    i,
                  favNums:  _favNums,
                  onToggle: _toggleFav,
                ),
              )),
            ),
          );
        },
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kBg,
      expandedHeight: 110,
      automaticallyImplyLeading: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'صحيح مسلم',
          style: TextStyle(color: _kGold, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        background: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [Color(0xFF0D1830), _kBg],
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 2, color: Color(0x66D4A853)),
          ),
        ]),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _kGold),
          onPressed: _load,
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  // ── Search bar ───────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: _kText, fontSize: 15),
        onChanged: _search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: _kGold, size: 20),
          hintText: 'ابحث في الأحاديث…',
          hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
          filled: true,
          fillColor: _kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kGold, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Empty / error states ─────────────────────────────────────
  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 52),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: _kMuted)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGold, foregroundColor: _kBg,
        ),
        onPressed: _load,
        icon:  const Icon(Icons.refresh_rounded),
        label: const Text('إعادة المحاولة'),
      ),
    ]),
  );

  Widget _buildEmpty() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: _kMuted, size: 52),
      SizedBox(height: 12),
      Text('لا توجد نتائج', style: TextStyle(color: _kMuted, fontSize: 16)),
    ]),
  );

  Widget _buildFavEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: _kCard, shape: BoxShape.circle,
          border: Border.all(color: _kGoldDim, width: 1.5),
        ),
        child: const Icon(Icons.bookmark_outline_rounded, color: _kGoldDim, size: 36),
      ),
      const SizedBox(height: 20),
      const Text(
        'لا توجد أحاديث محفوظة',
        style: TextStyle(color: _kMuted, fontSize: 17, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      const Text(
        'اضغط على علامة الحفظ في أي حديث لإضافته هنا',
        style: TextStyle(color: _kMuted, fontSize: 13),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    ]),
  );

  Widget _dismissBg() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade900,
      borderRadius: BorderRadius.circular(18),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
  );
}

// ─────────────────────────────────────────────────────────────
//  HADITH CARD
// ─────────────────────────────────────────────────────────────
class _HadithCard extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;
  final VoidCallback               onTap;

  const _HadithCard({
    required this.hadith,
    required this.isFav,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFav ? _kGold.withValues(alpha: 0.35) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              width: 52,
              decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote_rounded, color: _kTeal, size: 14),
                  const SizedBox(height: 4),
                  Text(
                    '${hadith.number}',
                    style: const TextStyle(
                      color: _kGold, fontSize: 13, fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hadith.arab,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kText, fontSize: 14, height: 1.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hadith.id,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            _BookmarkButton(number: hadith.number, isFav: isFav, onToggle: onToggle),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED BOOKMARK BUTTON
// ─────────────────────────────────────────────────────────────
class _BookmarkButton extends StatefulWidget {
  final int                        number;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;

  const _BookmarkButton({
    required this.number,
    required this.isFav,
    required this.onToggle,
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 1.4)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _tap() async {
    await _ctrl.forward();
    await widget.onToggle(widget.number);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          widget.isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: widget.isFav ? _kGold : _kMuted,
          size: 22,
        ),
        onPressed: _tap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHIMMER CARD
// ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 90,
        decoration: BoxDecoration(
          color: _kCard.withValues(alpha: _anim.value + 0.3),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class _DetailScreen extends StatefulWidget {
  final List<HadithModel>          list;
  final int                        index;
  final Set<int>                   favNums;
  final Future<void> Function(int) onToggle;

  const _DetailScreen({
    required this.list,
    required this.index,
    required this.favNums,
    required this.onToggle,
  });

  @override
  State<_DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<_DetailScreen> {
  late final PageController _controller;
  late int      _current;
  late Set<int> _localFav; // local copy → instant UI update

  @override
  void initState() {
    super.initState();
    _current    = widget.index;
    _localFav   = Set.of(widget.favNums);
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _toggle(int number) async {
    setState(() {
      _localFav.contains(number) ? _localFav.remove(number) : _localFav.add(number);
    });
    await widget.onToggle(number);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.list[_current];
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: Text(
          'حديث رقم ${h.number}',
          style: const TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          _BookmarkButton(
            number:   h.number,
            isFav:    _localFav.contains(h.number),
            onToggle: _toggle,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${_current + 1} / ${widget.list.length}',
              style: const TextStyle(color: _kGold, fontSize: 13, letterSpacing: 1),
            ),
          ),
          LinearProgressIndicator(
            value: (_current + 1) / widget.list.length,
            backgroundColor: _kCard,
            valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
            minHeight: 2,
          ),
          Expanded(
            child: PageView.builder(
              controller:    _controller,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount:     widget.list.length,
              itemBuilder:   (_, i) => _DetailPage(
                hadith:   widget.list[i],
                isFav:    _localFav.contains(widget.list[i].number),
                onToggle: _toggle,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left,  color: _kMuted, size: 18),
                SizedBox(width: 4),
                Text('اسحب للتنقل بين الأحاديث',
                    style: TextStyle(color: _kMuted, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: _kMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL PAGE  (single page inside PageView)
// ─────────────────────────────────────────────────────────────
class _DetailPage extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;

  const _DetailPage({
    required this.hadith,
    required this.isFav,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFav ? _kGold.withValues(alpha: 0.4) : const Color(0xFF1E2D45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C1624),
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: _kTeal, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('صحيح مسلم',
                        style: TextStyle(color: _kMuted, fontSize: 12)),
                  ]),
                  Text(
                    'الحديث ${hadith.number}',
                    style: const TextStyle(
                      color: _kGold, fontSize: 14, fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Arabic body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  hadith.arab,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: _kText, fontSize: 19, height: 2.1,
                    fontWeight: FontWeight.w400, letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            // Narrator footer
            Container(
              width: double.infinity,
              margin:  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: Text(
                hadith.id,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ROUTE HELPER
// ─────────────────────────────────────────────────────────────
PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder:        (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 320),
);