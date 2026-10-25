import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/prophet_story_model.dart';

class Anbiaa extends StatefulWidget {
  const Anbiaa({super.key});

  @override
  State<Anbiaa> createState() => _AnbiaaState();
}

class _AnbiaaState extends State<Anbiaa> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  // ألوان الثيم الإسلامي الفاخر
  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);
  static const Color kGoldDim = Color(0xFF8a6f30);
  static const Color kInk = Color(0xFF0e0c18);
  static const Color kParchment = Color(0xFFf5edd6);

  List<ProphetStory> _allProphets = [];
  List<ProphetStory> _filteredProphets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();

    _loadStories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadStories() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/prophets_stories.json');
      final List<dynamic> data = json.decode(jsonStr);
      final list = data.map((item) => ProphetStory.fromJson(item as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _allProphets = list;
          _filteredProphets = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading prophets stories: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProphets = _allProphets;
      } else {
        _filteredProphets = _allProphets.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.title.toLowerCase().contains(query) ||
              p.summary.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _openStory(ProphetStory prophet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StoryReaderSheet(prophet: prophet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kInk,
      body: SafeArea(
        child: FadeTransition(
          opacity: _headerFade,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearch(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع: ${_allProphets.length} نبياً ورسولاً',
                      style: TextStyle(
                        color: kGoldDim.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'قصص كاملة ومفصلة بالآيات والعبر',
                      style: TextStyle(
                        color: kGold.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kGold),
                      )
                    : _filteredProphets.isEmpty
                        ? _buildEmpty()
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.74,
                            ),
                            itemCount: _filteredProphets.length,
                            itemBuilder: (context, index) {
                              return _ProphetCard(
                                prophet: _filteredProphets[index],
                                index: index,
                                onTap: () => _openStory(_filteredProphets[index]),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kGold.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: kGold.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: kGoldLight,
                    size: 16,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: [Colors.transparent, kGoldDim]),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child:
                        Text('✦', style: TextStyle(color: kGoldDim, fontSize: 14)),
                  ),
                  Container(
                    width: 40,
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: [kGoldDim, Colors.transparent]),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'قِصَصُ الأَنْبِيَاء',
            style: TextStyle(
              color: kGoldLight,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFamily: 'serif',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'قصص ورسائل أولي العزم والأنبياء كاملة وموثقة',
            style: TextStyle(
              color: kGold.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: kGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: kGold.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(color: kParchment, fontSize: 14),
          cursorColor: kGold,
          decoration: InputDecoration(
            hintText: 'ابحث عن اسم نبي، لقب، أو حدث...',
            hintStyle:
                TextStyle(color: kGold.withValues(alpha: 0.35), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: kGoldDim, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: kGoldDim, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'لم يُعثر على نبي مطابق للبحث',
            style: TextStyle(color: kGold.withValues(alpha: 0.5), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROPHET CARD WIDGET
// ─────────────────────────────────────────
class _ProphetCard extends StatefulWidget {
  final ProphetStory prophet;
  final int index;
  final VoidCallback onTap;

  const _ProphetCard({
    required this.prophet,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ProphetCard> createState() => _ProphetCardState();
}

class _ProphetCardState extends State<_ProphetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeSlide;
  bool _pressed = false;

  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeSlide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 35 * (widget.index % 12)), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(_fadeSlide),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: kGold.withValues(alpha: 0.05),
                border: Border.all(
                    color: kGold.withValues(alpha: 0.18), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              kGold.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kGold.withValues(alpha: 0.1),
                                  border: Border.all(
                                      color: kGold.withValues(alpha: 0.25),
                                      width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.prophet.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.prophet.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: kGoldLight,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.prophet.period.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: kGold.withValues(alpha: 0.08),
                                  ),
                                  child: Text(
                                    widget.prophet.period,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: kGold.withValues(alpha: 0.65),
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Text(
                                widget.prophet.summary,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: kGold.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: kGold.withValues(alpha: 0.3),
                                  width: 0.8),
                            ),
                            child: Center(
                              child: Text(
                                'اقرأ القصة الكاملة',
                                style: TextStyle(
                                  color: kGoldLight.withValues(alpha: 0.9),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────
// RICH STORY READER SHEET
// ─────────────────────────────────────────
class _StoryReaderSheet extends StatefulWidget {
  final ProphetStory prophet;

  const _StoryReaderSheet({required this.prophet});

  @override
  State<_StoryReaderSheet> createState() => _StoryReaderSheetState();
}

class _StoryReaderSheetState extends State<_StoryReaderSheet> {
  double _fontSize = 15.5;

  static const Color kGold = Color(0xFFc9a84c);
  static const Color kGoldLight = Color(0xFFe8cc7a);
  static const Color kGoldDim = Color(0xFF8a6f30);
  static const Color kInkMid = Color(0xFF141122);
  static const Color kParchment = Color(0xFFf5edd6);

  void _copyStory() {
    Clipboard.setData(ClipboardData(
      text: '${widget.prophet.name}\n${widget.prophet.title}\n\n${widget.prophet.fullStory}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ قصة ${widget.prophet.name} إلى الحافظة بنجاح ✨',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: kGoldDim,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareStory() {
    Share.share(
      '📖 قصة ${widget.prophet.name} - ${widget.prophet.title}\n\n${widget.prophet.fullStory}\n\nتمت المشاركة من تطبيق رفيقي',
      subject: 'قصة ${widget.prophet.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: kInkMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: kGold.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Header bar with actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGold.withValues(alpha: 0.12),
                      border: Border.all(
                          color: kGold.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        widget.prophet.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.prophet.name,
                          style: const TextStyle(
                            color: kGoldLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.prophet.title.isNotEmpty)
                          Text(
                            widget.prophet.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kGold.withValues(alpha: 0.7),
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Font size controls
                  IconButton(
                    icon: const Icon(Icons.text_decrease_rounded,
                        color: kGoldLight, size: 20),
                    tooltip: 'تصغير الخط',
                    onPressed: () {
                      if (_fontSize > 13) setState(() => _fontSize -= 1.5);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_increase_rounded,
                        color: kGoldLight, size: 20),
                    tooltip: 'تكبير الخط',
                    onPressed: () {
                      if (_fontSize < 24) setState(() => _fontSize += 1.5);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: kGoldLight, size: 20),
                    tooltip: 'نسخ القصة',
                    onPressed: _copyStory,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: kGoldLight, size: 20),
                    tooltip: 'مشاركة',
                    onPressed: _shareStory,
                  ),
                ],
              ),
            ),

            // Metadata Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kGold.withValues(alpha: 0.1)),
                  bottom: BorderSide(color: kGold.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  if (widget.prophet.period.isNotEmpty)
                    _buildMetaChip(Icons.access_time_rounded, widget.prophet.period),
                  const SizedBox(width: 8),
                  if (widget.prophet.quranMentions.isNotEmpty)
                    _buildMetaChip(
                        Icons.menu_book_rounded, widget.prophet.quranMentions),
                ],
              ),
            ),

            // Story Body with Formatted Chapters
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _buildStoryContent(widget.prophet.fullStory),
              ),
            ),

            // Bottom Close Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kGold.withValues(alpha: 0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: kGold.withValues(alpha: 0.12),
                    foregroundColor: kGoldLight,
                    side: BorderSide(color: kGold.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'إغلاق القصة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kGoldLight),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: kGoldLight.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('### ')) {
        final title = line.substring(4);
        final isLessons = title.contains('الدروس المستفادة') || title.contains('العبر');
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLessons
                    ? [
                        const Color(0xFF1E3A2F),
                        kInkMid,
                      ]
                    : [
                        kGold.withValues(alpha: 0.18),
                        kGold.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLessons
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.4)
                    : kGold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLessons ? Icons.lightbulb_rounded : Icons.bookmark_added_rounded,
                  color: isLessons ? const Color(0xFF2ECC71) : kGoldLight,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLessons ? const Color(0xFF2ECC71) : kGoldLight,
                      fontSize: _fontSize + 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.contains('﴿') && line.contains('﴾')) {
        // Quranic Verse styled block
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                right: BorderSide(color: kGoldLight, width: 3),
              ),
            ),
            child: Text(
              line,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: kGoldLight,
                fontSize: _fontSize + 1.5,
                height: 2.1,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✦ ', style: TextStyle(color: kGoldLight, fontSize: _fontSize)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: kParchment.withValues(alpha: 0.9),
                      fontSize: _fontSize,
                      height: 1.85,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Text(
            line,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: kParchment.withValues(alpha: 0.88),
              fontSize: _fontSize,
              height: 2.0,
              fontFamily: 'serif',
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}
