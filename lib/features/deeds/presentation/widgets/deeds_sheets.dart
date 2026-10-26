import 'package:flutter/material.dart';
import 'package:rafiki_app/features/deeds/data/models/dhikr_entry.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DhikrPickerSheet – Browse, Add & Select Dhikr
// ─────────────────────────────────────────────────────────────────────────────
class DhikrPickerSheet extends StatefulWidget {
  final List<DhikrEntry> adhkar;
  final int selectedIndex;
  final MisbahaTheme theme;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;
  final void Function(String text, int target, String? virtue) onAdd;

  const DhikrPickerSheet({
    super.key,
    required this.adhkar,
    required this.selectedIndex,
    required this.theme,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<DhikrPickerSheet> createState() => _DhikrPickerSheetState();
}

class _DhikrPickerSheetState extends State<DhikrPickerSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController(text: "100");
  final TextEditingController _virtueCtrl = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _targetCtrl.dispose();
    _virtueCtrl.dispose();
    super.dispose();
  }

  void _submitNew() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    final virtue = _virtueCtrl.text.trim().isEmpty ? null : _virtueCtrl.text.trim();
    widget.onAdd(text, target, virtue);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 10),
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: DeedsColors.textHint,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "قائمة الأذكار والتسبيحات",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DeedsColors.textMain,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showAddForm = !_showAddForm),
                  icon: Icon(
                    _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                    color: widget.theme.accentLight,
                    size: 18,
                  ),
                  label: Text(
                    _showAddForm ? "إلغاء" : "إضافة ذكر",
                    style: TextStyle(
                      color: widget.theme.accentLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showAddForm) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  SheetInput(
                    controller: _textCtrl,
                    hint: "اكتب الذكر المبارك (مثال: سبحان الله وبحمده)",
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SheetInput(
                          controller: _targetCtrl,
                          hint: "الهدف (0 = غير محدد)",
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submitNew,
                        child: Text("حفظ الذكر", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SheetInput(
                    controller: _virtueCtrl,
                    hint: "فضل هذا الذكر (اختياري)",
                  ),
                  Divider(color: Colors.white12, height: 24),
                ],
              ),
            ),
          ],

          // List of Adhkar
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.adhkar.length,
              separatorBuilder: (_, __) => SizedBox(height: 6),
              itemBuilder: (_, idx) {
                final e = widget.adhkar[idx];
                final selected = idx == widget.selectedIndex;
                final isCustom = idx >= 10;
                final isDone = e.target > 0 && e.count >= e.target;

                return Dismissible(
                  key: ValueKey("dhikr_${e.text}_$idx"),
                  direction: isCustom ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: DeedsColors.red.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: DeedsColors.red),
                  ),
                  onDismissed: (_) => widget.onDelete(idx),
                  child: Material(
                    color: selected
                        ? widget.theme.primary.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onSelect(idx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? widget.theme.primaryLight.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: selected ? widget.theme.primaryLight : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: selected
                                    ? Icon(Icons.check_rounded, color: widget.theme.primaryLight, size: 18)
                                    : Text(
                                        "${idx + 1}",
                                        style: TextStyle(
                                          color: DeedsColors.textSub,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.text,
                                    style: TextStyle(
                                      color: selected ? Colors.white : DeedsColors.textMain,
                                      fontSize: 15,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  if (e.virtue != null && e.virtue!.isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      e.virtue!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? widget.theme.accentLight.withValues(alpha: 0.9)
                                            : DeedsColors.textHint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${e.count}",
                                  style: TextStyle(
                                    color: isDone ? widget.theme.accentLight : DeedsColors.textMain,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (e.target > 0)
                                  Text(
                                    "الهدف: ${e.target}",
                                    style: TextStyle(
                                      color: DeedsColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MisbahaThemeSheet – Gemstone Theme Picker
// ─────────────────────────────────────────────────────────────────────────────
class MisbahaThemeSheet extends StatelessWidget {
  final MisbahaTheme currentTheme;
  final ValueChanged<MisbahaTheme> onSelect;

  const MisbahaThemeSheet({
    super.key,
    required this.currentTheme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: DeedsColors.textHint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "مظهر وخامة المسبحة",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: DeedsColors.textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "اختر خامة الأحجار الكريمة المناسبة لذوقك الروحي",
                style: TextStyle(fontSize: 12.5, color: DeedsColors.textSub),
              ),
              SizedBox(height: 20),
              Column(
                children: MisbahaTheme.all.map((theme) {
                  final isSel = theme.id == currentTheme.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isSel
                          ? theme.primary.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(theme);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSel ? theme.primaryLight : Colors.white.withValues(alpha: 0.08),
                              width: isSel ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Bead preview swatch
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.beadHighlight,
                                      theme.primaryLight,
                                      theme.primary,
                                      theme.primaryDark,
                                    ],
                                    center: const Alignment(-0.3, -0.3),
                                    radius: 0.95,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primary.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      theme.name,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : DeedsColors.textMain,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      theme.description,
                                      style: TextStyle(
                                        color: DeedsColors.textSub,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSel)
                                Icon(Icons.check_circle_rounded, color: theme.primaryLight, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MisbahaSettingsSheet – Haptics & Sound Settings
// ─────────────────────────────────────────────────────────────────────────────
class MisbahaSettingsSheet extends StatefulWidget {
  final int hapticMode; // 0: off, 1: each tap, 2: milestone only
  final bool soundEnabled;
  final bool fullScreenTap;
  final ValueChanged<int> onHapticChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onFullScreenChanged;

  const MisbahaSettingsSheet({
    super.key,
    required this.hapticMode,
    required this.soundEnabled,
    required this.fullScreenTap,
    required this.onHapticChanged,
    required this.onSoundChanged,
    required this.onFullScreenChanged,
  });

  @override
  State<MisbahaSettingsSheet> createState() => _MisbahaSettingsSheetState();
}

class _MisbahaSettingsSheetState extends State<MisbahaSettingsSheet> {
  late int _haptic;
  late bool _sound;
  late bool _fullScreen;

  @override
  void initState() {
    super.initState();
    _haptic = widget.hapticMode;
    _sound = widget.soundEnabled;
    _fullScreen = widget.fullScreenTap;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: DeedsColors.textHint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "إعدادات المسبحة",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: DeedsColors.textMain,
                ),
              ),
              SizedBox(height: 20),

              // Haptics options
              Text(
                "نمط الاهتزاز اللمسي",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DeedsColors.textMain),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionTab("مع كل تسبيحة", 1),
                  SizedBox(width: 8),
                  _buildOptionTab("عند إتمام الهدف", 2),
                  SizedBox(width: 8),
                  _buildOptionTab("إيقاف", 0),
                ],
              ),

              SizedBox(height: 22),

              // Sound switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: DeedsColors.jade,
                title: Text(
                  "صوت نقر الخرزات",
                  style: TextStyle(color: DeedsColors.textMain, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "نقر صوتي هادئ عند تحريك حبة المسبحة",
                  style: TextStyle(color: DeedsColors.textSub, fontSize: 12),
                ),
                value: _sound,
                onChanged: (val) {
                  setState(() => _sound = val);
                  widget.onSoundChanged(val);
                },
              ),

              // Full-screen tap switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: DeedsColors.jade,
                title: Text(
                  "وضع التسبيح بكامل الشاشة",
                  style: TextStyle(color: DeedsColors.textMain, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "انقر في أي مكان بالشاشة دون الحاجة للنظر إليها",
                  style: TextStyle(color: DeedsColors.textSub, fontSize: 12),
                ),
                value: _fullScreen,
                onChanged: (val) {
                  setState(() => _fullScreen = val);
                  widget.onFullScreenChanged(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTab(String label, int mode) {
    final sel = _haptic == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _haptic = mode);
          widget.onHapticChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: sel ? DeedsColors.jade.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: sel ? DeedsColors.jadeLight : Colors.white.withValues(alpha: 0.08),
              width: sel ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: sel ? DeedsColors.jadeLight : DeedsColors.textSub,
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TargetEditorSheet – Custom Target Editor
// ─────────────────────────────────────────────────────────────────────────────
class TargetEditorSheet extends StatefulWidget {
  final DhikrEntry current;
  final ValueChanged<int> onSave;

  const TargetEditorSheet({
    super.key,
    required this.current,
    required this.onSave,
  });

  @override
  State<TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<TargetEditorSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current.target.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save(int target) {
    widget.onSave(target);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: DeedsColors.textHint,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "تحديد هدف التسبيح",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: DeedsColors.textMain,
              ),
            ),
            SizedBox(height: 6),
            Text(
              widget.current.text,
              style: TextStyle(fontSize: 13, color: DeedsColors.textSub),
            ),
            SizedBox(height: 16),

            // Preset buttons
            Row(
              children: [33, 100, 1000, 0].map((t) {
                final label = t == 0 ? "مفتوح ∞" : "$t";
                final sel = widget.current.target == t;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sel ? DeedsColors.goldLight : DeedsColors.textMain,
                        side: BorderSide(
                          color: sel ? DeedsColors.gold : Colors.white12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _save(t),
                      child: Text(label),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 16),
            SheetInput(
              controller: _ctrl,
              hint: "أدخل هدفاً مخصصاً (أرقام)",
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeedsColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final val = int.tryParse(_ctrl.text.trim()) ?? 0;
                  _save(val);
                },
                child: Text("حفظ وتطبيق", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
