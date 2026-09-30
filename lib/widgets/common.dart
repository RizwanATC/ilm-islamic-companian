import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Colour illustration for a prayer.
class PrayerIcon extends StatelessWidget {
  const PrayerIcon(this.prayer, {super.key, this.size = 30});
  final Prayer prayer;
  final double size;

  static String asset(Prayer p) => switch (p) {
        Prayer.fajr || Prayer.syuruk => 'assets/img/p_fajr.svg',
        Prayer.dhuhr => 'assets/img/p_dhuhr.svg',
        Prayer.asr => 'assets/img/p_asr.svg',
        Prayer.maghrib => 'assets/img/p_maghrib.svg',
        Prayer.isha => 'assets/img/p_isha.svg',
      };

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset(prayer), width: size, height: size);
}

/// Yun (boy, songkok) or Ayu (girl, tudung), depending on the gender setting.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) {
    final girl = AppState.instance.gender == Gender.female;
    return girl
        ? SvgPicture.asset('assets/img/yun_girl.svg', width: size, height: size)
        : Image.asset('assets/img/yun_boy.webp', width: size, height: size);
  }
}

String hm(DateTime t) => DateFormat('h:mm').format(t);
String ampm(DateTime t) => DateFormat('a').format(t);
String hmA(DateTime t) => DateFormat('h:mm a').format(t);

String countdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String inWords(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// Rebuilds every second.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder});
  final Widget Function(BuildContext, DateTime now) builder;
  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  late Timer _t;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// Colours used for the soft glow behind the next prayer.
Color prayerTint(Prayer p) => switch (p) {
      Prayer.fajr || Prayer.syuruk => const Color(0xFF8B7CF0),
      Prayer.dhuhr => const Color(0xFF57B8E0),
      Prayer.asr => const Color(0xFFF1B56E),
      Prayer.maghrib => const Color(0xFFF4844A),
      Prayer.isha => const Color(0xFF5B67E6),
    };

/// "Next prayer" block with countdown and the five-prayer day timeline.
class NextPrayerTimeline extends StatelessWidget {
  const NextPrayerTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Ticker(builder: (context, now) {
      final (next, at, _) = app.nextPrayer(now);
      final idx = fardPrayers.indexOf(next);
      // Position of "now" on the 5-dot line (dots at 10%, 30% ... 90%).
      double p;
      if (idx == 0) {
        p = .04;
      } else {
        final prev = app.today[fardPrayers[idx - 1]];
        final span = at.difference(prev).inSeconds;
        final done = now.difference(prev).inSeconds;
        final f = span <= 0 ? 0.0 : (done / span).clamp(0.0, 1.0);
        p = .1 + .2 * (idx - 1) + .2 * f * .92;
      }
      final tint = prayerTint(next);
      return Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: -40,
          top: -30,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  tint.withValues(alpha: .22),
                  tint.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Next prayer', style: T.ui(13, c: C.muted, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(next.label,
                    style: T.ui(46, w: FontWeight.w800, ls: -.04, h: 1)),
                const SizedBox(height: 6),
                Text(hmA(at), style: T.ui(15, c: C.sand2)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                _PulseDot(color: tint),
                const SizedBox(width: 8),
                Text(countdown(at.difference(now)),
                    style: T.ui(17, w: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 26),
          SizedBox(
            height: 30,
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 13,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: C.sand.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(2))),
                ),
                Positioned(
                  left: 0,
                  top: 13,
                  child: Container(
                    width: w * p,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        C.rose,
                        tint,
                      ]),
                    ),
                  ),
                ),
                for (var i = 0; i < 5; i++)
                  Positioned(
                    left: w * (.1 + .2 * i) - 4,
                    top: 11,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < idx
                            ? C.rose
                            : i == idx
                                ? C.sand
                                : const Color(0xFF3A2F40),
                        boxShadow: i == idx
                            ? [BoxShadow(color: tint, blurRadius: 10)]
                            : null,
                      ),
                    ),
                  ),
                Positioned(
                  left: w * p - 15,
                  top: 0,
                  child: PrayerIcon(next, size: 30),
                ),
              ]);
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: Text(
                    fardPrayers[i].label,
                    textAlign: TextAlign.center,
                    style: T.ui(12,
                        w: FontWeight.w700, c: i == idx ? C.sand : C.faint),
                  ),
                ),
            ],
          ),
        ]),
      ]);
    });
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: .3).animate(_c),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
          ),
        ),
      );
}

/// Section heading with an optional trailing action.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: Text(title, style: T.ui(18, w: FontWeight.w700, ls: -.01))),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: Text(trailing!,
                  style: T.ui(13.5,
                      c: onTap != null ? C.amber : C.faint, w: FontWeight.w600)),
            ),
        ],
      );
}

/// Small spark toast used for journey rewards.
void showNoorToast(BuildContext context, String text) {
  final overlay = Overlay.of(context);
  late OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1900),
            onEnd: () => e.remove(),
            builder: (context, v, child) {
              final pop = v < .15 ? v / .15 : 1.0;
              final fade = v > .8 ? (1 - v) / .2 : 1.0;
              return Opacity(
                opacity: (pop * fade).clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - pop) - (v > .8 ? 30 * (v - .8) / .2 : 0)),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE0A3), C.amber]),
                  boxShadow: [
                    BoxShadow(
                        color: C.amber.withValues(alpha: .6),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                        spreadRadius: -10)
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome, size: 18, color: C.ink),
                  const SizedBox(width: 8),
                  Text(text, style: T.ui(16, w: FontWeight.w800, c: C.ink)),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(e);
}
