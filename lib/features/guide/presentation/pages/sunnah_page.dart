import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/guide/data/models/sunnah_model.dart';
import 'package:rafiki_app/features/guide/data/datasources/sunnah_data.dart';

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

class SunnahPage extends StatefulWidget {
  const SunnahPage({super.key});

  @override
  State<SunnahPage> createState() => _SunnahPageState();
}

class _SunnahPageState extends State<SunnahPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;

  // Filter mode: 0 = all/category, 1 = completed today, 2 = favorites
  int _filterMode = 0;

  Set<String> _completedToday = {};
  Set<String> _favorites = {};

  String get _todayKey {
    final now = DateTime.now();
    return "sunan_done_${now.year}_${now.month}_${now.day}";
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
      });
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedList = prefs.getStringList(_todayKey) ?? [];
      final favList = prefs.getStringList("sunan_favorites_v1") ?? [];
      if (mounted) {
        setState(() {
          _completedToday = completedList.toSet();
          _favorites = favList.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleCompleted(String sunnahId) async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_completedToday.contains(sunnahId)) {
        _completedToday.remove(sunnahId);
      } else {
        _completedToday.add(sunnahId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_todayKey, _completedToday.toList());
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String sunnahId) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(sunnahId)) {
        _favorites.remove(sunnahId);
      } else {
        _favorites.add(sunnahId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("sunan_favorites_v1", _favorites.toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SunnahItem> get _filteredSunan {
    List<SunnahItem> list = allSunan;

    if (_filterMode == 1) {
      list = list.where((s) => _completedToday.contains(s.id)).toList();
    } else if (_filterMode == 2) {
      list = list.where((s) => _favorites.contains(s.id)).toList();
    } else {
      if (_selectedCategoryIndex > 0 &&
          _selectedCategoryIndex < sunnahCategories.length) {
        final cat = sunnahCategories[_selectedCategoryIndex].label;
        list = list.where((s) => s.category == cat).toList();
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.hadith.toLowerCase().contains(q) ||
            s.fadl.toLowerCase().contains(q) ||
            s.practicalTip.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredSunan;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Top Tab Pills (الكل / طبقتها اليوم / المفضلة)
            _buildTabPills(),

            // Search bar
            _buildSearchBar(),

            // Category filter chips (when in 'all' mode)
            if (_filterMode == 0) _buildCategoryRow(),

            // Sunan List
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final isDone = _completedToday.contains(item.id);
                        final isFav = _favorites.contains(item.id);
                        return _buildSunnahCard(item, isDone, isFav);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _kGoldLight, size: 18),
        onPressed: () => Navigator.pop(context),
        tooltip: 'رجوع',
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'سنن المصطفى ﷺ',
            style: TextStyle(
              color: _kGoldLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'طبّقت اليوم ${_completedToday.length} من ${allSunan.length} سنّة',
            style: TextStyle(
              color: _kGold.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
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
          _buildTabItem(0, 'جميع السنن', Icons.menu_book_rounded),
          _buildTabItem(
              1,
              _completedToday.isEmpty
                  ? 'طبّقتها اليوم'
                  : 'طبّقتها (${_completedToday.length})',
              Icons.check_circle_outline_rounded),
          _buildTabItem(
              2,
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
                size: 14,
                color: isSelected ? _kGoldLight : _kMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _kGoldLight : _kMuted,
                  fontSize: 11.5,
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
          style: const TextStyle(color: _kText, fontSize: 13.5),
          cursorColor: _kGold,
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.search_rounded, color: _kGold, size: 18),
            hintText: 'ابحث في سنن النبي ﷺ وهديه...',
            hintStyle: TextStyle(
                color: _kMuted.withValues(alpha: 0.7), fontSize: 12.5),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
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
        itemCount: sunnahCategories.length,
        itemBuilder: (context, index) {
          final cat = sunnahCategories[index];
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
                  const SizedBox(width: 4),
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

  Widget _buildSunnahCard(SunnahItem item, bool isDone, bool isFav) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
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
            // Top Bar: Icon, Title, Badge & Favorite
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGold.withValues(alpha: 0.12),
                    border: Border.all(
                        color: _kGold.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Center(
                    child: Icon(item.icon, color: _kGoldLight, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: _kGoldLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.badge.isNotEmpty)
                        Text(
                          item.badge,
                          style: TextStyle(
                            color: _kGold.withValues(alpha: 0.7),
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
                  onPressed: () => _toggleFavorite(item.id),
                  tooltip: 'حفظ في المفضلة',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              item.description,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: _kText.withValues(alpha: 0.9),
                fontSize: 13.5,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 10),

            // Hadith Box
            if (item.hadith.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    right: BorderSide(
                        color: _kGold.withValues(alpha: 0.5), width: 2.5),
                  ),
                ),
                child: Text(
                  item.hadith,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: _kGoldLight,
                    fontSize: 13.5,
                    height: 1.75,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Virtue (الفضل)
            if (item.fadl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star_outline_rounded,
                      color: _kGold, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.fadl,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: _kMuted.withValues(alpha: 0.95),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Bottom Actions Bar
            Row(
              children: [
                // Toggle "طبقتها اليوم" Button
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleCompleted(item.id),
                    borderRadius: BorderRadius.circular(25),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDone
                            ? _kEmerald.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isDone
                              ? _kEmerald
                              : _kCardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isDone ? _kEmerald : _kMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDone ? 'طبّقتها اليوم ✓' : 'طبّقتها اليوم',
                            style: TextStyle(
                              color: isDone ? _kEmerald : _kMuted,
                              fontSize: 12,
                              fontWeight: isDone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Copy
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: _kMuted, size: 17),
                  tooltip: 'نسخ السنة',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          '${item.title}\n${item.description}\n\n${item.hadith}\n\nالفضل: ${item.fadl}\nالمصدر: ${item.source}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم نسخ السنة النبوية بنجاح ✨',
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
                  icon: const Icon(Icons.share_rounded, color: _kMuted, size: 17),
                  tooltip: 'مشاركة',
                  onPressed: () {
                    Share.share(
                      '✨ ${item.title}\n${item.description}\n\n${item.hadith}\n\nالفضل: ${item.fadl}\nالمصدر: ${item.source}\n\nتمت المشاركة من تطبيق رفيقي',
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
          const Icon(Icons.search_off_rounded, color: _kMuted, size: 46),
          const SizedBox(height: 10),
          Text(
            _filterMode == 1
                ? 'لم تسجل أي سنّة مطبقة اليوم بعد'
                : (_filterMode == 2
                    ? 'لا توجد سنن محفوظة في المفضلة'
                    : 'لم يتم العثور على سنّة مطابقة'),
            style: TextStyle(
                color: _kMuted.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
