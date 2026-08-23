import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';

// Theme Constants
const _kCard    = Color(0xFF131F33);
const _kGold    = Color(0xFFD4A853);
const _kTeal    = Color(0xFF1A7F7A);
const _kText    = Color(0xFFEEE8D8);
const _kMuted   = Color(0xFF8A9BB0);

class HadithCard extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;
  final VoidCallback               onTap;

  const HadithCard({
    super.key,
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
              width: 48,
              decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Tag & Source
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hadith.category.isNotEmpty ? hadith.category : 'عام',
                            style: const TextStyle(color: _kTeal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          hadith.source.isNotEmpty ? hadith.source : 'موسوعة الأحاديث',
                          style: const TextStyle(color: _kMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Arabic Text
                    Text(
                      hadith.arab,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 15,
                        height: 1.75,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Narrator Footer
                    if (hadith.narrator.isNotEmpty)
                      Text(
                        'الراوي: ${hadith.narrator} • ${hadith.grade}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _kMuted, fontSize: 10.5),
                      )
                    else
                      Text(
                        hadith.grade.isNotEmpty ? hadith.grade : 'صحيح',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _kMuted, fontSize: 10.5),
                      ),
                  ],
                ),
              ),
            ),
            // Actions Column (Bookmark, Copy, Share)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: Column(
                children: [
                  BookmarkButton(number: hadith.number, isFav: isFav, onToggle: onToggle),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: _kMuted, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ نص الحديث الشريف.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: _kMuted, size: 16),
                    onPressed: () {
                      Share.share(
                        '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkButton extends StatefulWidget {
  final int                        number;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;

  const BookmarkButton({
    super.key,
    required this.number,
    required this.isFav,
    required this.onToggle,
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton>
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

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
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
