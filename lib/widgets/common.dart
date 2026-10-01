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

/// Softly pulsing dot in the next prayer's colour.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color});
  final Color color;
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
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
