import 'package:flutter/material.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/widgets/category_chips.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/domain/hadith_catalog.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:rafiki_app/features/hadith/presentation/controllers/hadith_controller.dart';
import 'package:rafiki_app/features/hadith/presentation/pages/hadith_details_page.dart';
import 'package:rafiki_app/features/hadith/presentation/widgets/hadith_widgets.dart';

const _kBg = Color(0xFF070D1A);
const _kCard = Color(0xFF131F33);
const _kGold = Color(0xFFD4A853);
const _kGoldDim = Color(0xFF8A6A2A);
const _kText = Color(0xFFEEE8D8);
const _kMuted = Color(0xFF8A9BB0);
const _kSurface = Color(0xFF0F1929);

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  late final HadithController _c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c = HadithController(sl<HadithRepository>());
    _scroll.addListener(_onScroll);
    _c.init();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _c.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_c.loading && !_c.loadingMore && _c.hasMore) {
        _c.load();
      }
    }
  }

  Future<void> _openDetails(List<HadithModel> list, int index) async {
    await _c.saveLastRead(list[index]);
    if (!mounted) return;
    pushPage(
      context,
      HadithDetailsPage(
        list: list,
        index: index,
        favNums: _c.favNums,
        onToggle: _c.toggleFav,
        onSaveLastRead: _c.saveLastRead,
      ),
    );
  }

  Future<void> _resume() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _kGold),
      ),
    );
    try {
      final h = await _c.fetchLastRead();
      if (!mounted) return;
      Navigator.pop(context);
      if (h != null) {
        await _openDetails([h], 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الحديث. يرجى التحقق من الشبكة.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل الحديث.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _kBg,
          body: IndexedStack(
            index: _c.tab,
            children: [_listTab(), _favTab()],
          ),
          bottomNavigationBar: _bottomNav(),
        );
      },
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: BottomNavigationBar(
        currentIndex: _c.tab,
        onTap: _c.setTab,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _kGold,
        unselectedItemColor: _kMuted,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'الأحاديث',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _c.favNums.isNotEmpty,
              backgroundColor: _kGold,
              textColor: _kBg,
              label: Text('${_c.favNums.length}'),
              child: const Icon(Icons.bookmark_rounded),
            ),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }

  Widget _listTab() {
    return RefreshIndicator(
      color: _kGold,
      backgroundColor: _kCard,
      onRefresh: () => _c.load(reset: true),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kBg,
            expandedHeight: 110,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kGold, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'رجوع',
            ),
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'موسوعة الأحاديث الموثقة',
                style: TextStyle(
                  color: _kGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _kGold),
                onPressed: () => _c.load(reset: true),
                tooltip: 'تحديث',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _resumeBanner(),
                _search(),
                _filters(),
              ],
            ),
          ),
          if (_c.loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const ShimmerCard(),
                childCount: 8,
              ),
            )
          else if (_c.error != null)
            SliverFillRemaining(child: _error())
          else if (_c.filtered.isEmpty)
            const SliverFillRemaining(child: _Empty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final h = _c.filtered[i];
                    return HadithCard(
                      hadith: h,
                      isFav: _c.favNums.contains(h.number),
                      onToggle: _c.toggleFav,
                      onTap: () => _openDetails(_c.filtered, i),
                    );
                  },
                  childCount: _c.filtered.length,
                ),
              ),
            ),
          if (_c.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _favTab() {
    final list = _c.favList;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kGold, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'رجوع',
        ),
        title: Text(
          list.isEmpty ? 'المفضلة' : 'المفضلة  (${list.length})',
          style: const TextStyle(
            color: _kGold,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: list.isEmpty
          ? const _FavEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final h = list[i];
                return Dismissible(
                  key: ValueKey(h.number),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => _c.toggleFav(h.number),
                  child: HadithCard(
                    hadith: h,
                    isFav: true,
                    onToggle: _c.toggleFav,
                    onTap: () => _openDetails(list, i),
                  ),
                );
              },
            ),
    );
  }

  Widget _resumeBanner() {
    if (_c.lastReadNumber == null || _c.lastReadBookName == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2D45), Color(0xFF0F1929)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _resume,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_outline_rounded, color: _kGold, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'متابعة القراءة من حيث توقفت',
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'حديث رقم ${_c.lastReadNumber} في ${_c.lastReadBookName}',
                        style: const TextStyle(color: _kText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: _kGold, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: _kText, fontSize: 15),
        onChanged: _c.search,
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

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'اختر كتاب الحديث (العدد المتوفر من الـ API):',
            style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: HadithCatalog.sources.length,
            itemBuilder: (context, index) {
              final src = HadithCatalog.sources[index];
              final selected = _c.selectedSource == src;
              final count = _c.availableOf(src);
              final countStr = count > 0 ? ' ($count)' : '';
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    '$src$countStr',
                    style: TextStyle(
                      color: selected ? _kBg : _kText,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: selected,
                  selectedColor: _kGold,
                  backgroundColor: _kCard,
                  checkmarkColor: _kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: _kGold.withValues(alpha: selected ? 1 : 0.2),
                    ),
                  ),
                  onSelected: (value) {
                    if (value) _c.setSource(src);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'التصنيف الموضوعي للحديث:',
            style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
        CategoryChips(
          items: HadithCatalog.categories,
          selected: _c.selectedCategory,
          onSelected: _c.setCategory,
          selectedColor: _kGold,
          backgroundColor: _kSurface,
          unselectedLabel: _kMuted,
          selectedLabel: _kBg,
          height: 36,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _error() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 52),
            const SizedBox(height: 12),
            Text(
              _c.error!,
              style: const TextStyle(color: _kMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: _kBg,
              ),
              onPressed: () => _c.load(reset: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: _kMuted, size: 52),
          SizedBox(height: 12),
          Text('لا توجد نتائج', style: TextStyle(color: _kMuted, fontSize: 16)),
        ],
      ),
    );
  }
}

class _FavEmpty extends StatelessWidget {
  const _FavEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kCard,
              shape: BoxShape.circle,
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
        ],
      ),
    );
  }
}
