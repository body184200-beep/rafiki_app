import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/guide/data/datasources/reciters_data.dart';
import 'package:rafiki_app/features/guide/data/models/reciter_model.dart';

class RecitersPage extends StatefulWidget {
  const RecitersPage({super.key});

  @override
  State<RecitersPage> createState() => _RecitersPageState();
}

class _RecitersPageState extends State<RecitersPage> {
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _expandedKeys = {};

  static const List<String> _categories = [
    'الكل',
    'الصحابة الكرام',
    'أئمة القراءات العشر',
    'المدرسة المصرية الذهبية',
    'قراء الحرمين',
    'قراء العصر الحديث',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Reciter> get _filteredReciters {
    List<Reciter> base;
    if (_selectedCategory == 'الكل') {
      base = kCategories.values.expand((list) => list).toList();
    } else {
      base = kCategories[_selectedCategory] ?? [];
    }

    if (_searchQuery.trim().isEmpty) {
      return base;
    }

    final q = _searchQuery.trim().toLowerCase();
    return base.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.country.toLowerCase().contains(q) ||
          r.specialty.toLowerCase().contains(q) ||
          r.story.toLowerCase().contains(q);
    }).toList();
  }

  void _toggleExpand(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final list = _filteredReciters;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isLight ? const Color(0xFFF8F6F0) : const Color(0xFF080C16),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              _buildHeader(),

              SizedBox(height: 6),

              // ── Search Bar ──────────────────────────────────────────
              _buildSearchBar(),

              SizedBox(height: 8),

              // ── Category Chips ──────────────────────────────────────
              _buildCategoryChips(),

              SizedBox(height: 10),

              // ── Reciters List ───────────────────────────────────────
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 4, bottom: 24),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return _buildReciterCard(list[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 40),
          Column(
            children: [
              Text(
                'مجتمع القرّاء',
                style: TextStyle(
                  color: ThemeProvider.instance.isLight ? const Color(0xFF111827) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'أعلام التلاوة وأصوات القرآن عبر التاريخ',
                style: TextStyle(
                  color: Color(0xFF8DA3C4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1728),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B2A45), width: 0.8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF8DA3C4),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1728),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1B2A45), width: 0.8),
        ),
        child: TextField(
          controller: _searchCtrl,
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'ابحث عن قارئ أو بلد أو تخصص...',
            hintStyle: TextStyle(color: Color(0xFF5A718F), fontSize: 13),
            prefixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Color(0xFF8DA3C4), size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            suffixIcon: Icon(Icons.search_rounded, color: Color(0xFF3CD2A2), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory && _searchQuery.isEmpty;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat;
                _searchQuery = '';
                _searchCtrl.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3CD2A2) : const Color(0xFF0F1728),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3CD2A2) : const Color(0xFF1B2A45),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF070B14) : const Color(0xFFCAD5E2),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReciterCard(Reciter r) {
    final isExpanded = _expandedKeys.contains(r.name);
    final initial = r.name.trim().isNotEmpty ? r.name.trim().characters.first : 'ق';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: ThemeProvider.instance.isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ThemeProvider.instance.isLight ? const Color(0xFFE5E7EB) : (isExpanded ? const Color(0xFF3CD2A2).withValues(alpha: 0.5) : const Color(0xFF1B2A45)),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Tile
          InkWell(
            onTap: () => _toggleExpand(r.name),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF142436),
                      border: Border.all(color: const Color(0xFF203754), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Color(0xFF3CD2A2),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${r.country} • ${r.specialty}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF8DA3C4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  // Expand Chevron Icon
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? const Color(0xFF3CD2A2) : const Color(0xFF5A718F),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details
          if (isExpanded) ...[
            Container(
              height: 0.6,
              color: const Color(0xFF1B2A45),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Famous Quote
                  if (r.famousQuote.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF142436),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3CD2A2).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded, color: Color(0xFF3CD2A2), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '«${r.famousQuote}»',
                              style: TextStyle(
                                color: Color(0xFFD4E2F4),
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Biography Story
                  Text(
                    'سيرة القارئ:',
                    style: TextStyle(
                      color: Color(0xFF3CD2A2),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    r.story,
                    style: TextStyle(
                      color: Color(0xFFCAD5E2),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),

                  // Highlights Chips
                  if (r.highlights.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(
                      'أبرز المحطات والصفات:',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.highlights.map((h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162035),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF243450)),
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 11.5,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Color(0xFF5A718F), size: 48),
            SizedBox(height: 12),
            Text(
              'لا توجد نتائج مطابقة لـ "$_searchQuery"',
              style: TextStyle(color: Color(0xFF8DA3C4), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
