import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.selectedColor = AppColors.gold,
    this.backgroundColor = AppColors.surface,
    this.unselectedLabel = AppColors.goldLight,
    this.selectedLabel,
    this.height = 44,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color selectedColor;
  final Color backgroundColor;
  final Color unselectedLabel;
  final Color? selectedLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final onSelectedColor = selectedLabel ?? AppColors.bg;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selected == item;
          return ChoiceChip(
            label: Text(
              item,
              style: TextStyle(
                color: isSelected ? onSelectedColor : unselectedLabel,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
            ),
            selected: isSelected,
            selectedColor: selectedColor,
            backgroundColor: backgroundColor,
            checkmarkColor: onSelectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              side: BorderSide(
                color: selectedColor.withValues(alpha: isSelected ? 1 : 0.2),
              ),
            ),
            onSelected: (value) {
              if (value) onSelected(item);
            },
          );
        },
      ),
    );
  }
}
