import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'home_screen.dart' show LocationLabel;

const _hijriMonths = [
  'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Ula',
  'Jumada al-Akhirah', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal',
  "Dhu al-Qa'dah", 'Dhu al-Hijjah',
];

String hijriLabel(PrayerDay d) {
  if (d.hijri != null) {
    final p = d.hijri!.split('-').map(int.parse).toList();
    return '${p[2]} ${_hijriMonths[p[1] - 1]} ${p[0]}';
  }
  final h = HijriCalendar.fromDate(d.date);
  return '${h.hDay} ${_hijriMonths[h.hMonth - 1]} ${h.hYear}';
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key, required this.controller, required this.onOpenSettings});
  final ScrollController controller;
  final VoidCallback onOpenSettings;
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  DateTime _date = DateTime.now();

  bool get _isToday => PrayerService.key(_date) == PrayerService.key(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final day = app.day(_date);
    return Ticker(builder: (context, now) {
      final (next, _, nextDay) = app.nextPrayer(now);
      final nextIsHere = PrayerService.key(nextDay.date) == PrayerService.key(_date);
      return ListView(
        controller: widget.controller,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 12, 20, 200),
        children: [
          Row(children: [
            Expanded(
                child: Text('Prayer times',
                    style: T.ui(30, w: FontWeight.w700, ls: -.025))),
            LocationLabel(onTap: widget.onOpenSettings),
          ]),
          const SizedBox(height: 4),
          Text(app.sourceLabel, style: T.ui(12.5, c: C.faint, w: FontWeight.w500)),
          if (app.error != null) ...[
            const SizedBox(height: 6),
            Text(app.error!, style: T.ui(12.5, c: C.rose, w: FontWeight.w500)),
          ],
          const SizedBox(height: 18),
          const Hairline(alpha: .08),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              _arrow(LucideIcons.chevronLeft,
                  () => setState(() => _date = _date.subtract(const Duration(days: 1)))),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _date = DateTime.now()),
                  child: Column(children: [
                    Text(
                        '${_isToday ? 'Today, ' : ''}${DateFormat('EEEE, d MMM').format(_date)}',
                        style: T.ui(15, w: FontWeight.w700)),
                    Text(hijriLabel(day),
                        style: T.ui(12.5, c: C.faint, w: FontWeight.w500)),
                  ]),
                ),
              ),
              _arrow(LucideIcons.chevronRight,
                  () => setState(() => _date = _date.add(const Duration(days: 1)))),
            ]),
          ),
          const Hairline(alpha: .08),
          for (final p in Prayer.values)
            _row(context, p, day, now, isNext: nextIsHere && p == next),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(children: [
              _tool(LucideIcons.compass, 'Qibla',
                  '${app.qiblaBearing.round()}° ${_compass(app.qiblaBearing)}',
                  () => showQiblaSheet(context)),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0x1AF7ECDC)),
              _tool(LucideIcons.calculator, 'Method',
                  app.inMalaysia ? 'JAKIM' : app.method.label.split(' ').first,
                  () => showMethodSheet(context)),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0x1AF7ECDC)),
              _tool(LucideIcons.volume2, 'Adhan', app.adhanSound.label.split(' ').first,
                  () => showAdhanSheet(context)),
            ]),
          ),
          const SizedBox(height: 30),
          _WeekTracker(),
        ],
      );
    });
  }

  Widget _arrow(IconData i, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
            width: 36, height: 36, child: Icon(i, size: 18, color: C.muted)),
      );

  Widget _row(BuildContext context, Prayer p, PrayerDay day, DateTime now,
      {required bool isNext}) {
    final app = AppState.instance;
    final t = day[p];
    final past = t.isBefore(now);
    // A prayer that has not started yet cannot have been prayed.
    final prayed = past && app.isPrayed(_date, p);
    String sub;
    Color subC = C.faint;
    if (p == Prayer.syuruk) {
      sub = 'Sunrise · no prayer';
    } else if (isNext) {
      sub = 'Next · in ${inWords(t.difference(now))}';
    } else if (prayed) {
      sub = 'Prayed';
      subC = C.sage;
    } else if (past) {
      sub = 'Not marked yet';
    } else {
      sub = app.alerts[p] == true ? 'Alert on' : 'Silent';
    }
    Widget action;
    if (p == Prayer.syuruk) {
      action = const SizedBox(width: 34);
    } else if (past || prayed) {
      action = GestureDetector(
        onTap: () => app.togglePrayed(_date, p),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(LucideIcons.check,
              size: 20, color: prayed ? C.sage : C.sand.withValues(alpha: .28)),
        ),
      );
    } else {
      action = GestureDetector(
        onTap: () => app.toggleAlert(p),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(app.alerts[p] == true ? LucideIcons.bell : LucideIcons.bellOff,
              size: 19, color: isNext ? prayerTint(p) : C.muted),
        ),
      );
    }
    final tint = prayerTint(p);
    final nameC = isNext ? C.sand : (prayed ? C.sand2 : C.sand);
    final content = Row(children: [
      SizedBox(width: 34, child: Center(child: PrayerIcon(p, size: isNext ? 34 : 30))),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.label,
              style: T.ui(isNext ? 18 : 16.5, w: FontWeight.w700, c: nameC)),
          const SizedBox(height: 2),
          Text(sub, style: T.ui(12.5, c: isNext ? tint : subC, w: isNext ? FontWeight.w700 : FontWeight.w600)),
        ]),
      ),
      Text(hm(t),
          style: T.ui(isNext ? 20 : 17, w: FontWeight.w700, c: nameC)),
      const SizedBox(width: 3),
      Text(ampm(t), style: T.ui(11, c: isNext ? C.sand2 : C.faint, w: FontWeight.w700)),
      const SizedBox(width: 12),
      action,
    ]);
    if (!isNext) {
      final row = Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line()))),
        child: content,
      );
      return p == Prayer.syuruk ? Opacity(opacity: .5, child: row) : row;
    }
    // The next prayer sits in a tinted card in its own colour, matching the
    // wide tile on Home.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 13, 4, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint.withValues(alpha: .30), C.sand.withValues(alpha: .05)],
            stops: const [0, .75],
          ),
          border: Border.all(color: tint.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
                color: tint.withValues(alpha: .35),
                blurRadius: 26,
                offset: const Offset(0, 12),
                spreadRadius: -16),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _tool(IconData i, String t, String v, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(children: [
            Icon(i, size: 23, color: C.amber),
            const SizedBox(height: 8),
            Text(t, style: T.ui(13.5, w: FontWeight.w700)),
            Text(v, style: T.ui(12, c: C.faint)),
          ]),
        ),
      );

  static String _compass(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg % 360) / 45).round() % 8];
  }
}

