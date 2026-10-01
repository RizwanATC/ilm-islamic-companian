import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Sky colours (top, middle, horizon) for the time of day before each prayer.
List<Color> _sky(Prayer p) => switch (p) {
  Prayer.fajr || Prayer.syuruk => const [
    Color(0xFF2A2550),
    Color(0xFF5A4A86),
    Color(0xFFE39A86),
  ],
  Prayer.dhuhr => const [
    Color(0xFF1F4F7A),
    Color(0xFF3F86B3),
    Color(0xFF9FD0E6),
  ],
  Prayer.asr => const [Color(0xFF3D3A64), Color(0xFFA8708A), Color(0xFFF1B56E)],
  Prayer.maghrib => const [
    Color(0xFF3A2350),
    Color(0xFFB04A6E),
    Color(0xFFF4844A),
  ],
  Prayer.isha => const [
    Color(0xFF0F1030),
    Color(0xFF232457),
    Color(0xFF3B2F6E),
  ],
};

/// Home "next prayer" card: a small sky that follows the time of day, with the
/// sun or moon travelling along an arc from Fajr to Isha, and the countdown
/// below the horizon.
class SkyArcPrayerCard extends StatelessWidget {
  const SkyArcPrayerCard({super.key, this.onTap});
  final VoidCallback? onTap;

  static const _skyHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Ticker(
      builder: (context, now) {
        final (next, at, _) = app.nextPrayer(now);
        final idx = fardPrayers.indexOf(next);
        final today = app.today;
        final start = today[Prayer.fajr], end = today[Prayer.isha];
        double frac(DateTime t) {
          final span = end.difference(start).inSeconds;
          if (span <= 0) return 0;
          return (t.difference(start).inSeconds / span).clamp(0.0, 1.0);
        }

        // Before Fajr (or after Isha) the moon waits at the start of the arc.
        final f = idx == 0 ? 0.0 : frac(now);
        final ticks = [for (final p in fardPrayers) frac(today[p])];
        final night = next == Prayer.fajr || next == Prayer.isha;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .7),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                  spreadRadius: -20,
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _skyHeight,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final size = Size(c.maxWidth, _skyHeight);
                        final orb = _ArcPainter.point(size, f);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: _sky(next),
                                    stops: const [0, .58, 1],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: AnimatedOpacity(
                                duration: const Duration(seconds: 1),
                                opacity: night ? 1 : 0,
                                child: const CustomPaint(
                                  painter: _StarsPainter(),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ArcPainter(
                                  ticks: ticks,
                                  current: idx,
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 1400),
                              curve: Curves.easeOutCubic,
                              left: orb.dx - 20,
                              top: orb.dy - 20,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFECBE,
                                      ).withValues(alpha: .55),
                                      blurRadius: 18,
                                      spreadRadius: -6,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  transitionBuilder: (child, a) =>
                                      FadeTransition(
                                        opacity: a,
                                        child: ScaleTransition(
                                          scale: Tween(
                                            begin: .85,
                                            end: 1.0,
                                          ).animate(a),
                                          child: child,
                                        ),
                                      ),
                                  child: PrayerIcon(
                                    next,
                                    key: ValueKey(next),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Clip so the blur only frosts the ground, not the sky above.
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              C.bg.withValues(alpha: .55),
                              C.bg.withValues(alpha: .85),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next prayer',
                                    style: T.ui(
                                      12.5,
                                      c: C.muted,
                                      w: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    next.label,
                                    style: T.ui(
                                      32,
                                      w: FontWeight.w800,
                                      ls: -.035,
                                      h: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(hmA(at), style: T.ui(13.5, c: C.sand2)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'starts in',
                                  style: T.ui(
                                    12,
                                    c: C.muted,
                                    w: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  countdown(at.difference(now)),
                                  style: T.ui(22, w: FontWeight.w800, ls: -.01),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dotted half-ellipse from Fajr (left horizon) to Isha (right horizon),
/// with a dot for each prayer.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.ticks, required this.current});
  final List<double> ticks;
  final int current;

  // Geometry in a 300x128 design box, scaled to the real size.
  static Offset point(Size s, double f) {
    final a = math.pi * (1 - f.clamp(0.0, 1.0));
    final sx = s.width / 300, sy = s.height / 128;
    return Offset(
      (150 + 126 * math.cos(a)) * sx,
      (118 - 92 * math.sin(a)) * sy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .4)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // Walk the arc and draw a short dash every 7px of length.
    var prev = point(size, 0);
    var run = 0.0;
    for (var i = 1; i <= 400; i++) {
      final p = point(size, i / 400);
      run += (p - prev).distance;
      if (run >= 7) {
        canvas.drawLine(p, p + (p - prev) / (p - prev).distance * 2, dash);
        run = 0;
      }
      prev = p;
    }
    for (var i = 0; i < ticks.length; i++) {
      final alpha = i < current
          ? .35
          : i == current
          ? 1.0
          : .7;
      canvas.drawCircle(
        point(size, ticks[i]),
        3,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.current != current || !_same(old.ticks, ticks);

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A few fixed stars for the night sky (Isha and before Fajr).
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  static const _stars = [
    (30.0, 22.0, 1.0),
    (74.0, 48.0, .8),
    (118.0, 16.0, 1.1),
    (196.0, 30.0, .8),
    (240.0, 14.0, 1.0),
    (272.0, 52.0, .9),
    (160.0, 58.0, .7),
    (52.0, 80.0, .7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final sx = size.width / 300, sy = size.height / 128;
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(x * sx, y * sy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
