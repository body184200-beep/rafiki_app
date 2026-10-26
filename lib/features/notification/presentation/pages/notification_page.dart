import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/features/azkar/data/datasources/azkar_data.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static bool get _l => ThemeProvider.instance.isLight;
  static Color get bg       => _l ? const Color(0xFFF8F6F0) : const Color(0xff06080D);
  static Color get surf     => _l ? const Color(0xFFFFFFFF) : const Color(0xff0D1117);
  static Color get surf2    => _l ? const Color(0xFFF3F4F6) : const Color(0xff131A24);
  static Color get surf3    => _l ? const Color(0xFFE5E7EB) : const Color(0xff1B2332);
  static Color get acc      => _l ? const Color(0xFF0F4A39) : const Color(0xff4ECBA8);
  static Color get acc2     => _l ? const Color(0xFF1D5A46) : const Color(0xff2E9E7A);
  static Color get acc3     => _l ? const Color(0xFF0B4633) : const Color(0xff1B6B53);
  static Color get txt      => _l ? const Color(0xFF111827) : const Color(0xffECF0F8);
  static Color get txt2     => _l ? const Color(0xFF6B7280) : const Color(0xff8896AB);
  static Color get txt3     => _l ? const Color(0xFF9CA3AF) : const Color(0xff4D5A6C);
  static Color get border   => _l ? const Color(0xFFE5E7EB) : const Color(0xff1E2A38);
  static Color get border2  => _l ? const Color(0xFFE5E7EB) : const Color(0xff253040);
  static const errorBg  = Color(0xff1E0808);
  static const errorAcc = Color(0xffE24B4A);
}

const _readyAzkar = <String>[
  'سبحان الله وبحمده سبحان الله العظيم',
  'لا إله إلا الله وحده لا شريك له',
  'اللهم صل وسلم على نبينا محمد',
  'أستغفر الله العظيم وأتوب إليه',
  'لا حول ولا قوة إلا بالله',
  'حسبي الله ونعم الوكيل',
  'اللهم اغفر لي ولوالدي',
  'اللهم ارزقني الجنة وأجرني من النار',
];

