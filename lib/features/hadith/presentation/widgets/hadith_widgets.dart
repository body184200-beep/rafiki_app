import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';

// Unified Calming Islamic Theme
const _kCard = Color(0xFF111827);
const _kCardBorder = Color(0xFF1F293D);
const _kGold = Color(0xFFC9A84C);
const _kGoldLight = Color(0xFFE8CC7A);
const _kText = Color(0xFFF3EEDD);
const _kMuted = Color(0xFF8B9CB2);

class HadithCard extends StatelessWidget {
  final HadithModel hadith;
  final bool isFav;
  final Future<void> Function(int) onToggle;
  final VoidCallback onTap;

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFav
                ? _kGold.withValues(alpha: 0.45)
                : _kCardBorder,
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
              // Top Bar: Meta badges & Bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badges: Book, number, grade
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Source & Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _kGold.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${hadith.source.isNotEmpty ? hadith.source : "حديث"} • #${hadith.number}',
                            style: const TextStyle(
                              color: _kGoldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Category tag if specific
                        if (hadith.category.isNotEmpty &&
                            hadith.category != 'عام' &&
                            hadith.category != 'الكل')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hadith.category,
                              style: TextStyle(
                                color: _kMuted.withValues(alpha: 0.9),
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        // Grade
                        if (hadith.grade.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hadith.grade,
                              style: const TextStyle(
                                color: Color(0xFF2ECC71),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bookmark Button
                  BookmarkButton(
                    number: hadith.number,
                    isFav: isFav,
                    onToggle: onToggle,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Full-width Arabic text
              Text(
                hadith.arab,
                textDirection: TextDirection.rtl,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 15.5,
                  height: 1.85,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'serif',
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Bar: Narrator on right, actions on left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Narrator
                  Expanded(
                    child: Text(
                      hadith.narrator.isNotEmpty
                          ? 'الراوي: ${hadith.narrator}'
                          : (hadith.source.isNotEmpty ? hadith.source : ''),
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  // Quick Action Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Copy
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                            text:
                                '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم نسخ نص الحديث الشريف بنجاح ✨',
                                textDirection: TextDirection.rtl,
                              ),
                              backgroundColor: Color(0xFF1E2D45),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.copy_rounded,
                              color: _kMuted, size: 17),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Share
                      InkWell(
                        onTap: () {
                          Share.share(
                            '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}\n\nتمت المشاركة من تطبيق رفيقي',
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.share_rounded,
                              color: _kMuted, size: 17),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Open details arrow
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'كامل',
                                style: TextStyle(
                                  color: _kGoldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_back_ios_rounded,
                                color: _kGoldLight,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookmarkButton extends StatefulWidget {
  final int number;
  final bool isFav;
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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 1.35)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.forward();
    await widget.onToggle(widget.number);
    if (mounted) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: InkWell(
        onTap: _tap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            widget.isFav
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: widget.isFav ? _kGold : _kMuted.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
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
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: _kCard.withValues(alpha: _anim.value + 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
        ),
      ),
    );
  }
}
