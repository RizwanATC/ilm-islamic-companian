import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

IconData stepIcon(int i) => switch (i) {
      0 => LucideIcons.sunrise,
      1 => LucideIcons.bookOpen,
      2 => LucideIcons.sun,
      3 => LucideIcons.cloudSun,
      4 => LucideIcons.sunset,
      5 => LucideIcons.moonStar,
      _ => LucideIcons.moon,
    };

enum NodeState { done, now, lock }

NodeState stateOf(int i) {
  final d = AppState.instance.journeyDone;
  return i < d ? NodeState.done : (i == d ? NodeState.now : NodeState.lock);
}

/// When a prayer step opens: its prayer time today. Other steps are always open.
DateTime? stepOpensAt(int i) {
  final p = journeySteps[i].prayer;
  return p == null ? null : AppState.instance.today[p];
}

/// Prayer steps can't be tapped until their prayer time has arrived.
bool stepArrived(int i) {
  final at = stepOpensAt(i);
  return at == null || !DateTime.now().isBefore(at);
}

String stepTime(JourneyStep s) {
  if (s.prayer == null) return s.time;
  return hmA(AppState.instance.today[s.prayer!]);
}

/// Chunky game-style node.
class JourneyNode extends StatefulWidget {
  const JourneyNode({super.key, required this.index, this.size = 58, this.onTap});
  final int index;
  final double size;
  final VoidCallback? onTap;
  @override
  State<JourneyNode> createState() => _JourneyNodeState();
}

class _JourneyNodeState extends State<JourneyNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _arrival;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _scheduleArrival();
  }

  @override
  void didUpdateWidget(JourneyNode old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _scheduleArrival();
  }

  /// Rebuild the moment the prayer time arrives so the node becomes tappable.
  void _scheduleArrival() {
    _arrival?.cancel();
    final at = stepOpensAt(widget.index);
    if (at == null) return;
    final wait = at.difference(DateTime.now());
    if (wait.isNegative) return;
    _arrival = Timer(wait + const Duration(milliseconds: 50), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _arrival?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = stateOf(widget.index);
    final arrived = stepArrived(widget.index);
    final s = st == NodeState.now ? widget.size + 10 : widget.size;
    final icon = st == NodeState.done ? LucideIcons.check : stepIcon(widget.index);
    Widget node;
    switch (st) {
      case NodeState.done:
        node = Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: C.amberGradient,
            boxShadow: [
              const BoxShadow(color: Color(0xFFA8683A), offset: Offset(0, 6)),
              BoxShadow(
                  color: C.amber.withValues(alpha: .45),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                  spreadRadius: -8),
            ],
          ),
          child: Icon(icon, size: s * .42, color: C.ink),
        );
      case NodeState.now:
        node = AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2230),
              // Waiting for its prayer time: dim ring, no pulse.
              border: Border.all(
                  color: arrived ? C.amber : C.amber.withValues(alpha: .35), width: 2),
              boxShadow: [
                const BoxShadow(color: Color(0x99A8683A), offset: Offset(0, 6)),
                if (arrived)
                  BoxShadow(
                      color: C.amber.withValues(alpha: .15 + .2 * _pulse.value),
                      blurRadius: 18 + 14 * _pulse.value,
                      spreadRadius: 4 * _pulse.value),
              ],
            ),
            child: child,
          ),
          child: Icon(icon,
              size: s * .42, color: arrived ? C.amber : C.amber.withValues(alpha: .45)),
        );
      case NodeState.lock:
        node = Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: C.lockNode,
            boxShadow: [BoxShadow(color: Color(0xFF16121A), offset: Offset(0, 6))],
          ),
          child: Icon(icon, size: s * .42, color: C.sand.withValues(alpha: .35)),
        );
    }
    return Semantics(
      button: true,
      enabled: arrived,
      child: GestureDetector(onTap: arrived ? widget.onTap : null, child: node),
    );
  }
}

