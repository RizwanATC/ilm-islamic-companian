import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/quran_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/journey_path.dart';
import '../widgets/sky_arc_card.dart';
import 'journey_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab, required this.controller});
  final void Function(int) onOpenTab;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 200),
      children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE6A39A), C.plum]),
            ),
            child: Text(app.userName[0],
                style: T.ui(17, w: FontWeight.w700, c: C.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Assalamu alaikum', style: T.ui(13, c: C.muted, w: FontWeight.w500)),
              Text(app.userName, style: T.ui(20, w: FontWeight.w700, ls: -.015)),
            ]),
          ),
          LocationLabel(onTap: () => onOpenTab(3)),
        ]),
        const SizedBox(height: 26),
        SkyArcPrayerCard(onTap: () => onOpenTab(1)),
        const SizedBox(height: 30),
        HomeJourney(onOpen: () => openJourney(context)),
        const SizedBox(height: 12),
        const AyahCard(),
        const SizedBox(height: 26),
        ContinueReading(onPlay: () => onOpenTab(2), onAll: () => onOpenTab(2)),
        const SizedBox(height: 14),
        SavedRow(onTap: () => onOpenTab(2)),
      ],
    );
  }
}

class LocationLabel extends StatelessWidget {
  const LocationLabel({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.mapPin, size: 16, color: C.amber),
          const SizedBox(width: 6),
          Flexible(
            child: Text(app.placeName,
                overflow: TextOverflow.ellipsis,
                style: T.ui(14.5, c: C.sand2)),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ journey

class HomeJourney extends StatefulWidget {
  const HomeJourney({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  State<HomeJourney> createState() => _HomeJourneyState();
}

class _HomeJourneyState extends State<HomeJourney> {
  final _scroll = ScrollController();
  static const _x0 = 40.0, _gap = 92.0, _h = 180.0;
  static const _ys = [106.0, 82.0];
  int _lastDone = -1;

  List<Offset> get _pts => [
        for (var i = 0; i <= journeySteps.length; i++)
          Offset(_x0 + i * _gap, _ys[i % 2]),
      ];

  void _scrollToCurrent() {
    final d = AppState.instance.journeyDone;
    if (d == _lastDone || !_scroll.hasClients) return;
    _lastDone = d;
    final target = (_x0 + d.clamp(0, 6) * _gap - 150)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final pts = _pts;
    final width = _x0 * 2 + journeySteps.length * _gap;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text("Today's journey",
                style: T.ui(18, w: FontWeight.w700, ls: -.01))),
        GestureDetector(
          onTap: widget.onOpen,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: C.amber.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(9)),
              child: Text('${app.journeyDone}/${journeySteps.length}',
                  style: T.ui(13.5, c: C.amber, w: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Text('Open', style: T.ui(13.5, c: C.sand2, w: FontWeight.w700)),
            const Icon(LucideIcons.chevronRight, size: 15, color: C.sand2),
          ]),
        ),
      ]),
      SizedBox(
        height: _h,
        child: OverflowBox(
          maxWidth: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: width,
              height: _h,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: TrailPainter(pts, app.journeyDone, horizontal: true)),
                ),
                for (var i = 0; i < journeySteps.length; i++) ..._node(context, i, pts[i]),
                Positioned(
                  left: pts.last.dx - 24,
                  top: pts.last.dy - 24,
                  child: const GiftNode(size: 48),
                ),
                _label(pts.last, 'Complete', '+50',
                    app.journeyDone >= journeySteps.length ? NodeState.done : NodeState.lock),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  List<Widget> _node(BuildContext context, int i, Offset p) {
    final st = stateOf(i);
    final s = st == NodeState.now ? 58.0 : 48.0;
    return [
      Positioned(
        left: p.dx - s / 2,
        top: p.dy - s / 2,
        child: JourneyNode(
            index: i, size: 48, onTap: () => openStepSheet(context, i)),
      ),
      _label(p, journeySteps[i].short, '+${journeySteps[i].reward}', st),
      if (st == NodeState.now)
        Positioned(
            left: p.dx - 22,
            top: p.dy - 80,
            child: const HoppingMascot(size: 44)),
    ];
  }

  Widget _label(Offset p, String t, String sub, NodeState st) => Positioned(
        left: p.dx - 45,
        top: p.dy + 36,
        width: 90,
        child: Column(children: [
          Text(t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.ui(12.5,
                  w: FontWeight.w700,
                  c: switch (st) {
                    NodeState.done => C.sand2,
                    NodeState.now => C.amber,
                    NodeState.lock => C.muted,
                  })),
          Text(sub,
              style: T.ui(11,
                  w: FontWeight.w700,
                  c: st == NodeState.now ? C.amber : C.faint)),
        ]),
      );
}

// ------------------------------------------------------------------ ayah

class AyahCard extends StatefulWidget {
  const AyahCard({super.key});
  @override
  State<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<AyahCard> {
  static const _dur = 120; // ticks of 100ms = 12s recitation
  Timer? _timer;
  int _t = 0;
  bool _playing = true;
  final _bars = List.generate(
      30, (i) => .25 + (math.sin(i * 1.7)).abs() * .55 + ((i * 37) % 10) / 50);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_playing && mounted) setState(() => _t = (_t + 1) % (_dur + 10));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = math.min(_t / _dur, 1.0);
    final k = (f * ayahWords.length).floor();
    final reciter = reciters[AppState.instance.reciter].$1;
    return Glass(
      radius: 30,
      tint: .09,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: Column(children: [
        Text('AYAH OF THE DAY',
            style: T.ui(11, w: FontWeight.w800, c: C.sand2, ls: .14)),
        Container(
            width: 34,
            height: 2,
            margin: const EdgeInsets.only(top: 10),
            color: C.amber.withValues(alpha: .7)),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              for (var i = 0; i < ayahWords.length; i++)
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  style: T.arabic(23,
                      c: i == k && f < 1
                          ? C.amber
                          : (i < k || f >= 1)
                              ? C.sand
                              : C.sand.withValues(alpha: .42)),
                  child: Text(ayahWords[i]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(ayahTranslation,
            textAlign: TextAlign.center,
            style: T.ui(14.5, w: FontWeight.w600, h: 1.5)),
        const SizedBox(height: 12),
        Text(ayahRef, style: T.ui(12, c: C.faint, w: FontWeight.w700)),
        const SizedBox(height: 22),
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _playing = !_playing),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: C.amberGradient,
                boxShadow: [
                  BoxShadow(
                      color: C.amber.withValues(alpha: .5),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -8)
                ],
              ),
              child: Icon(_playing ? LucideIcons.pause : LucideIcons.play,
                  size: 19, color: C.ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 34,
              child: Row(children: [
                for (var i = 0; i < _bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.2),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 34 *
                              _bars[i] *
                              (_playing && i / _bars.length < f
                                  ? (.7 + .3 * math.sin(_t * .6 + i).abs())
                                  : 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i / _bars.length < f
                                ? C.amber
                                : C.sand.withValues(alpha: .2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 64, top: 8),
          child: Row(children: [
            Expanded(
                child: Text(reciter,
                    overflow: TextOverflow.ellipsis,
                    style: T.ui(11.5, c: C.faint))),
            Text('0:${(f * 12).round().toString().padLeft(2, '0')} / 0:12',
                style: T.ui(11.5, c: C.faint)),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ continue

class ContinueReading extends StatelessWidget {
  const ContinueReading({super.key, this.onPlay, this.onAll, this.showHeader = true, this.trailing});
  final VoidCallback? onPlay;
  final VoidCallback? onAll;
  final bool showHeader;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final s = surah(app.lastSurah);
    final frac = app.lastAyah / s.ayahs;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showHeader)
        SectionTitle('Continue reading',
            trailing: trailing ?? 'All saved', onTap: trailing == null ? onAll : null),
      const SizedBox(height: 14),
      SizedBox(
        height: 76,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            right: 58,
            top: -8,
            child: IgnorePointer(
              child: Opacity(
                opacity: .13,
                child: Text(s.arabic,
                    textDirection: TextDirection.rtl,
                    style: T.calligraphy(66)),
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: T.ui(24, w: FontWeight.w800, ls: -.03)),
                    Text('Ayah ${app.lastAyah} of ${s.ayahs}',
                        style: T.ui(13.5, c: C.muted)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 4,
                        backgroundColor: C.sand.withValues(alpha: .1),
                        valueColor: const AlwaysStoppedAnimation(C.sage),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: C.amberGradient,
                  boxShadow: [
                    BoxShadow(
                        color: C.amber.withValues(alpha: .5),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: -8)
                  ],
                ),
                child: const Icon(LucideIcons.play, size: 19, color: C.ink),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

/// Bookmarked surahs separated by thin vertical lines.
class SavedRow extends StatelessWidget {
  const SavedRow({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final saved = AppState.instance.bookmarks.toList()..sort();
    if (saved.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (var i = 0; i < saved.length; i++) ...[
          if (i > 0)
            Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: C.sand.withValues(alpha: .18)),
          GestureDetector(
            onTap: onTap,
            child: Row(children: [
              const Icon(LucideIcons.bookmark, size: 15, color: C.amber),
              const SizedBox(width: 7),
              Text(surah(saved[i]).name,
                  style: T.ui(13.5, c: C.sand2, w: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('${saved[i]}:1', style: T.ui(13.5, c: C.faint)),
            ]),
          ),
        ],
      ]),
    );
  }
}
