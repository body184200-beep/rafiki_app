import 'dart:ui';
import 'package:flutter/material.dart';

class DoneChip extends StatelessWidget {
  const DoneChip({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff2EB88A).withValues(alpha: 0.18),
        border: Border.all(color: const Color(0xff2EB88A).withValues(alpha: 0.38)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: Color(0xff5EFACC), size: 13),
          SizedBox(width: 4),
          Text('مكتمل',
              style: TextStyle(
                color: Color(0xff5EFACC), fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class IndexBadge extends StatelessWidget {
  final int index;
  const IndexBadge({super.key, required this.index});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Color(0xff5A6E7E), fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class TapButton extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const TapButton({super.key, required this.done, required this.onTap});

  static const Color _teal    = Color(0xff2EB88A);
  static const Color _tealDim = Color(0xff0D6E52);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done
              ? null
              : const LinearGradient(colors: [_tealDim, _teal]),
          color: done ? Colors.white.withValues(alpha: 0.04) : null,
          boxShadow: done
              ? []
              : [
            BoxShadow(
              color: _teal.withValues(alpha: 0.4),
              blurRadius: 16, spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          done ? Icons.check_rounded : Icons.add_rounded,
          color: done ? _teal.withValues(alpha: 0.5) : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class AzkarCard extends StatefulWidget {
  final String text;
  final String keyId;
  final int    max;
  final int    current;
  final bool   done;
  final VoidCallback onTap;
  final VoidCallback? onSetReminder;
  final int    index;

  const AzkarCard({
    super.key,
    required this.text,    required this.keyId,
    required this.max,     required this.current,
    required this.done,    required this.onTap,
    this.onSetReminder,
    required this.index,
  });

  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  static const Color _teal    = Color(0xff2EB88A);
  static const Color _tealLt  = Color(0xff5EFACC);
  static const Color _gold    = Color(0xffC9A84C);
  static const Color _text    = Color(0xffEDE8D8);
  static const Color _sub     = Color(0xff5A6E7E);

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.max > 0 ? widget.current / widget.max : 0.0;

    return ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
      ),
      child: GestureDetector(
        onTapDown:   (_) { if (!widget.done) _tapCtrl.reverse(from: 1); },
        onTapUp:     (_) { _tapCtrl.forward(); if (!widget.done) widget.onTap(); },
        onTapCancel: ()  { _tapCtrl.forward(); },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.done
                  ? [
                _teal.withValues(alpha: 0.12),
                _teal.withValues(alpha: 0.04),
              ]
                  : [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
            border: Border.all(
              color: widget.done
                  ? _teal.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.07),
              width: widget.done ? 1.5 : 1,
            ),
            boxShadow: widget.done
                ? [
              BoxShadow(
                color: _teal.withValues(alpha: 0.10),
                blurRadius: 20, offset: const Offset(0, 6),
              )
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.done
                            ? const DoneChip()
                            : IndexBadge(index: widget.index),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onSetReminder != null)
                              GestureDetector(
                                onTap: widget.onSetReminder,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _teal.withValues(alpha: 0.12),
                                    border: Border.all(
                                        color: _teal.withValues(alpha: 0.28)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_active_outlined,
                                          color: _tealLt, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'تذكير',
                                        style: TextStyle(
                                          color: _tealLt,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _gold.withValues(alpha: 0.09),
                                border: Border.all(
                                    color: _gold.withValues(alpha: 0.22)),
                              ),
                              child: Text(
                                widget.max == 1 ? 'مرة' : '${widget.max} مرة',
                                style: const TextStyle(
                                  color: _gold, fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      widget.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: widget.done
                            ? _text.withValues(alpha: 0.55)
                            : _text,
                        fontSize: 15.5,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        TapButton(done: widget.done, onTap: widget.onTap),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(pct * 100).toInt()}%',
                                    style: TextStyle(
                                      color: widget.done
                                          ? _tealLt.withValues(alpha: 0.7)
                                          : _teal.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${widget.current} / ${widget.max}',
                                    style: const TextStyle(
                                        color: _sub, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 5,
                                  backgroundColor:
                                  Colors.white.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation(
                                    widget.done ? _tealLt : _teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class AzkarList extends StatelessWidget {
  final List<Map<String, dynamic>>      azkar;
  final String                           type;
  final Map<String, Map<String, int>>   progress;
  final void Function(String, int)       onTap;
  final void Function(String text)?     onSetReminder;
  final AnimationController             entryCtrl;

  const AzkarList({
    super.key,
    required this.azkar,    required this.type,
    required this.progress, required this.onTap,
    this.onSetReminder,
    required this.entryCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: azkar.length,
      itemBuilder: (_, i) {
        final key  = '$type-$i';
        final max  = azkar[i]['count'] as int;
        final cur  = progress[key]?['current'] ?? 0;
        final done = cur >= max;

        final delay = (0.04 + i * 0.07).clamp(0.0, 0.82);
        final end   = (delay + 0.35).clamp(0.0, 1.0);
        final anim  = CurvedAnimation(
          parent: entryCtrl,
          curve: Interval(delay, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12), end: Offset.zero,
            ).animate(anim),
            child: AzkarCard(
              text: azkar[i]['text'] as String,
              keyId: key, max: max, current: cur, done: done,
              onTap: () => onTap(key, max),
              onSetReminder: onSetReminder != null
                  ? () => onSetReminder!(azkar[i]['text'] as String)
                  : null,
              index: i + 1,
            ),
          ),
        );
      },
    );
  }
}

class ProgressPill extends StatelessWidget {
  final String label;
  final int    done;
  final int    total;
  final Color  color;
  const ProgressPill({
    super.key,
    required this.label, required this.done,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text('$done/$total',
            style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const GlassButton({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class StyledDialog extends StatelessWidget {
  final String icon, title, body, buttonLabel;
  const StyledDialog({
    super.key,
    required this.icon,   required this.title,
    required this.body,   required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff08111E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xffEDE8D8), fontSize: 19,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 10),
          Text(body,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Color(0xff5A6E7E), height: 1.65, fontSize: 13,
              )),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2EB88A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class Blob extends StatelessWidget {
  final Color  color;
  final double size;
  const Blob({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6)],
    ),
  );
}
