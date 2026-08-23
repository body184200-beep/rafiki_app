import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 42),
              const SizedBox(height: AppSpacing.md),
              Text(
                message ?? 'حدث خطأ غير متوقع',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'أعد فتح الصفحة أو أعد تشغيل التطبيق',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
