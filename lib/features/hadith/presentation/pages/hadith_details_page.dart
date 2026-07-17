import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/presentation/widgets/hadith_widgets.dart';

// Theme Constants
const _kBg      = Color(0xFF070D1A);
const _kCard    = Color(0xFF131F33);
const _kGold    = Color(0xFFD4A853);
const _kTeal    = Color(0xFF1A7F7A);
const _kText    = Color(0xFFEEE8D8);
const _kMuted   = Color(0xFF8A9BB0);

class HadithDetailsPage extends StatefulWidget {
  final List<HadithModel>          list;
  final int                        index;
  final Set<int>                   favNums;
  final Future<void> Function(int) onToggle;
  final Future<void> Function(HadithModel) onSaveLastRead;

  const HadithDetailsPage({
    super.key,
    required this.list,
    required this.index,
    required this.favNums,
    required this.onToggle,
    required this.onSaveLastRead,
  });

  @override
  State<HadithDetailsPage> createState() => _HadithDetailsPageState();
}

class _HadithDetailsPageState extends State<HadithDetailsPage> {
  late final PageController _controller;
  late int      _current;
  late Set<int> _localFav; // local copy → instant UI update
  bool          _showEnglish = true;
  double        _arabicFontSize = 18.0;

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
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: _kMuted, size: 20),
            onPressed: () {
              if (_arabicFontSize > 15) {
                setState(() => _arabicFontSize -= 2.0);
              }
            },
            tooltip: 'تصغير الخط',
          ),
          Center(
            child: Text(
              '${_arabicFontSize.toInt()}',
              style: const TextStyle(color: _kGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: _kMuted, size: 20),
            onPressed: () {
              if (_arabicFontSize < 34) {
                setState(() => _arabicFontSize += 2.0);
              }
            },
            tooltip: 'تكبير الخط',
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              _showEnglish ? Icons.translate_rounded : Icons.g_translate_rounded,
              color: _showEnglish ? _kGold : _kMuted,
            ),
            onPressed: () {
              setState(() {
                _showEnglish = !_showEnglish;
              });
            },
            tooltip: 'إظهار/إخفاء الترجمة',
          ),
          BookmarkButton(
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
              onPageChanged: (i) {
                setState(() => _current = i);
                widget.onSaveLastRead(widget.list[i]);
              },
              itemCount:     widget.list.length,
              itemBuilder:   (_, i) => DetailPage(
                hadith:   widget.list[i],
                isFav:    _localFav.contains(widget.list[i].number),
                onToggle: _toggle,
                showEnglish: _showEnglish,
                fontSize: _arabicFontSize,
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

class DetailPage extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;
  final bool                       showEnglish;
  final double                     fontSize;

  const DetailPage({
    super.key,
    required this.hadith,
    required this.isFav,
    required this.onToggle,
    required this.showEnglish,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasRichEnglish = hadith.english.isNotEmpty;
    final hasIndonesian = hadith.id.isNotEmpty;
    
    String transText = '';
    String transLabel = '';
    
    if (hasRichEnglish) {
      transText = hadith.english;
      transLabel = 'English Translation';
    } else if (hasIndonesian) {
      transText = hadith.id;
      transLabel = 'الترجمة المتاحة للحديث (Indonesian)';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFav ? _kGold.withOpacity(0.4) : const Color(0xFF1E2D45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
                    Text(hadith.source.isNotEmpty ? hadith.source : 'موسوعة الأحاديث',
                        style: const TextStyle(color: _kMuted, fontSize: 12)),
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
            // Arabic and English Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hadith.grade.isNotEmpty) ...[
                          _pillTag(hadith.grade, _kTeal),
                          const SizedBox(width: 8),
                        ],
                        if (hadith.category.isNotEmpty)
                          _pillTag(hadith.category, _kGold),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Narrator section
                    if (hadith.narrator.isNotEmpty) ...[
                      Text(
                        'رواه ${hadith.narrator} رضي الله عنه:',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kGold,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Arabic Hadith Text (Main)
                    Text(
                      hadith.arab,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kText,
                        fontSize: fontSize,
                        height: 1.95,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // English/Indonesian Translation (Secondary)
                    if (showEnglish && transText.isNotEmpty) ...[
                      const Divider(color: Color(0xFF1E2D45), thickness: 1),
                      const SizedBox(height: 12),
                      Text(
                        transLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kGold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kBg.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E2D45).withOpacity(0.5)),
                        ),
                        child: Text(
                          transText,
                          textDirection: hasRichEnglish ? TextDirection.ltr : TextDirection.rtl,
                          textAlign: hasRichEnglish ? TextAlign.left : TextAlign.center,
                          style: TextStyle(
                            color: _kMuted.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.55,
                            fontStyle: hasRichEnglish ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Card Footer Actions (Copy & Share)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C1624),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: _kGold, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الحديث النبوي الشريف إلى الحافظة.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'نسخ الحديث',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: _kGold, size: 20),
                    onPressed: () {
                      Share.share(
                        '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      );
                    },
                    tooltip: 'مشاركة الحديث',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Route slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder:        (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 320),
);
