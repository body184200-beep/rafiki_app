import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Clean, Simple & Modern Notification Page
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationEngine _engine = sl<NotificationEngine>();

  static bool get _l => ThemeProvider.instance.isLight;
  static Color get _bg => _l ? const Color(0xFFF8F6F0) : const Color(0xff060A12);
  static Color get _cardBg => _l ? const Color(0xFFFFFFFF) : const Color(0xff0E1626);
  static Color get _teal => _l ? const Color(0xFF0F4A39) : const Color(0xff2EB88A);
  static Color get _gold => _l ? const Color(0xFF8D5B18) : const Color(0xffC9A84C);
  static Color get _textMain => _l ? const Color(0xFF111827) : const Color(0xffEDE8D8);
  static Color get _textSub => _l ? const Color(0xFF6B7280) : const Color(0xff7E93A8);
  static Color get _border => _l ? const Color(0xFFE5E7EB) : const Color(0xff162238);

  @override
  void initState() {
    super.initState();
    _engine.checkAndRequestPermission();
  }

  void _showForm([CustomNotification? notif]) {
    NotificationFormSheet.show(context, existing: notif);
  }

  Future<void> _toggleNotif(String id, bool val) async {
    HapticFeedback.lightImpact();
    await _engine.toggleNotification(id, val);
  }

  Future<void> _deleteNotif(String id, String body) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _cardBg,
          title: Text('حذف التذكير', style: TextStyle(color: _textMain, fontSize: 16)),
          content: Text('هل أنت متأكد من حذف هذا التذكير؟', style: TextStyle(color: _textSub, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: TextStyle(color: _textSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await _engine.deleteNotification(id);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تذكيرات الأذكار',
            style: TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded, color: _textMain, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          onPressed: () => _showForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة ذكر للتذكير', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ValueListenableBuilder<List<CustomNotification>>(
          valueListenable: _engine.notifications,
          builder: (context, notifs, _) {
            if (notifs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active_outlined, size: 48, color: _teal),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد تذكيرات نشطة حالياً',
                        style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أضف أذكارك المفضلة وحدد وقتها أو اختر تكرارها كل عدة ساعات لتصلك تلقائياً على هاتفك.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _textSub, fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إنشاء تذكير جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showForm(),
                      ),
                    ],
                  ),
                ),
              );
            }

            final activeCount = notifs.where((n) => n.enabled).length;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: _teal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لديك $activeCount تذكيرات مفعلة تعمل محلياً على الهاتف بدون إنترنت.',
                          style: TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reminders list
                for (final notif in notifs) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.enabled ? _cardBg : _cardBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: notif.enabled ? _teal.withValues(alpha: 0.3) : _border,
                        width: notif.enabled ? 1.2 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Frequency Badge & Toggle Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: notif.enabled
                                    ? _teal.withValues(alpha: 0.14)
                                    : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    notif.repeatIntervalHours != null && notif.repeatIntervalHours! > 0
                                        ? Icons.repeat_rounded
                                        : Icons.access_time_rounded,
                                    size: 14,
                                    color: notif.enabled ? _teal : _textSub,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notif.repeatIntervalHours != null && notif.repeatIntervalHours! > 0
                                        ? 'يتكرر كل ${notif.repeatIntervalHours} ساعات'
                                        : 'يومياً الساعة ${_formatTimeOfDay(notif.time)}',
                                    style: TextStyle(
                                      color: notif.enabled ? _teal : _textSub,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: notif.enabled,
                              activeColor: _teal,
                              onChanged: (val) => _toggleNotif(notif.id, val),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Dhikr Title & Body
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: notif.enabled ? _textMain : _textSub,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Actions & Days
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.days.length == 7 ? 'كل الأيام' : notif.days.join('، '),
                                style: TextStyle(color: _textSub, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: _textSub),
                              tooltip: 'تعديل',
                              onPressed: () => _showForm(notif),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withValues(alpha: 0.7)),
                              tooltip: 'حذف',
                              onPressed: () => _deleteNotif(notif.id, notif.body),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Simple, Intuitive Bottom Sheet Form
// ─────────────────────────────────────────────────────────────────────────────

class NotificationFormSheet extends StatefulWidget {
  final CustomNotification? existing;
  final String? initialZekr;
  final String? initialTitle;
  final TimeOfDay? initialTime;

  const NotificationFormSheet({
    super.key,
    this.existing,
    this.initialZekr,
    this.initialTitle,
    this.initialTime,
  });

  static Future<void> show(
    BuildContext context, {
    CustomNotification? existing,
    String? initialZekr,
    String? initialTitle,
    TimeOfDay? initialTime,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeProvider.instance.isLight ? Colors.white : const Color(0xFF0F1728),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NotificationFormSheet(
        existing: existing,
        initialZekr: initialZekr,
        initialTitle: initialTitle,
        initialTime: initialTime,
      ),
    );
  }

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  late TimeOfDay _time;
  int? _repeatIntervalHours; // null for specific time, or 1, 2, 3, 4, 6
  bool _isPeriodicMode = true; // User can choose between repeat interval vs specific time
  bool _isSaving = false;

  final List<String> _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  final Set<String> _selectedDays = {};

  static const List<String> _presetAzkar = [
    'سبحان الله وبحمده سبحان الله العظيم',
    'لا إله إلا الله وحده لا شريك له',
    'اللهم صلِّ وسلم على نبينا محمد',
    'أستغفر الله العظيم وأتوب إليه',
    'لا حول ولا قوة إلا بالله العلي العظيم',
    'حسبي الله ونعم الوكيل',
    'اللهم اغفر لي ولوالدي وللمسلمين',
    'رضيت بالله رباً وبالإسلام ديناً وبمحمد نبياً',
  ];

