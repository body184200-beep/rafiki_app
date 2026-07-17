import 'package:flutter/material.dart';
import 'package:rafiki_app/features/deeds/data/models/dhikr_entry.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_widgets.dart';

class DhikrPickerSheet extends StatefulWidget {
  final List<DhikrEntry> adhkar;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;
  final void Function(String, int) onAdd;

  const DhikrPickerSheet({
    super.key,
    required this.adhkar,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<DhikrPickerSheet> createState() => _DhikrPickerSheetState();
}

class _DhikrPickerSheetState extends State<DhikrPickerSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: DeedsColors.textHint,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text("اختر ذكرًا",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: DeedsColors.textMain)),
        ),

        // List
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.40,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.adhkar.length,
            itemBuilder: (_, idx) {
              final e = widget.adhkar[idx];
              final selected = idx == widget.selectedIndex;
              final isCustom = idx >= 8;
              return Dismissible(
                key: ValueKey(e.text + idx.toString()),
                direction: isCustom
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: DeedsColors.red.withValues(alpha: 0.2),
                  child: const Icon(Icons.delete_outline_rounded, color: DeedsColors.red),
                ),
                onDismissed: (_) => widget.onDelete(idx),
                child: ListTile(
                  onTap: () => widget.onSelect(idx),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: selected
                      ? Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DeedsColors.jade.withValues(alpha: 0.15),
                      border: Border.all(color: DeedsColors.jade.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.check_rounded, color: DeedsColors.jade, size: 18),
                  )
                      : Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  title: Text(e.text,
                      style: TextStyle(
                        color: selected ? DeedsColors.jadeLight : DeedsColors.textMain,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 16,
                      )),
                  trailing: e.count > 0
                      ? Text("${e.count}",
                      style: const TextStyle(color: DeedsColors.jadeLight,
                          fontSize: 13, fontWeight: FontWeight.bold))
                      : null,
                ),
              );
            },
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // Add new
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: SheetInput(
                controller: _textCtrl,
                hint: "ذكر جديد...",
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SheetInput(
                controller: _targetCtrl,
                hint: "الهدف",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _textCtrl.text.trim();
                if (text.isEmpty) return;
                final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
                widget.onAdd(text, target);
                Navigator.pop(context);
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [DeedsColors.jade, DeedsColors.jadeLight]),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class TargetEditorSheet extends StatefulWidget {
  final DhikrEntry current;
  final ValueChanged<int> onSave;
  const TargetEditorSheet({super.key, required this.current, required this.onSave});

  @override
  State<TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<TargetEditorSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final List<int> _presets = [10, 33, 34, 100, 300, 1000];

  @override
  void initState() {
    super.initState();
    if (widget.current.target > 0) {
      _ctrl.text = widget.current.target.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DeedsColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: DeedsColors.textHint,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text(widget.current.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: DeedsColors.textMain),
            textDirection: TextDirection.rtl),
        const SizedBox(height: 4),
        const Text("حدد الهدف",
            style: TextStyle(fontSize: 12, color: DeedsColors.textSub)),
        const SizedBox(height: 20),

        // Presets
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _presets.map((p) {
            final sel = _ctrl.text == p.toString();
            return GestureDetector(
              onTap: () => setState(() => _ctrl.text = p.toString()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sel ? DeedsColors.jade.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: sel ? DeedsColors.jade : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text("$p",
                    style: TextStyle(
                      color: sel ? DeedsColors.jadeLight : DeedsColors.textSub,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 16,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Manual input
        SheetInput(
          controller: _ctrl,
          hint: "أو أدخل رقمًا مخصصًا",
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // Save button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              final val = int.tryParse(_ctrl.text.trim()) ?? 0;
              widget.onSave(val);
              Navigator.pop(context);
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [DeedsColors.jade, Color(0xff1A7A5C)]),
              ),
              child: const Center(
                child: Text("حفظ الهدف",
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.onSave(0);
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text("إزالة الهدف",
                style: TextStyle(color: DeedsColors.red, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  const ConfirmDialog({super.key, required this.message, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DeedsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      title: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: DeedsColors.textMain, fontSize: 16)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: DeedsColors.textSub)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DeedsColors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () { Navigator.pop(context); onConfirm(); },
          child: const Text("تأكيد"),
        ),
      ],
    );
  }
}
