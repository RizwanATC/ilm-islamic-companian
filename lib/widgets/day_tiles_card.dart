import 'package:flutter/material.dart';

import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Home "today's prayers" card: one tile per prayer. The next prayer's tile
/// opens wide with its countdown, past ones fade with a tick, and upcoming
/// ones show only their time.
class DayTilesPrayerCard extends StatelessWidget {
  const DayTilesPrayerCard({super.key, this.onTap});
  final VoidCallback? onTap;

  static const _gap = 6.0;
  static const _height = 132.0;
  static const _grow = 2.6; // width of the next tile, in small-tile units
  static const _dur = Duration(milliseconds: 700);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Ticker(builder: (context, now) {
      final (next, at, _) = app.nextPrayer(now);
      final idx = fardPrayers.indexOf(next);
      final today = app.today;
      final tint = prayerTint(next);

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Text("Today's prayers",
                    style: T.ui(18, w: FontWeight.w800, ls: -.01))),
            Text('${5 - idx} left',
                style: T.ui(12.5, c: C.muted, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: _height,
            child: LayoutBuilder(builder: (context, c) {
              final unit = (c.maxWidth - 4 * _gap) / (4 + _grow);
              final bigW = unit * _grow;
              return Row(children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _Tile(
                    prayer: fardPrayers[i],
                    // The next tile shows the real next time (tomorrow's
                    // Fajr after Isha); the others show today's.
                    time: i == idx ? at : today[fardPrayers[i]],
                    state: i < idx
                        ? _TileState.done
                        : i == idx
                            ? _TileState.next
                            : _TileState.upcoming,
                    width: i == idx ? bigW : unit,
                    bigWidth: bigW,
                    tint: tint,
                    left: at.difference(now),
                  ),
                ],
              ]);
            }),
          ),
        ]),
      );
    });
  }
}

enum _TileState { done, next, upcoming }

class _Tile extends StatelessWidget {
  const _Tile({
    required this.prayer,
    required this.time,
    required this.state,
    required this.width,
    required this.bigWidth,
    required this.tint,
    required this.left,
  });

  final Prayer prayer;
  final DateTime time;
  final _TileState state;
  final double width, bigWidth;
  final Color tint;
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final isNext = state == _TileState.next;
    final done = state == _TileState.done;
    final r = BorderRadius.circular(20);

    return AnimatedOpacity(
      duration: DayTilesPrayerCard._dur,
      opacity: done ? .5 : 1,
      child: AnimatedContainer(
        duration: DayTilesPrayerCard._dur,
        curve: DayTilesPrayerCard._curve,
        width: width,
        height: DayTilesPrayerCard._height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: r,
          color: isNext ? null : C.sand.withValues(alpha: .05),
          gradient: isNext
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: .34),
                    C.sand.withValues(alpha: .06),
                  ],
                  stops: const [0, .7],
                )
              : null,
          border: Border.all(
              color: isNext
                  ? tint.withValues(alpha: .5)
                  : C.sand.withValues(alpha: .08)),
          boxShadow: isNext
              ? [
                  BoxShadow(
                      color: tint.withValues(alpha: .45),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                      spreadRadius: -16),
                ]
              : null,
        ),
        child: Stack(children: [
          if (isNext)
            // Laid out at full size so text never squeezes while the tile
            // grows; the tile's clip hides the rest mid-animation.
            OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: bigWidth,
              maxWidth: bigWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrayerIcon(prayer, size: 34),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(prayer.label,
                          style: T.ui(22,
                              w: FontWeight.w800, ls: -.03, h: 1)),
                    ),
                    const SizedBox(height: 3),
                    Text(hmA(time),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: T.ui(12.5, c: C.sand2)),
                    const SizedBox(height: 8),
                    Row(children: [
                      PulseDot(color: tint),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(countdown(left),
                              style: T.ui(14, w: FontWeight.w800)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            )
          else
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
                child: Column(children: [
                  ColorFiltered(
                    colorFilter: done
                        ? const ColorFilter.matrix(_desaturate)
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst),
                    child: PrayerIcon(prayer, size: 26),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(hm(time),
                        style: T.ui(12.5, c: C.sand2, w: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          if (done)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 14,
                height: 14,
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: C.rose),
                child: const Icon(Icons.check_rounded, size: 10, color: C.ink),
              ),
            ),
        ]),
      ),
    );
  }

  // 60% desaturation, for the icons of prayers that have passed.
  static const _desaturate = <double>[
    .6228, .4292, .0480, 0, 0, //
    .1308, .9212, .0480, 0, 0, //
    .1308, .4292, .5400, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
