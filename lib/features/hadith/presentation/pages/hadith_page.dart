import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/domain/hadith_catalog.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:rafiki_app/features/hadith/presentation/controllers/hadith_controller.dart';
import 'package:rafiki_app/features/hadith/presentation/pages/hadith_details_page.dart';
import 'package:rafiki_app/features/hadith/presentation/widgets/hadith_widgets.dart';

// Unified Calming Islamic Palette
bool get _l => ThemeProvider.instance.isLight;
Color get _kBg => _l ? const Color(0xFFF8F6F0) : const Color(0xFF0A0E17);
Color get _kCard => _l ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
Color get _kCardBorder => _l ? const Color(0xFFE5E7EB) : const Color(0xFF1F293D);
Color get _kGold => _l ? const Color(0xFF8D5B18) : const Color(0xFFC9A84C);
Color get _kGoldLight => _l ? const Color(0xFFB48216) : const Color(0xFFE8CC7A);
Color get _kGoldDim => _l ? const Color(0xFF8D5B18) : const Color(0xFF8A6F30);
Color get _kText => _l ? const Color(0xFF111827) : const Color(0xFFF3EEDD);
Color get _kMuted => _l ? const Color(0xFF6B7280) : const Color(0xFF8B9CB2);

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  late final HadithController _c;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = HadithController(sl<HadithRepository>());
    _scroll.addListener(_onScroll);
    _c.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HadithDetailsPage(
          list: list,
          index: index,
          favNums: _c.favNums,
          onToggle: _c.toggleFav,
          onSaveLastRead: _c.saveLastRead,
        ),
      ),
    );
  }

  Future<void> _resume() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
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
          const SnackBar(
            content: Text(
              'تعذر استئناف القراءة. يرجى التحقق من الاتصال بالشبكة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل الحديث.',
            textDirection: TextDirection.rtl,
          ),
        ),
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
          appBar: _buildAppBar(),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Clean Top Tabs (All vs Favorites)
                _buildTabSwitch(),

                // Search & Filter Bar (shown on Hadiths tab)
                if (_c.tab == 0) ...[
                  _buildSearchBar(),
                  _buildBooksFilter(),
                  _buildCategoriesFilter(),
                  if (_c.lastReadNumber != null && _c.lastReadBookName != null)
                    _buildCompactResume(),
                ],

                // Body content
                Expanded(
                  child: _c.tab == 0 ? _buildHadithList() : _buildFavList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _kGoldLight, size: 18),
        onPressed: () => Navigator.pop(context),
        tooltip: 'رجوع',
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'الأحاديث النبوية',
            style: TextStyle(
              color: _kGoldLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_c.tab == 0)
            Text(
              '${_c.selectedSource} • ${_c.selectedCategory}',
              style: TextStyle(
                color: _kGold.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: _kGold, size: 22),
          onPressed: () => _c.load(reset: true),
          tooltip: 'تحديث الأحاديث',
        ),
      ],
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          // All Hadiths Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _c.setTab(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _c.tab == 0
                      ? _kGold.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _c.tab == 0
                        ? _kGold.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: _c.tab == 0 ? _kGoldLight : _kMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'جميع الأحاديث',
                      style: TextStyle(
                        color: _c.tab == 0 ? _kGoldLight : _kMuted,
                        fontSize: 12.5,
                        fontWeight: _c.tab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Favorites Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _c.setTab(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _c.tab == 1
                      ? _kGold.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _c.tab == 1
                        ? _kGold.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: _c.tab == 1 ? _kGoldLight : _kMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _c.favNums.isEmpty
                          ? 'المفضلة'
                          : 'المفضلة (${_c.favNums.length})',
                      style: TextStyle(
                        color: _c.tab == 1 ? _kGoldLight : _kMuted,
                        fontSize: 12.5,
                        fontWeight: _c.tab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder),
        ),
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(color: _kText, fontSize: 13.5),
          cursorColor: _kGold,
          onChanged: _c.search,
          decoration: InputDecoration(
            prefixIcon:
                Icon(Icons.search_rounded, color: _kGold, size: 18),
            hintText: 'ابحث في متن الحديث أو الراوي...',
            hintStyle: TextStyle(
                color: _kMuted.withValues(alpha: 0.7), fontSize: 12.5),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: _kMuted, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      _c.search('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildBooksFilter() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: HadithCatalog.sources.length,
        itemBuilder: (context, index) {
          final src = HadithCatalog.sources[index];
          final selected = _c.selectedSource == src;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(src),
              labelStyle: TextStyle(
                color: selected ? _kBg : _kText,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11.5,
              ),
              selected: selected,
              selectedColor: _kGold,
              backgroundColor: _kCard,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? _kGold
                      : _kCardBorder,
                  width: 1,
                ),
              ),
              onSelected: (value) {
                if (value) _c.setSource(src);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: HadithCatalog.categories.length,
        itemBuilder: (context, index) {
          final cat = HadithCatalog.categories[index];
          final selected = _c.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(cat),
              labelStyle: TextStyle(
                color: selected ? _kGoldLight : _kMuted,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10.5,
              ),
              selected: selected,
              selectedColor: _kGold.withValues(alpha: 0.15),
              backgroundColor: Colors.transparent,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selected
                      ? _kGold.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              onSelected: (value) {
                if (value) _c.setCategory(cat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactResume() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: InkWell(
        onTap: _resume,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _kGold.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline_rounded,
                  color: _kGold, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'متابعة القراءة: حديث #${_c.lastReadNumber} في ${_c.lastReadBookName}',
                  style: TextStyle(
                    color: _kGoldLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kGold, size: 11),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHadithList() {
    if (_c.loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }

    if (_c.error != null) {
      return _buildError();
    }

    if (_c.filtered.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: _kGold,
      backgroundColor: _kCard,
      onRefresh: () => _c.load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: _c.filtered.length + (_c.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _c.filtered.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                ),
              ),
            );
          }

          final h = _c.filtered[index];
          return HadithCard(
            hadith: h,
            isFav: _c.favNums.contains(h.number),
            onToggle: _c.toggleFav,
            onTap: () => _openDetails(_c.filtered, index),
          );
        },
      ),
    );
  }

  Widget _buildFavList() {
    final list = _c.favList;
    if (list.isEmpty) {
      return const _FavEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final h = list[index];
        return Dismissible(
          key: ValueKey(h.number),
          direction: DismissDirection.startToEnd,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
          ),
          onDismissed: (_) => _c.toggleFav(h.number),
          child: HadithCard(
            hadith: h,
            isFav: true,
            onToggle: _c.toggleFav,
            onTap: () => _openDetails(list, index),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: _kMuted, size: 48),
            SizedBox(height: 12),
            Text(
              _c.error ?? 'تعذر تحميل الأحاديث',
              style: TextStyle(color: _kMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: _kBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => _c.load(reset: true),
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('إعادة المحاولة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: _kMuted, size: 46),
          SizedBox(height: 10),
          Text(
            'لم يتم العثور على أحاديث مطابقة',
            style: TextStyle(
                color: _kMuted.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FavEmptyState extends StatelessWidget {
  const _FavEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _kCard,
                shape: BoxShape.circle,
                border: Border.all(color: _kGoldDim, width: 1.2),
              ),
              child: Icon(Icons.bookmark_outline_rounded,
                  color: _kGold, size: 32),
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد أحاديث في المفضلة',
              style: TextStyle(
                  color: _kText, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'اضغط على علامة الحفظ في أي حديث للرجوع إليه لاحقاً',
              style: TextStyle(
                  color: _kMuted.withValues(alpha: 0.8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


typedef HadithPage = HadithScreen;