/// Final "day complete" gift.
class GiftNode extends StatelessWidget {
  const GiftNode({super.key, this.size = 62});
  final double size;
  @override
  Widget build(BuildContext context) {
    final open = AppState.instance.journeyDone >= journeySteps.length;
    return Transform.rotate(
      angle: .785,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .32),
          gradient: open
              ? const LinearGradient(colors: [Color(0xFFFFE0A3), C.amberDeep])
              : null,
          color: open ? null : C.lockNode,
          boxShadow: [
            BoxShadow(
                color: open ? const Color(0xFFA8683A) : const Color(0xFF16121A),
                offset: const Offset(0, 6)),
            if (open) BoxShadow(color: C.amber.withValues(alpha: .7), blurRadius: 30),
          ],
        ),
        child: Transform.rotate(
          angle: -.785,
          child: Icon(LucideIcons.gift,
              size: size * .42,
              color: open ? C.ink : C.sand.withValues(alpha: .4)),
        ),
      ),
    );
  }
}

/// Hopping mascot.
class HoppingMascot extends StatefulWidget {
  const HoppingMascot({super.key, this.size = 46});
  final double size;
  @override
  State<HoppingMascot> createState() => _HoppingMascotState();
}

class _HoppingMascotState extends State<HoppingMascot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
            offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
            child: child),
        child: Mascot(size: widget.size),
      );
}

/// Draws the winding trail through node centres.
class TrailPainter extends CustomPainter {
  TrailPainter(this.points, this.done, {required this.horizontal});
  final List<Offset> points;
  final int done;
  final bool horizontal;

  Path _path(int upto) {
    final p = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i <= upto && i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if (horizontal) {
        final mx = (a.dx + b.dx) / 2;
        p.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      } else {
        final my = (a.dy + b.dy) / 2;
        p.cubicTo(a.dx, my, b.dx, my, b.dx, b.dy);
      }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = C.sand.withValues(alpha: .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final full = _path(points.length - 1);
    for (final m in full.computeMetrics()) {
      for (double d = 0; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d, d + 2), base);
      }
    }
    if (done > 0) {
      final gold = _path(done.clamp(0, points.length - 1));
      canvas.drawPath(
          gold,
          Paint()
            ..color = C.amber.withValues(alpha: .5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(
          gold,
          Paint()
            ..color = C.amber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(TrailPainter old) => old.done != done;
}

/// Glass sheet for a journey step with "Mark as done".
Future<void> openStepSheet(BuildContext context, int i) {
  final app = AppState.instance;
  final s = journeySteps[i];
  final st = stateOf(i);
  return showGlassSheet(context, builder: (ctx) {
    return Column(children: [
      Container(
        width: 66,
        height: 66,
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: st == NodeState.done ? Colors.white : S.fill(.16),
          border: st == NodeState.done
              ? null
              : Border.all(
                  color: st == NodeState.lock ? S.line(.4) : Colors.white,
                  width: 2),
        ),
        child: Icon(stepIcon(i),
            size: 30,
            color: st == NodeState.done
                ? C.ink
                : st == NodeState.lock
                    ? S.faint
                    : S.text),
      ),
      Text(s.title, style: T.ui(22, w: FontWeight.w700, c: S.text)),
      const SizedBox(height: 6),
      Text(s.detail,
          textAlign: TextAlign.center,
          style: T.ui(14, c: S.muted, w: FontWeight.w500, h: 1.5)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: S.fill(.22),
            borderRadius: BorderRadius.circular(13)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.sparkles, size: 15, color: S.accent),
          const SizedBox(width: 6),
          Text('+${s.reward} Noor', style: T.ui(14, c: S.accent, w: FontWeight.w800)),
        ]),
      ),
      const SizedBox(height: 18),
      SheetButton(
        label: switch (st) {
          NodeState.done => 'Done today ✓',
          NodeState.lock => 'Unlocks at ${stepTime(s)}',
          NodeState.now => 'Mark as done',
        },
        enabled: st == NodeState.now && stepArrived(i),
        onTap: () async {
          Navigator.pop(ctx);
          if (s.prayer != null && !app.isPrayed(DateTime.now(), s.prayer!)) {
            await app.togglePrayed(DateTime.now(), s.prayer!);
          }
          final (reward, up) = await app.completeStep();
          if (context.mounted) {
            showNoorToast(context, '+$reward Noor');
            if (up) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (context.mounted) {
                  showNoorToast(context, 'Level ${app.level} · ${app.levelName}');
                }
              });
            }
          }
        },
      ),
    ]);
  });
}