  static const List<int> _intervalOptions = [1, 2, 3, 4, 6];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _textCtrl.text = ex.body;
      _time = ex.time;
      _repeatIntervalHours = ex.repeatIntervalHours;
      _isPeriodicMode = ex.repeatIntervalHours != null && ex.repeatIntervalHours! > 0;
      _selectedDays.addAll(ex.days);
    } else {
      _textCtrl.text = widget.initialZekr ?? _presetAzkar.first;
      _time = widget.initialTime ?? const TimeOfDay(hour: 8, minute: 0);
      _repeatIntervalHours = 2; // Default to repeating every 2 hours!
      _isPeriodicMode = true;
      _selectedDays.addAll(_days); // Default to all days
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    final body = _textCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال نص الذكر أو الدعاء')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notif = CustomNotification(
      id: widget.existing?.id ?? UniqueKey().toString(),
      title: widget.initialTitle ?? '🤍 تذكير بذكر الله',
      body: body,
      time: _time,
      days: _selectedDays.toList(),
      enabled: widget.existing?.enabled ?? true,
      repeatIntervalHours: _isPeriodicMode ? _repeatIntervalHours : null,
    );

    try {
      if (widget.existing != null) {
        await sl<NotificationEngine>().updateNotification(notif);
      } else {
        await sl<NotificationEngine>().addNotification(notif);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتفعيل التذكير بنجاح 🔔'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeProvider.instance.isLight;
    final textPri = isLight ? const Color(0xFF111827) : const Color(0xFFEDE8D8);
    final textSec = isLight ? const Color(0xFF6B7280) : const Color(0xFF7E93A8);
    final teal = isLight ? const Color(0xFF0F4A39) : const Color(0xff2EB88A);
    final border = isLight ? const Color(0xFFE5E7EB) : const Color(0xff1E2C44);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 18,
          right: 18,
          top: 14,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                widget.existing != null ? 'تعديل التذكير' : 'إضافة تذكير بذكر الله',
                style: TextStyle(color: textPri, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // ── 1. Dhikr Text Input ─────────────────────────────────────
              Text('نص الذكر أو الدعاء:', style: TextStyle(color: textSec, fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 2,
                  style: TextStyle(color: textPri, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'اكتب الذكر أو اختر من القائمة أدناه...',
                    hintStyle: TextStyle(color: textSec, fontSize: 13),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick preset chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presetAzkar.take(5).map((zkr) {
                  return ActionChip(
                    label: Text(zkr, style: TextStyle(fontSize: 11, color: textPri)),
                    backgroundColor: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF131D30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: border)),
                    onPressed: () {
                      setState(() => _textCtrl.text = zkr);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // ── 2. Repeat Interval (Requested Feature!) ──────────────────
              Text('طريقة التكرار:', style: TextStyle(color: textSec, fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('تكرار كل عدة ساعات 🔄')),
                      selected: _isPeriodicMode,
                      selectedColor: teal.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _isPeriodicMode ? teal : textSec,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: _isPeriodicMode ? teal : border),
                      ),
                      onSelected: (val) {
                        setState(() {
                          _isPeriodicMode = true;
                          _repeatIntervalHours ??= 2;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('وقت محدد يومياً ⏰')),
                      selected: !_isPeriodicMode,
                      selectedColor: teal.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: !_isPeriodicMode ? teal : textSec,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: !_isPeriodicMode ? teal : border),
                      ),
                      onSelected: (val) {
                        setState(() => _isPeriodicMode = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interval Options
              if (_isPeriodicMode) ...[
                Text(
                  'اختر كم ساعة بين كل تذكير:',
                  style: TextStyle(color: textSec, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _intervalOptions.map((h) {
                    final isSel = _repeatIntervalHours == h;
                    return ChoiceChip(
                      label: Text('كل $h ${h == 1 ? "ساعة" : (h == 2 ? "ساعتين" : "ساعات")}'),
                      selected: isSel,
                      selectedColor: teal.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSel ? teal : textSec,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSel ? teal : border),
                      ),
                      onSelected: (_) => setState(() => _repeatIntervalHours = h),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'يبدأ التكرار تلقائياً خلال ساعات اليوم النشطة لتذكيرك بالله طوال اليوم.',
                  style: TextStyle(color: textSec, fontSize: 11),
                ),
              ] else ...[
                // Specific Time Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.access_time_rounded, color: teal),
                  title: Text(
                    'وقت التذكير: ${_time.format(context)}',
                    style: TextStyle(color: textPri, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  trailing: TextButton(
                    onPressed: _pickTime,
                    child: Text('تغيير الوقت', style: TextStyle(color: teal, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ── 3. Days of Week Selection ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أيام التنبيه:',
                    style: TextStyle(color: textSec, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _selectedDays.length == _days.length ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: teal,
                    ),
                    label: Text(
                      _selectedDays.length == _days.length ? 'كل الأيام (محدد)' : 'تحديد كل الأيام',
                      style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_selectedDays.length == _days.length) {
                          // Uncheck some to allow custom picking, keep today
                          _selectedDays.clear();
                          _selectedDays.add(_days.first);
                        } else {
                          _selectedDays.clear();
                          _selectedDays.addAll(_days);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 7 Days Chips Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((d) {
                  final isSel = _selectedDays.contains(d);
                  return FilterChip(
                    label: Text(d),
                    selected: isSel,
                    selectedColor: teal.withValues(alpha: 0.18),
                    checkmarkColor: teal,
                    labelStyle: TextStyle(
                      color: isSel ? teal : textPri,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSel ? teal : border),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDays.add(d);
                        } else {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(d);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يجب اختيار يوم واحد على الأقل للتنبيه'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ وتفعيل التذكير 🔔', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
