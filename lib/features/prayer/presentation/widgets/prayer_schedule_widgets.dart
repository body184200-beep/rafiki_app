import 'package:flutter/material.dart';
import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';

class QadaCarryEntry {
  final String prayerName;
  final String dateKey;
  bool completed = false;

  QadaCarryEntry({
    required this.prayerName,
    required this.dateKey,
  });
}

class QadaCarryCard extends StatelessWidget {
  final QadaCarryEntry entry;
  final VoidCallback onComplete;
  const QadaCarryCard({
    super.key,
    required this.entry,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: T.rubyL, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${entry.prayerName} (${entry.dateKey})',
                style: const TextStyle(color: T.t1, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onComplete,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: T.ruby.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: T.ruby.withValues(alpha: 0.4)),
              ),
              child: const Text('قضيتها',
                  style: TextStyle(
                      color: T.rubyL,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class DayChip extends StatelessWidget {
  final bool completed;
  final bool isEmpty;
  const DayChip({
    super.key,
    required this.completed,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
    String label;
    IconData icon;
    if (isEmpty) {
      bg = T.t3.withValues(alpha: 0.1);
      border = T.t3.withValues(alpha: 0.25);
      text = T.t3;
      label = 'لا يوجد تاريخ';
      icon = Icons.calendar_today_rounded;
    } else if (completed) {
      bg = T.jade.withValues(alpha: 0.12);
      border = T.jade.withValues(alpha: 0.35);
      text = T.jade;
      label = 'مكتمل';
      icon = Icons.check_circle_rounded;
    } else {
      bg = T.t3.withValues(alpha: 0.1);
      border = T.t3.withValues(alpha: 0.25);
      text = T.t3;
      label = 'غير مكتمل';
      icon = Icons.remove_circle_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class BannerWidget extends StatelessWidget {
  final String text;
  const BannerWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: T.flame.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: T.flame.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: T.flameL, fontSize: 13)),
    ),
  );
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class RakatDots extends StatelessWidget {
  final int rakats;
  final Color accent;
  final bool done;
  const RakatDots({
    super.key,
    required this.rakats,
    required this.accent,
    required this.done,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      rakats,
          (i) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? accent
              : accent.withValues(alpha: 0.3 + i * 0.1),
          boxShadow: done
              ? [BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 4)]
              : [],
        ),
      ),
    ),
  );
}

class MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MiniStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: T.card,
      border: Border.all(color: color.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style:
            const TextStyle(color: T.t3, fontSize: 11)),
      ],
    ),
  );
}

