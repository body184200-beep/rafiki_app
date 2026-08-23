import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standard loading / error / empty / content switch for list screens.
class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    required this.child,
    this.error,
    this.empty = false,
    this.onRetry,
    this.emptyMessage = 'لا توجد عناصر',
    this.loadingColor = AppColors.gold,
  });

  final bool loading;
  final bool empty;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;
  final String emptyMessage;
  final Color loadingColor;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: loadingColor, strokeWidth: 2),
      );
    }
    if (error != null) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        title: error!,
        actionLabel: onRetry == null ? null : 'إعادة المحاولة',
        onAction: onRetry,
      );
    }
    if (empty) {
      return _Message(
        icon: Icons.inbox_outlined,
        title: emptyMessage,
      );
    }
    return child;
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
