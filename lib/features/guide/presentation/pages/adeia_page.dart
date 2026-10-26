import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/guide/data/models/dua_model.dart';
import 'package:rafiki_app/features/guide/data/datasources/adeia_data.dart';

// ─────────────────────────────────────────────────────────────
//  Unified Calming Islamic Palette
// ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0A0E17);
const Color _kCard = Color(0xFF111827);
const Color _kCardBorder = Color(0xFF1F293D);
const Color _kGold = Color(0xFFC9A84C);
const Color _kGoldLight = Color(0xFFE8CC7A);
const Color _kText = Color(0xFFF3EEDD);
const Color _kMuted = Color(0xFF8B9CB2);
const Color _kEmerald = Color(0xFF10B981);

class AdeiaPage extends StatefulWidget {
  const AdeiaPage({super.key});

  @override
  State<AdeiaPage> createState() => _AdeiaPageState();
}

class _AdeiaPageState extends State<AdeiaPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;

  // Filter mode: 0 = all/category, 1 = favorites
  int _filterMode = 0;

  // Font size scale: 16 (normal), 19 (large), 22 (extra large)
  double _duaFontSize = 17.5;

  Set<String> _favorites = {};
  // In-memory counter for tasbeeh on each dua: title -> count
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
      });
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList("adeia_favorites_v1") ?? [];
      if (mounted) {
        setState(() {
          _favorites = favList.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String duaTitle) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(duaTitle)) {
        _favorites.remove(duaTitle);
      } else {
        _favorites.add(duaTitle);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("adeia_favorites_v1", _favorites.toList());
    } catch (_) {}
  }

  void _incrementCount(String title, int maxRepeat) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = _counts[title] ?? 0;
      if (current < maxRepeat) {
        _counts[title] = current + 1;
      }
    });
  }

  void _resetCount(String title) {
    HapticFeedback.selectionClick();
    setState(() {
      _counts[title] = 0;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DuaData> get _filteredDuas {
    List<DuaData> list = allDuas;

    if (_filterMode == 1) {
      list = list.where((d) => _favorites.contains(d.title)).toList();
    } else {
      if (_selectedCategoryIndex > 0 &&
          _selectedCategoryIndex < duaCategories.length) {
        final cat = duaCategories[_selectedCategoryIndex].label;
        list = list.where((d) => d.category == cat).toList();
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.dua.toLowerCase().contains(q) ||
            d.fadl.toLowerCase().contains(q) ||
            d.source.toLowerCase().contains(q) ||
            d.when.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final list = _filteredDuas;
        return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Top Tab Pills (جميع الأدعية / المفضلة)
            _buildTabPills(),

            // Search bar
            _buildSearchBar(),

            // Category filter chips (when in 'all' mode)
            if (_filterMode == 0) _buildCategoryRow(),

            // Duas List
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final isFav = _favorites.contains(item.title);
                        final count = _counts[item.title] ?? 0;
                        return _buildDuaCard(item, isFav, count);
                      },
                    ),
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
      title: Text(
        'الأدعية والأذكار',
        style: TextStyle(
          color: _kGoldLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        // Font size controls
        IconButton(
          icon: Icon(Icons.text_decrease_rounded,
              color: _kGoldLight, size: 20),
          tooltip: 'تصغير الخط',
          onPressed: () {
            if (_duaFontSize > 14) {
              setState(() => _duaFontSize -= 1.5);
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.text_increase_rounded,
              color: _kGoldLight, size: 20),
          tooltip: 'تكبير الخط',
          onPressed: () {
            if (_duaFontSize < 25) {
              setState(() => _duaFontSize += 1.5);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabPills() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'جميع الأدعية', Icons.auto_stories_rounded),
          _buildTabItem(
              1,
              _favorites.isEmpty
                  ? 'المفضلة'
                  : 'المفضلة (${_favorites.length})',
              Icons.bookmark_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _filterMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? _kGold.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? _kGold.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? _kGoldLight : _kMuted,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _kGoldLight : _kMuted,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
          controller: _searchCtrl,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(color: _kText, fontSize: 13.5),
          cursorColor: _kGold,
          decoration: InputDecoration(
            prefixIcon:
                Icon(Icons.search_rounded, color: _kGold, size: 18),
            hintText: 'ابحث في نصوص الأدعية والأذكار...',
            hintStyle: TextStyle(
                color: _kMuted.withValues(alpha: 0.7), fontSize: 12.5),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: _kMuted, size: 16),
                    onPressed: () => _searchCtrl.clear(),
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

  Widget _buildCategoryRow() {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: duaCategories.length,
        itemBuilder: (context, index) {
          final cat = duaCategories[index];
          final selected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 13,
                      color: selected ? _kBg : _kMuted),
                  SizedBox(width: 4),
                  Text(cat.label),
                ],
              ),
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
                  color: selected ? _kGold : _kCardBorder,
                  width: 1,
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedCategoryIndex = index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDuaCard(DuaData item, bool isFav, int count) {
    final isCompleted = count >= item.repeat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? _kEmerald.withValues(alpha: 0.5)
              : (isFav ? _kGold.withValues(alpha: 0.45) : _kCardBorder),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Category, Title, Occasion & Favorite
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kGold.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: _kGoldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: _kText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.when.isNotEmpty)
                        Text(
                          item.when,
                          style: TextStyle(
                            color: _kMuted.withValues(alpha: 0.85),
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFav ? _kGold : _kMuted.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  onPressed: () => _toggleFavorite(item.title),
                  tooltip: 'حفظ في المفضلة',
                ),
              ],
            ),

            SizedBox(height: 10),

            // Dua Text Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  right: BorderSide(
                      color: _kGold.withValues(alpha: 0.5), width: 3),
                ),
              ),
              child: Text(
                item.dua,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _kGoldLight,
                  fontSize: _duaFontSize,
                  height: 2.05,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Virtue (الفضل) & Source
            if (item.fadl.isNotEmpty || item.source.isNotEmpty) ...[
              SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _kMuted, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.fadl}${item.source.isNotEmpty ? " • " + item.source : ""}',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: _kMuted.withValues(alpha: 0.95),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12),

            // Bottom Actions & Tasbeeh Counter Bar
            Row(
              children: [
                // Tasbeeh Button
                Expanded(
                  child: InkWell(
                    onTap: () => _incrementCount(item.title, item.repeat),
                    borderRadius: BorderRadius.circular(25),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? _kEmerald.withValues(alpha: 0.2)
                            : _kGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isCompleted
                              ? _kEmerald
                              : _kGold.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.touch_app_rounded,
                            color: isCompleted ? _kEmerald : _kGoldLight,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            isCompleted
                                ? 'اكتمل ($count/${item.repeat}) ✓'
                                : (item.repeat > 1
                                    ? 'تكرار ($count/${item.repeat})'
                                    : (count > 0 ? 'تمت القراءة ✓' : 'قرأتُه')),
                            style: TextStyle(
                              color: isCompleted ? _kEmerald : _kGoldLight,
                              fontSize: 12,
                              fontWeight: isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Reset button (if count > 0)
                if (count > 0) ...[
                  SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: _kMuted, size: 18),
                    tooltip: 'إعادة العداد',
                    onPressed: () => _resetCount(item.title),
                  ),
                ],

                SizedBox(width: 4),

                // Copy
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: _kMuted, size: 17),
                  tooltip: 'نسخ الدعاء',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          '${item.title}\n\n${item.dua}\n\nالفضل: ${item.fadl}\nالمصدر: ${item.source}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم نسخ الدعاء المبارك بنجاح ✨',
                          textDirection: TextDirection.rtl,
                        ),
                        backgroundColor: Color(0xFF1E2D45),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Share
                IconButton(
                  icon: Icon(Icons.share_rounded, color: _kMuted, size: 17),
                  tooltip: 'مشاركة',
                  onPressed: () {
                    Share.share(
                      '🤲 ${item.title}\n\n${item.dua}\n\nالفضل: ${item.fadl}\nالمصدر: ${item.source}\n\nتمت المشاركة من تطبيق رفيقي',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: _kMuted, size: 46),
          SizedBox(height: 10),
          Text(
            _filterMode == 1
                ? 'لا توجد أدعية محفوظة في المفضلة'
                : 'لم يتم العثور على دعاء أو ذكر مطابق',
            style: TextStyle(
                color: _kMuted.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
