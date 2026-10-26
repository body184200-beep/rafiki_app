import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MisbahaTheme – Luxury Gemstone & Material Themes
// ─────────────────────────────────────────────────────────────────────────────
class MisbahaTheme {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentLight;
  final Color beadHighlight;
  final Color dialBg;
  final Color threadColor;

  const MisbahaTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentLight,
    required this.beadHighlight,
    required this.dialBg,
    required this.threadColor,
  });

  static const emerald = MisbahaTheme(
    id: 'emerald',
    name: 'الزمرد الملكي',
    description: 'خرزات زمردية خضراء عميقة مع بريق ذهبي دافئ',
    primary: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    primaryDark: Color(0xFF022C22),
    accent: Color(0xFFD97706),
    accentLight: Color(0xFFFBBF24),
    beadHighlight: Color(0xFFA7F3D0),
    dialBg: Color(0xFF061A14),
    threadColor: Color(0xFFB45309),
  );

  static const amber = MisbahaTheme(
    id: 'amber',
    name: 'العقيق اليماني',
    description: 'خرزات كهرمانية عقيقية دافئة بلون العسل الصافي',
    primary: Color(0xFFD97706),
    primaryLight: Color(0xFFFBBF24),
    primaryDark: Color(0xFF451A03),
    accent: Color(0xFFEA580C),
    accentLight: Color(0xFFFED7AA),
    beadHighlight: Color(0xFFFEF3C7),
    dialBg: Color(0xFF1B0E05),
    threadColor: Color(0xFF78350F),
  );

  static const turquoise = MisbahaTheme(
    id: 'turquoise',
    name: 'الفيروز الصافي',
    description: 'حبات فيروزية صافية مستوحاة من سكون البحار والأنهار',
    primary: Color(0xFF0891B2),
    primaryLight: Color(0xFF22D3EE),
    primaryDark: Color(0xFF083344),
    accent: Color(0xFF0284C7),
    accentLight: Color(0xFFBAE6FD),
    beadHighlight: Color(0xFFCFFAFE),
    dialBg: Color(0xFF061622),
    threadColor: Color(0xFF0E7490),
  );

  static const pearl = MisbahaTheme(
    id: 'pearl',
    name: 'اللؤلؤ النقي',
    description: 'حبات لؤلؤية فضية نقية تشع صفاءً ونوراً',
    primary: Color(0xFF94A3B8),
    primaryLight: Color(0xFFF8FAFC),
    primaryDark: Color(0xFF1E293B),
    accent: Color(0xFFA855F7),
    accentLight: Color(0xFFE9D5FF),
    beadHighlight: Color(0xFFFFFFFF),
    dialBg: Color(0xFF0F172A),
    threadColor: Color(0xFF64748B),
  );

  static const obsidian = MisbahaTheme(
    id: 'obsidian',
    name: 'السبج والذهب',
    description: 'حجر السبج الأسود المصقول بحواف ذهبية ملكية',
    primary: Color(0xFF27272A),
    primaryLight: Color(0xFF71717A),
    primaryDark: Color(0xFF09090B),
    accent: Color(0xFFF59E0B),
    accentLight: Color(0xFFFDE68A),
    beadHighlight: Color(0xFFE4E4E7),
    dialBg: Color(0xFF0A0A0E),
    threadColor: Color(0xFFB45309),
  );

  static const List<MisbahaTheme> all = [
    emerald,
    amber,
    turquoise,
    pearl,
    obsidian,
  ];

  static MisbahaTheme getTheme(String? id) {
    if (id == null) return emerald;
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => emerald,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DeedsColors – General App Colors
// ─────────────────────────────────────────────────────────────────────────────
class DeedsColors {
  static bool get _l => ThemeProvider.instance.isLight;
  static Color get surface   => _l ? const Color(0xFFFFFFFF) : const Color(0xff090F16);
  static Color get jade      => _l ? const Color(0xFF0F4A39) : const Color(0xff2EB88A);
  static Color get jadeLight => _l ? const Color(0xFF1D5A46) : const Color(0xff5EFACC);
  static Color get jadeDim   => const Color(0xff1A7A5C);
  static Color get gold      => _l ? const Color(0xFF8D5B18) : const Color(0xffC9A84C);
  static Color get goldLight => _l ? const Color(0xFFB48216) : const Color(0xffF0CC7A);
  static Color get textMain  => _l ? const Color(0xFF111827) : const Color(0xffEEE8D5);
  static Color get textSub   => _l ? const Color(0xFF6B7280) : const Color(0xff7A8F98);
  static Color get textHint  => _l ? const Color(0xFF9CA3AF) : const Color(0xff3E5260);
  static Color get red       => const Color(0xffE05252);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DhikrCapsuleChip – Quick Dhikr Selector Chip
// ─────────────────────────────────────────────────────────────────────────────
class DhikrCapsuleChip extends StatelessWidget {
  final String text;
  final int count;
  final int target;
  final bool isSelected;
  final MisbahaTheme theme;
  final VoidCallback onTap;

  const DhikrCapsuleChip({
    super.key,
    required this.text,
    required this.count,
    required this.target,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = target > 0 && count >= target;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? theme.primary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? theme.primaryLight
                : (isDone
                    ? theme.accentLight.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone) ...[
              Icon(Icons.check_circle_rounded, color: theme.accentLight, size: 14),
              SizedBox(width: 5),
            ],
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : DeedsColors.textMain,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? theme.primaryLight.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    color: isSelected ? Colors.white : DeedsColors.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TargetCapsuleChip – Quick Target Presets
// ─────────────────────────────────────────────────────────────────────────────
class TargetCapsuleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final MisbahaTheme theme;
  final VoidCallback onTap;

  const TargetCapsuleChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? theme.accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? theme.accentLight
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.accentLight : DeedsColors.textSub,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GlassCard, Buttons & Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback onTap;
  const GlassIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const ActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: DeedsColors.textSub,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const SheetInput({
    super.key,
    required this.controller,
    required this.hint,
    this.textDirection,
    this.keyboardType,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Directionality(
        textDirection: textDirection ?? TextDirection.rtl,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: DeedsColors.textMain, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DeedsColors.textHint, fontSize: 13.5),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const GlowBlob({super.key, required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  const ConfirmDialog({
    super.key,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DeedsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: DeedsColors.red, size: 24),
          SizedBox(width: 8),
          Text("تأكيد الإجراء", style: TextStyle(color: DeedsColors.textMain, fontSize: 17)),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: DeedsColors.textSub, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("إلغاء", style: TextStyle(color: DeedsColors.textSub)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DeedsColors.red.withValues(alpha: 0.25),
            foregroundColor: DeedsColors.red,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text("تأكيد"),
        ),
      ],
    );
  }
}