/// On-time / late / missed grid for the last 7 days, from the user's marks.
class _WeekTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final now = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    var done = 0, total = 0;
    Color cell(DateTime d, Prayer p) {
      final isFuture = PrayerService.key(d) == PrayerService.key(now) &&
          app.day(d)[p].isAfter(now);
      if (isFuture) return Colors.transparent;
      total++;
      if (app.isPrayed(d, p)) {
        done++;
        return C.sage;
      }
      return C.rose.withValues(alpha: .35);
    }

    final grid = [
      for (final p in fardPrayers) [for (final d in days) cell(d, p)]
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('This week', style: T.ui(18, w: FontWeight.w700))),
        Text.rich(TextSpan(children: [
          TextSpan(text: '$done', style: T.ui(13, c: C.sage, w: FontWeight.w700)),
          TextSpan(text: ' of $total prayed', style: T.ui(13, c: C.faint)),
        ])),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        const SizedBox(width: 22),
        for (final d in days)
          Expanded(
            child: Text(DateFormat('E').format(d).substring(0, 2),
                textAlign: TextAlign.center,
                style: T.ui(11,
                    w: FontWeight.w700,
                    c: PrayerService.key(d) == PrayerService.key(now)
                        ? C.amber
                        : C.faint)),
          ),
      ]),
      const SizedBox(height: 7),
      for (var r = 0; r < 5; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            SizedBox(
                width: 22,
                child: Text(fardPrayers[r].label[0],
                    style: T.ui(11.5, c: C.faint, w: FontWeight.w700))),
            for (var c = 0; c < 7; c++)
              Expanded(
                child: Container(
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: grid[r][c],
                    border: grid[r][c] == Colors.transparent
                        ? Border.all(color: C.sand.withValues(alpha: .18))
                        : null,
                    boxShadow: grid[r][c] == C.sage
                        ? [BoxShadow(color: C.sage.withValues(alpha: .35), blurRadius: 6)]
                        : null,
                  ),
                ),
              ),
          ]),
        ),
      const SizedBox(height: 8),
      Row(children: [
        _legend(C.sage, 'Prayed'),
        const SizedBox(width: 16),
        _legend(C.rose.withValues(alpha: .35), 'Not marked'),
        const SizedBox(width: 16),
        Text('Tap ✓ on a prayer to mark it',
            style: T.ui(11.5, c: C.faint.withValues(alpha: .8))),
      ]),
    ]);
  }

  Widget _legend(Color c, String t) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(t, style: T.ui(12, c: C.faint)),
      ]);
}

/// Degrees helper kept for the Qibla dial.
double degToRad(double d) => d * math.pi / 180;
