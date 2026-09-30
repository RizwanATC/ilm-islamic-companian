import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/journey_path.dart';

void openJourney(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, a, b) => const JourneyScreen(),
    transitionsBuilder: (context, a, b, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(c),
          child: child,
        ),
      );
    },
  ));
}

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final app = AppState.instance;
          final pct = ((app.noor - app.levelFloor) / 100).clamp(0.0, 1.0);
          return ListView(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 50),
            children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Glass(
                    radius: 14,
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(LucideIcons.chevronLeft, size: 18, color: C.sand)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Journey',
                        style: T.ui(30, w: FontWeight.w700, ls: -.025))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: C.amber.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.amber.withValues(alpha: .28)),
                  ),
                  child: Row(children: [
                    const Icon(LucideIcons.sparkles, size: 16, color: C.amber),
                    const SizedBox(width: 6),
                    Text('${app.noor}', style: T.ui(14, c: C.amber, w: FontWeight.w800)),
                    Text(' Noor', style: T.ui(14, c: C.sand2)),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Level ${app.level}',
                        style: T.ui(13, c: C.amber, w: FontWeight.w700)),
                    Text(app.levelName, style: T.ui(26, w: FontWeight.w800, ls: -.03)),
                  ]),
                ),
                Text('${app.noor} / ${app.levelCeil}', style: T.ui(13, c: C.faint)),
              ]),
              const SizedBox(height: 12),
              _XpBar(value: pct),
              const SizedBox(height: 8),
              Text(
                  '${app.levelCeil - app.noor} Noor to Level ${app.level + 1} · ${levelNames[(app.level - 6).clamp(0, levelNames.length - 1)]}',
                  style: T.ui(13, c: C.muted, w: FontWeight.w500)),
              const SizedBox(height: 22),
              IntrinsicHeight(
                child: Row(children: [
                  _stat(LucideIcons.flame, C.flame, '${app.streak}', 'day streak'),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0x1FF7ECDC)),
                  _stat(LucideIcons.check, C.sage,
                      '${app.journeyDone}/${journeySteps.length}', 'today'),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0x1FF7ECDC)),
                  _stat(LucideIcons.medal, C.amber, '9', 'badges'),
                ]),
              ),
              const SizedBox(height: 28),
              const SectionTitle("Today's path"),
              const SizedBox(height: 4),
              const _VerticalPath(),
              const SizedBox(height: 10),
              const SectionTitle('Weekly quest', trailing: '3 days left'),
              const SizedBox(height: 12),
              Glass(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: C.sage.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(15)),
                      child: const Icon(LucideIcons.landmark, size: 22, color: C.sage),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('All five, on time', style: T.ui(16, w: FontWeight.w700)),
                        Text('Pray every prayer on time for 5 days',
                            style: T.ui(13, c: C.muted, w: FontWeight.w500)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    for (var i = 0; i < 5; i++)
                      Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(right: i < 4 ? 5 : 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i < 3 ? C.sage : C.sand.withValues(alpha: .1),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Text('3 of 5 days', style: T.ui(12.5, c: C.faint))),
                    const Icon(LucideIcons.sparkles, size: 13, color: C.amber),
                    const SizedBox(width: 5),
                    Text('+100 Noor · Lantern badge', style: T.ui(12.5, c: C.amber)),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),
              const SectionTitle('Badges', trailing: 'See all'),
              const SizedBox(height: 14),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: const [
                    _Badge('Fajr Hero', LucideIcons.sunrise,
                        [Color(0xFFFFE0A3), C.amberDeep]),
                    _Badge('7-day streak', LucideIcons.flame,
                        [Color(0xFFFFB38A), C.rose]),
                    _Badge('Night Reader', LucideIcons.bookOpen,
                        [Color(0xFFCFE3D5), Color(0xFF8FB59A)]),
                    _Badge('Khatam', LucideIcons.lock, null),
                    _Badge('Lantern', LucideIcons.lock, null),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle('Journeys', trailing: 'Explore'),
              const SizedBox(height: 4),
              _journeyRow(LucideIcons.sparkles, C.amber, '99 Names of Allah',
                  'Day 12 of 99', .12),
              const Hairline(),
              _journeyRow(LucideIcons.bookOpen, C.sage, 'Khatam in 30 days',
                  'Day 6 · 118 pages read', .2),
              const Hairline(),
              _journeyRow(LucideIcons.moon, C.rose, 'Seerah in 30 stories',
                  'Life of the Prophet ﷺ', null),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(IconData i, Color c, String v, String l) => Expanded(
        child: Column(children: [
          Icon(i, size: 22, color: c),
          const SizedBox(height: 3),
          Text(v, style: T.ui(20, w: FontWeight.w800, ls: -.02)),
          Text(l, style: T.ui(12, c: C.faint)),
        ]),
      );

  Widget _journeyRow(IconData i, Color c, String t, String sub, double? p) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Icon(i, size: 22, color: c),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: T.ui(15.5, w: FontWeight.w700)),
              Text(sub, style: T.ui(12.5, c: C.faint)),
              if (p != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: p,
                    minHeight: 4,
                    backgroundColor: C.sand.withValues(alpha: .1),
                    valueColor: const AlwaysStoppedAnimation(C.amber),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(width: 12),
          p == null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.amber.withValues(alpha: .4)),
                  ),
                  child: Text('Start', style: T.ui(13, c: C.amber, w: FontWeight.w700)),
                )
              : const Icon(LucideIcons.chevronRight, size: 16, color: C.faint),
        ]),
      );
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Container(
        height: 10,
        decoration: BoxDecoration(
          color: C.sand.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                    colors: [C.rose, C.amber, Color(0xFFFFE0A3)]),
                boxShadow: [BoxShadow(color: C.amber.withValues(alpha: .5), blurRadius: 12)],
              ),
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.icon, this.colors);
  final String label;
  final IconData icon;
  final List<Color>? colors;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 80,
        child: Column(children: [
          ClipPath(
            clipper: _StarClipper(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: colors == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors!),
                color: colors == null ? const Color(0xFF2A2430) : null,
              ),
              child: Icon(icon,
                  size: 24,
                  color: colors == null ? C.sand.withValues(alpha: .35) : C.ink),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: T.ui(11.5,
                  w: FontWeight.w700, c: colors == null ? C.faint : C.sand2)),
        ]),
      );
}