class ScoreDetailChip extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const ScoreDetailChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value > 0
                    ? '+${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}'
                    : '٠',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style:
                  const TextStyle(color: T.t3, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class PrayerCard extends StatefulWidget {
  final PrayerDef prayer;
  final PrayerRecord record;
  final ValueChanged<bool> onComplete;
  final VoidCallback onQada;
  final ValueChanged<int> onMarkSunnah;
  final int index;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.record,
    required this.onComplete,
    required this.onQada,
    required this.onMarkSunnah,
    required this.index,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + widget.index * 80));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.record.state) {
      case PrayerState.locked:                return T.t3;
      case PrayerState.available:             return widget.prayer.accent;
      case PrayerState.completedIndividual:   return T.jade;
      case PrayerState.completedCongregation: return T.gold;
      case PrayerState.oadaPending:           return T.ruby;
      case PrayerState.oadaCompleted:         return T.violet;
    }
  }

  Color get _stateBg {
    switch (widget.record.state) {
      case PrayerState.locked:                return T.card;
      case PrayerState.available:             return widget.prayer.tint;
      case PrayerState.completedIndividual:   return const Color(0xFF0E1E18);
      case PrayerState.completedCongregation: return const Color(0xFF1A160A);
      case PrayerState.oadaPending:           return const Color(0xFF1E0E0E);
      case PrayerState.oadaCompleted:         return const Color(0xFF120E1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.prayer;
    final rec   = widget.record;
    final state = rec.state;
    final sc    = _stateColor;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: _stateBg,
              border: Border.all(
                color: sc.withValues(
                    alpha: state == PrayerState.locked ? 0.12 : 0.4),
                width: state == PrayerState.locked ? 1 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: sc.withValues(
                      alpha: state == PrayerState.locked ? 0.05 : 0.15),
                  blurRadius: state == PrayerState.locked ? 8 : 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [sc, sc.withValues(alpha: 0.2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _iconBox(p, sc, state),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p.name,
                                          style: TextStyle(
                                              color: state ==
                                                  PrayerState.locked
                                                  ? T.t3
                                                  : T.t1,
                                              fontSize: 18,
                                              fontWeight:
                                              FontWeight.w900)),
                                      const SizedBox(width: 8),
                                      _stateBadge(state),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      RakatDots(
                                          rakats: p.rakats,
                                          accent: sc,
                                          done: state.isCompleted),
                                      const SizedBox(width: 6),
                                      Text('${p.rakats} ركعات',
                                          style: const TextStyle(
                                              color: T.t3,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActionArea(state, p, sc),
                        if (p.sunnah.isNotEmpty &&
                            (state == PrayerState.available ||
                                state ==
                                    PrayerState.completedIndividual ||
                                state ==
                                    PrayerState
                                        .completedCongregation)) ...[
                          const SizedBox(height: 12),
                          _buildSunnahRow(p, sc, rec),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(PrayerDef p, Color sc, PrayerState state) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      color: sc.withValues(
          alpha: state == PrayerState.locked ? 0.05 : 0.12),
      border: Border.all(
          color: sc.withValues(
              alpha: state == PrayerState.locked ? 0.15 : 0.3)),
    ),
    child: Icon(
      state == PrayerState.locked
          ? Icons.lock_outline_rounded
          : p.icon,
      color: sc.withValues(
          alpha: state == PrayerState.locked ? 0.4 : 1),
      size: 22,
    ),
  );

  Widget _stateBadge(PrayerState state) {
    String label;
    Color color;
    IconData icon;

    switch (state) {
      case PrayerState.locked:
        label = 'مغلق';
        color = T.t3;
        icon  = Icons.lock_outline_rounded;
      case PrayerState.available:
        label = 'متاحة';
        color = widget.prayer.accent;
        icon  = Icons.radio_button_unchecked_rounded;
      case PrayerState.completedIndividual:
        label = 'فردي';
        color = T.jade;
        icon  = Icons.check_circle_rounded;
      case PrayerState.completedCongregation:
        label = 'جماعة';
        color = T.gold;
        icon  = Icons.groups_rounded;
      case PrayerState.oadaPending:
        label = 'قضاء';
        color = T.ruby;
        icon  = Icons.warning_amber_rounded;
      case PrayerState.oadaCompleted:
        label = 'قُضيت';
        color = T.violet;
        icon  = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionArea(PrayerState state, PrayerDef p, Color sc) {
    switch (state) {
      case PrayerState.locked:
        return _lockedMessage();
      case PrayerState.available:
        return _availableActions();
      case PrayerState.completedIndividual:
        return _completedMessage(
            'أديتها فردياً', T.jade, Icons.person_rounded);
      case PrayerState.completedCongregation:
        return _completedMessage(
            'أديتها في الجماعة', T.gold, Icons.groups_rounded);
      case PrayerState.oadaPending:
        return _qadaAction();
      case PrayerState.oadaCompleted:
        return _completedMessage(
            'قُضيت', T.violet, Icons.check_circle_outline_rounded);
    }
  }

  Widget _lockedMessage() => Row(
    children: [
      Icon(Icons.access_time_rounded, color: T.t3, size: 14),
      const SizedBox(width: 6),
      const Text('لم يحن وقت الصلاة بعد',
          style: TextStyle(color: T.t3, fontSize: 12)),
    ],
  );

  Widget _availableActions() => Row(
    children: [
      Expanded(
          child: ActionBtn(
            label: 'صليتها جماعة',
            icon:  Icons.groups_rounded,
            color: T.gold,
            onTap: () => widget.onComplete(true),
          )),
      const SizedBox(width: 10),
      Expanded(
          child: ActionBtn(
            label: 'صليتها فردي',
            icon:  Icons.person_rounded,
            color: T.jade,
            onTap: () => widget.onComplete(false),
          )),
    ],
  );

  Widget _qadaAction() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: T.rubyL, size: 14),
          const SizedBox(width: 6),
          const Text('فات وقت الصلاة — تبقّى القضاء',
              style: TextStyle(color: T.rubyL, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: widget.onQada,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: T.ruby.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: T.ruby.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh_rounded,
                  color: T.rubyL, size: 16),
              const SizedBox(width: 8),
              const Text('قضيتها الآن',
                  style: TextStyle(
                      color: T.rubyL,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _completedMessage(String text, Color color, IconData icon) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(text,
          style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildSunnahRow(PrayerDef p, Color sc, PrayerRecord rec) =>
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(p.sunnah.length, (i) {
            final sel = rec.completedSunnah.contains(i);
            return GestureDetector(
              onTap: sel ? null : () => widget.onMarkSunnah(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel
                      ? sc.withValues(alpha: 0.18)
                      : T.bg.withValues(alpha: 0.5),
                  border: Border.all(
                      color: sel ? sc : T.t3.withValues(alpha: 0.3)),
                  boxShadow: sel
                      ? [BoxShadow(
                      color: sc.withValues(alpha: 0.2),
                      blurRadius: 8)]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sel)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_rounded,
                            color: sc, size: 13),
                      ),
                    Text(p.sunnah[i],
                        style: TextStyle(
                          color: sel ? sc : T.t2,
                          fontSize: 12.5,
                          fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
