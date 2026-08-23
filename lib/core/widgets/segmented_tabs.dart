import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i == index) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: index == i ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: index == i ? AppColors.bg : AppColors.goldLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