class _StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const pts = [
      [.5, 0], [.63, .13], [.82, .10], [.84, .30], [1, .42], [.90, .60],
      [.96, .80], [.76, .84], [.66, 1], [.5, .90], [.34, 1], [.24, .84],
      [.04, .80], [.10, .60], [0, .42], [.16, .30], [.18, .10], [.37, .13],
    ];
    final p = Path()..moveTo(pts[0][0] * s.width, pts[0][1] * s.height);
    for (final q in pts.skip(1)) {
      p.lineTo(q[0] * s.width, q[1] * s.height);
    }
    return p..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _VerticalPath extends StatelessWidget {
  const _VerticalPath();
  static const _xs = [.5, .78, .5, .22, .5, .78, .5, .22];
  static const _top = 40.0, _gap = 86.0;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pts = [
        for (var i = 0; i < _xs.length; i++) Offset(_xs[i] * w, _top + i * _gap)
      ];
      final h = _top + (_xs.length - 1) * _gap + 60;
      final children = <Widget>[
        Positioned.fill(
            child: CustomPaint(
                painter: TrailPainter(pts, app.journeyDone, horizontal: false))),
      ];
      for (var i = 0; i < journeySteps.length; i++) {
        final p = pts[i];
        final st = stateOf(i);
        final size = st == NodeState.now ? 68.0 : 58.0;
        final right = _xs[i] > .6;
        final s = journeySteps[i];
        children.add(Positioned(
          left: p.dx - size / 2,
          top: p.dy - size / 2,
          child: JourneyNode(index: i, onTap: () => openStepSheet(context, i)),
        ));
        children.add(Positioned(
          left: right ? p.dx - 170 : p.dx + 42,
          top: p.dy - 22,
          width: 128,
          child: Column(
            crossAxisAlignment:
                right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(s.title,
                  textAlign: right ? TextAlign.right : TextAlign.left,
                  style: T.ui(st == NodeState.now ? 14.5 : 13.5,
                      w: FontWeight.w700,
                      h: 1.25,
                      c: switch (st) {
                        NodeState.done => C.sand2,
                        NodeState.now => C.amber,
                        NodeState.lock => C.muted,
                      })),
              Text(
                  '${st == NodeState.now ? "You're here · " : ''}${stepTime(s)} · +${s.reward}',
                  textAlign: right ? TextAlign.right : TextAlign.left,
                  style: T.ui(11.5, c: C.faint)),
            ],
          ),
        ));
        if (st == NodeState.now) {
          final side = right ? 1 : (p.dx - 84 >= 0 ? -1 : 0);
          children.add(Positioned(
            left: side == 1
                ? p.dx + 40
                : side == -1
                    ? p.dx - 86
                    : p.dx - 23,
            top: side == 0 ? p.dy - 84 : p.dy - 30,
            child: const HoppingMascot(size: 46),
          ));
        }
      }
      final g = pts.last;
      children.add(Positioned(left: g.dx - 31, top: g.dy - 31, child: const GiftNode()));
      children.add(Positioned(
        left: g.dx + 42,
        top: g.dy - 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Day complete', style: T.ui(13.5, w: FontWeight.w700, c: C.muted)),
          Text('+50 Noor · streak day ${app.streak + 1}',
              style: T.ui(11.5, c: C.faint)),
        ]),
      ));
      return SizedBox(height: h, child: Stack(clipBehavior: Clip.none, children: children));
    });
  }
}
