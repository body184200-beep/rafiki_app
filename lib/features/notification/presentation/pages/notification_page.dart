import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xff06080D);
  static const surf     = Color(0xff0D1117);
  static const surf2    = Color(0xff131A24);
  static const surf3    = Color(0xff1B2332);
  static const acc      = Color(0xff4ECBA8);
  static const acc2     = Color(0xff2E9E7A);
  static const acc3     = Color(0xff1B6B53);
  static const txt      = Color(0xffECF0F8);
  static const txt2     = Color(0xff8896AB);
  static const txt3     = Color(0xff4D5A6C);
  static const border   = Color(0xff1E2A38);
  static const border2  = Color(0xff253040);
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
  bool _isAllowed = true;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final allowed = await sl<NotificationEngine>().checkAndRequestPermission();
    if (mounted) {
      setState(() {
        _isAllowed = allowed;
      });
    }
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  void _showForm([CustomNotification? notif]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationFormSheet(existing: notif),
    );
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
      value: const SystemUiOverlayStyle(
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
            child: const Icon(Icons.add_rounded),
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
                          style: const TextStyle(
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
                                style: const TextStyle(color: _T.txt2, fontSize: 13.5),
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
              if (!_isAllowed)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _T.errorBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _T.errorAcc.withOpacity(0.3)),
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final loc = AppLocalizations.of(ctx)!;
                        return Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: _T.errorAcc),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.notif_permission_disabled,
                            style: const TextStyle(color: _T.txt, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final success = await sl<NotificationEngine>().checkAndRequestPermission();
                            if (mounted) {
                              setState(() {
                                _isAllowed = success;
                              });
                            }
                          },
                          child: Text(
                            loc.notif_enable_button,
                            style: const TextStyle(color: _T.acc, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                      },
                    ),
                  ),
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
                          style: const TextStyle(color: _T.txt3, fontSize: 16),
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
        gradient: const LinearGradient(
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: n.enabled ? _T.acc : _T.txt3),
              const SizedBox(width: 6),
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
                icon: const Icon(Icons.edit_rounded, color: _T.txt2, size: 20),
                onPressed: () => _showForm(n),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: _T.errorAcc, size: 20),
                onPressed: () => _deleteNotif(n.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
class _NotificationFormSheet extends StatefulWidget {
  final CustomNotification? existing;
  const _NotificationFormSheet({this.existing});

  @override
  State<_NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<_NotificationFormSheet> {
  final _zekrController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 5, minute: 30);
  final List<String> _selectedDays = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _zekrController.text = widget.existing!.body;
      _selectedTime = widget.existing!.time;
      _selectedDays.addAll(widget.existing!.days);
    } else {
      _zekrController.text = _readyAzkar.first;
    }
  }

  @override
  void dispose() {
    _zekrController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
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
          colorScheme: const ColorScheme.dark(
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

  Future<void> _onSave() async {
    final loc  = AppLocalizations.of(context)!;
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
    
    final notif = CustomNotification(
      id: widget.existing?.id ?? UniqueKey().toString(),
      title: loc.notif_default_title,
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(color: _T.txt3, fontSize: 10.5, fontWeight: FontWeight.w700),
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _T.surf3, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(widget.existing != null ? loc.notif_edit_title : loc.notif_add_title, style: const TextStyle(color: _T.txt, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Zekr Select
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(loc.notif_select_ready_zekr),
                        Wrap(
                          spacing: 8, runSpacing: 8,
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
                                child: Text(z, style: TextStyle(color: isActive ? _T.acc : _T.txt2, fontSize: 12.5)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _label(loc.notif_custom_zekr_label),
                        TextField(
                          controller: _zekrController,
                          maxLines: 2,
                          style: const TextStyle(color: _T.txt, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: loc.notif_zekr_hint,
                            hintStyle: const TextStyle(color: _T.txt3, fontSize: 14),
                            filled: true,
                            fillColor: _T.surf2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time
                  _card(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: _T.acc3.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.access_time_rounded, color: _T.acc, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(loc.notif_time_label),
                            Text(_selectedTime.format(context), style: const TextStyle(color: _T.txt, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Days
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(loc.notif_days_label),
                        Wrap(
                          spacing: 8, runSpacing: 10,
                          children: days.map((d) {
                            final isSel = _selectedDays.contains(d['label']);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSel ? _selectedDays.remove(d['label']) : _selectedDays.add(d['label']!);
                                });
                              },
                              child: Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSel ? _T.acc3.withValues(alpha: 0.22) : _T.surf2,
                                  border: Border.all(color: isSel ? _T.acc : _T.border2),
                                ),
                                child: Center(child: Text(d['short']!, style: TextStyle(color: isSel ? _T.acc : _T.txt2, fontSize: 11))),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.acc,
                        foregroundColor: _T.bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: _T.bg)
                        : Text(loc.notif_save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}