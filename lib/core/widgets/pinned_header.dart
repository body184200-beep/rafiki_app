import 'package:flutter/material.dart';

/// Fixed-height pinned sliver header used by catalog tabs.
class PinnedHeader extends SliverPersistentHeaderDelegate {
  PinnedHeader({
    required this.child,
    required this.height,
    this.background = const Color(0xFF080C12),
  });

  final Widget child;
  final double height;
  final Color background;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant PinnedHeader oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.background != background;
  }
}