/// Build locale-aware days list from AppLocalizations.
List<Map<String, String>> _buildDays(AppLocalizations loc) => [
  {'label': loc.day_sat, 'short': loc.day_sat_short},
  {'label': loc.day_sun, 'short': loc.day_sun_short},
  {'label': loc.day_mon, 'short': loc.day_mon_short},
  {'label': loc.day_tue, 'short': loc.day_tue_short},
  {'label': loc.day_wed, 'short': loc.day_wed_short},
  {'label': loc.day_thu, 'short': loc.day_thu_short},
  {'label': loc.day_fri, 'short': loc.day_fri_short},
];

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    sl<NotificationEngine>().checkAndRequestPermission();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  void _showForm([CustomNotification? notif]) {
    NotificationFormSheet.show(context, existing: notif);
  }

  Future<void> _toggleNotif(String id, bool val) async {
    HapticFeedback.lightImpact();
    await sl<NotificationEngine>().toggleNotification(id, val);
  }

  Future<void> _deleteNotif(String id) async {
    HapticFeedback.mediumImpact();
    await sl<NotificationEngine>().deleteNotification(id);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _T.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Directionality(
        textDirection: Localizations.localeOf(context).languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: _T.bg,
          floatingActionButton: FloatingActionButton(
            backgroundColor: _T.acc,
            foregroundColor: _T.bg,
            onPressed: () => _showForm(),
            child: Icon(Icons.add_rounded),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                elevation: 0,
                backgroundColor: _T.bg,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: FadeTransition(
                    opacity: _headerFade,
                    child: Builder(
                      builder: (ctx) {
                        final loc = AppLocalizations.of(ctx)!;
                        return Text(
                          loc.notif_title,
                          style: TextStyle(
                            color: _T.txt,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        );
                      },
                    ),
                  ),
                  background: Container(
                    color: _T.bg,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Builder(
                            builder: (ctx) {
                              final loc = AppLocalizations.of(ctx)!;
                              return Text(
                                loc.notif_subtitle,
                                style: TextStyle(color: _T.txt2, fontSize: 13.5),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _T.border),
                ),
              ),

              // ── Permission Warning Banner ───────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: sl<NotificationEngine>().isGlobalAllowed,
                builder: (context, allowed, _) {
                  if (allowed) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  final loc = AppLocalizations.of(context)!;
                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _T.errorBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _T.errorAcc.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: _T.errorAcc),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.notif_permission_disabled,
                              style: TextStyle(color: _T.txt, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await sl<NotificationEngine>().requestAllNotificationPermissions(context: context);
                            },
                            child: Text(
                              loc.notif_enable_button,
                              style: TextStyle(color: _T.acc, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── List ──────────────────────────────────────────────────
              ValueListenableBuilder<List<CustomNotification>>(
                valueListenable: sl<NotificationEngine>().notifications,
                builder: (context, notifications, _) {
                  final loc = AppLocalizations.of(context)!;
                  if (notifications.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          loc.notif_empty,
                          style: TextStyle(color: _T.txt3, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final n = notifications[i];
                          return _buildNotifCard(n);
                        },
                        childCount: notifications.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard(CustomNotification n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _T.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0D1117), Color(0xff0A0F18)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  n.body,
                  style: TextStyle(
                    color: n.enabled ? _T.txt : _T.txt3,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              Switch(
                value: n.enabled,
                onChanged: (val) => _toggleNotif(n.id, val),
                activeColor: _T.acc,
                inactiveThumbColor: _T.txt3,
                inactiveTrackColor: _T.surf3,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: n.enabled ? _T.acc : _T.txt3),
              SizedBox(width: 6),
              Text(
                n.time.format(context),
                style: TextStyle(
                  color: n.enabled ? _T.acc : _T.txt3,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: _T.txt2, size: 20),
                onPressed: () => _showForm(n),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: _T.errorAcc, size: 20),
                onPressed: () => _deleteNotif(n.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            n.days.join(' • '),
            style: TextStyle(color: _T.txt3, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Form Bottom Sheet
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
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  final _titleController = TextEditingController();
  final _zekrController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 5, minute: 30);
  final List<String> _selectedDays = [];
  bool _isSaving = false;
  bool _initializedDays = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _zekrController.text = widget.existing!.body;
      _selectedTime = widget.existing!.time;
      _selectedDays.addAll(widget.existing!.days);
      _initializedDays = true;
    } else {
      _titleController.text = widget.initialTitle ?? '';
      _zekrController.text = widget.initialZekr ?? _readyAzkar.first;
      if (widget.initialTime != null) {
        _selectedTime = widget.initialTime!;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDays) {
      _initializedDays = true;
      final loc = AppLocalizations.of(context);
      if (loc != null) {
        _selectedDays.addAll([
          loc.day_sat,
          loc.day_sun,
          loc.day_mon,
          loc.day_tue,
          loc.day_wed,
          loc.day_thu,
          loc.day_fri,
        ]);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _zekrController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: isError ? _T.errorBg : _T.surf3,
        ),
      );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _T.acc,
            onPrimary: _T.bg,
            surface: _T.surf3,
            onSurface: _T.txt,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: _T.surf,
            hourMinuteColor: _T.surf3,
            hourMinuteTextColor: _T.txt,
            dialBackgroundColor: _T.surf3,
            dialHandColor: _T.acc,
            entryModeIconColor: _T.txt2,
            dialTextColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected) ? _T.bg : _T.txt,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _openZekrLibraryPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ZekrPickerSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _zekrController.text = result['text'] ?? '';
        if (_titleController.text.trim().isEmpty ||
            _titleController.text == 'تذكير بالأذكار') {
          _titleController.text = result['category'] ?? 'تذكير بذكر الله';
        }
      });
    }
  }

  Future<void> _onSave() async {
    final loc = AppLocalizations.of(context)!;
    final text = _zekrController.text.trim();
    if (text.isEmpty) {
      _showSnack(loc.notif_error_no_zekr, isError: true);
      return;
    }
    if (_selectedDays.isEmpty) {
      _showSnack(loc.notif_error_no_days, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : loc.notif_default_title;

    final notif = CustomNotification(
      id: widget.existing?.id ?? UniqueKey().toString(),
      title: title,
      body: text,
      time: _selectedTime,
      days: _selectedDays,
      enabled: widget.existing?.enabled ?? true,
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
            content: Text('تم حفظ وتفعيل إشعار التذكير بنجاح 🔔',
                style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Color(0xff1B2332),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(color: _T.txt3, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  Widget _card({required Widget child, VoidCallback? onTap}) {
    Widget inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _T.border),
      ),
      child: child,
    );
    if (onTap != null) inner = GestureDetector(onTap: onTap, child: inner);
    return inner;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final days = _buildDays(loc);
    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.surf3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.existing != null ? loc.notif_edit_title : 'تحديد ذكر للتذكير اليومي',
              style: TextStyle(color: _T.txt, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Browse full Azkar library button
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: _openZekrLibraryPicker,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _T.acc3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _T.acc2.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: _T.acc, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تصفح مكتبة الأذكار الكاملة',
                                    style: TextStyle(
                                      color: _T.acc,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'اختر من أذكار الصباح، المساء، أو الأدعية النبوية',
                                    style: TextStyle(color: _T.txt2, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: _T.acc, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Zekr Select & Custom Input
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('أذكار وأدعية سريعة:'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _readyAzkar.map((z) {
                            final isActive = _zekrController.text == z;
                            return GestureDetector(
                              onTap: () => setState(() => _zekrController.text = z),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? _T.acc3.withValues(alpha: 0.22) : _T.surf2,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: isActive ? _T.acc2 : _T.border2),
                                ),
                                child: Text(
                                  z,
                                  style: TextStyle(
                                    color: isActive ? _T.acc : _T.txt2,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 18),
                        _label('عنوان التنبيه (اختياري):'),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(color: _T.txt, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'مثال: أذكار الصباح، ورد الاستغفار، الصلاة على النبي',
                            hintStyle: TextStyle(color: _T.txt3, fontSize: 13),
                            filled: true,
                            fillColor: _T.surf2,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        SizedBox(height: 16),
                        _label('نص الذكر المطلوب التذكير به:'),
                        TextField(
                          controller: _zekrController,
                          maxLines: 3,
                          style: TextStyle(color: _T.txt, fontSize: 14, height: 1.5),
                          decoration: InputDecoration(
                            hintText: loc.notif_zekr_hint,
                            hintStyle: TextStyle(color: _T.txt3, fontSize: 13),
                            filled: true,
                            fillColor: _T.surf2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Time
                  _card(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _T.acc3.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.access_time_rounded, color: _T.acc, size: 22),
                        ),
                        SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(loc.notif_time_label),
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                color: _T.txt,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Days
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(loc.notif_days_label),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: days.map((d) {
                            final isSel = _selectedDays.contains(d['label']);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSel ? _selectedDays.remove(d['label']) : _selectedDays.add(d['label']!);
                                });
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSel ? _T.acc3.withValues(alpha: 0.22) : _T.surf2,
                                  border: Border.all(color: isSel ? _T.acc : _T.border2),
                                ),
                                child: Center(
                                  child: Text(
                                    d['short']!,
                                    style: TextStyle(
                                      color: isSel ? _T.acc : _T.txt2,
                                      fontSize: 11,
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
                  SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.acc,
                        foregroundColor: _T.bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(color: _T.bg)
                          : Text(
                              loc.notif_save,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full Zekr Library Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ZekrPickerSheet extends StatefulWidget {
  const _ZekrPickerSheet();

  @override
  State<_ZekrPickerSheet> createState() => _ZekrPickerSheetState();
}

class _ZekrPickerSheetState extends State<_ZekrPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _filter(List<String> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final morningList = morningAzkar.map((m) => m['text'] as String).toList();
    final eveningList = eveningAzkar.map((m) => m['text'] as String).toList();
    final generalList = _readyAzkar;

    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.surf3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'اختر ذكراً لضبط التذكير',
              style: TextStyle(
                color: _T.txt,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: _T.txt, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث في الأذكار...',
                  hintStyle: TextStyle(color: _T.txt3, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _T.acc, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: _T.txt3, size: 18),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: _T.surf,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _T.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _T.border),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Tabs
            TabBar(
              controller: _tabCtrl,
              indicatorColor: _T.acc,
              labelColor: _T.acc,
              unselectedLabelColor: _T.txt3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'أذكار الصباح ☀️'),
                Tab(text: 'أذكار المساء 🌙'),
                Tab(text: 'جوامع الأذكار 📿'),
              ],
            ),
            Divider(height: 1, color: _T.border),

            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(_filter(morningList), 'أذكار الصباح'),
                  _buildList(_filter(eveningList), 'أذكار المساء'),
                  _buildList(_filter(generalList), 'تذكير بذكر الله'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<String> items, String category) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أذكار مطابقة للبحث',
          style: TextStyle(color: _T.txt3, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final text = items[i];
        return InkWell(
          onTap: () {
            Navigator.pop(context, {'text': text, 'category': category});
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.surf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.acc3.withValues(alpha: 0.22),
                  ),
                  child: Icon(Icons.add_rounded, color: _T.acc, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: _T.txt,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}