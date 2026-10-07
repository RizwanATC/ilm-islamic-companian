import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens/chat_sheet.dart';
import 'screens/explore.dart';
import 'screens/home_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/quran_screen.dart';
import 'services/prayer_alerts.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: C.bg,
  ));
  runApp(const IlmApp());
}

class IlmApp extends StatelessWidget {
  const IlmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ilm',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Boot(),
      );
}

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late final Future<void> _init = AppState.instance.init();

  @override
  void initState() {
    super.initState();
    // Alerts start after the times are known; the permission prompt shows
    // over Home rather than holding up the splash.
    _init.whenComplete(() async {
      await PrayerAlerts.instance.init();
      PrayerAlerts.instance.reschedule();
      // flutter run --dart-define=ILM_TEST_ALERT=true fires a sample alert.
      if (kDebugMode && const bool.fromEnvironment('ILM_TEST_ALERT')) {
        await PrayerAlerts.instance.test(after: const Duration(seconds: 20));
      }
    });
  }
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _init,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Scaffold(
              body: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ilm', style: T.ui(44, w: FontWeight.w800, ls: -.04)),
                  const SizedBox(height: 6),
                  Text('Finding your prayer zone…', style: T.ui(14, c: C.faint)),
                ]),
              ),
            );
          }
          return const Shell();
        },
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  bool _compact = false;
  final _controllers = List.generate(3, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      _controllers[i].addListener(() {
        if (i != _tab) return;
        final c = _controllers[i].offset > 24;
        if (c != _compact) setState(() => _compact = c);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _open(int i) {
    if (AppState.instance.haptics) HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      _compact = _controllers[i].hasClients && _controllers[i].offset > 24;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) => Stack(children: [
          const Positioned.fill(child: _Backdrop()),
          IndexedStack(index: _tab, children: [
            HomeScreen(onOpenTab: _open, controller: _controllers[0]),
            PrayerScreen(controller: _controllers[1], onOpenSettings: () => openSettings(context)),
            QuranScreen(controller: _controllers[2]),
          ]),
          _YunButton(bottom: bottom, compact: _compact),
          _TabBar(
            index: _tab,
            compact: _compact,
            bottom: bottom,
            onTap: _open,
            onExplore: () {
              if (AppState.instance.haptics) HapticFeedback.selectionClick();
              showExploreSheet(context);
            },
          ),
        ]),
      ),
    );
  }
}

/// Quiet ink background with one soft amber glow at the top.
class _Backdrop extends StatelessWidget {
  const _Backdrop();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.25),
            radius: 1.1,
            colors: [Color(0x33F1B56E), Color(0x00141118)],
          ),
        ),
      );
}

class _TabBar extends StatefulWidget {
  const _TabBar(
      {required this.index,
      required this.compact,
      required this.bottom,
      required this.onTap,
      required this.onExplore});
  final int index;
  final bool compact;
  final double bottom;
  final void Function(int) onTap;
  final VoidCallback onExplore;

  /// The three tabs the glass lens slides between; Explore sits in the last
  /// slot and opens a sheet instead.
  static const _icons = [
    (LucideIcons.house, 'Home'),
    (LucideIcons.landmark, 'Prayer'),
    (LucideIcons.bookOpen, 'Quran'),
  ];
  static const _last = 2;

  @override
  State<_TabBar> createState() => _TabBarState();
}

/// The active tab is a glass lens that glides between slots, stretching
/// mid-flight like a droplet, and can be dragged along the bar to scrub tabs.
class _TabBarState extends State<_TabBar> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
    ..addListener(_tick);
  late double _pos = widget.index.toDouble();
  double _from = 0, _to = 0;
  bool _dragging = false;

  @override
  void didUpdateWidget(_TabBar old) {
    super.didUpdateWidget(old);
    final to = widget.index.toDouble();
    if (!_dragging && widget.index != old.index && !(_ctrl.isAnimating && _to == to)) _glide(to);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _glide(double to) {
    _from = _pos;
    _to = to;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      setState(() => _pos = to);
      return;
    }
    _ctrl.forward(from: 0);
  }

  void _tick() => setState(() => _pos = _from + (_to - _from) * Curves.easeOutCubic.transform(_ctrl.value));

  /// 0 at rest, peaks mid-glide, scaled by how far the lens travels.
  double get _stretch {
    if (_dragging) return .08;
    if (!_ctrl.isAnimating) return 0;
    return math.sin(math.pi * _ctrl.value) * (.18 * (_to - _from).abs()).clamp(0, .42);
  }

  void _dragStart(DragStartDetails _) {
    _ctrl.stop();
    setState(() => _dragging = true);
  }

  void _dragUpdate(DragUpdateDetails d, double slot) =>
      setState(() => _pos = (_pos + d.delta.dx / slot).clamp(0, _TabBar._last).toDouble());

  void _dragEnd(DragEndDetails d, double slot) {
    final flick = (d.primaryVelocity ?? 0) / slot * .12;
    final target = (_pos + flick).round().clamp(0, _TabBar._last);
    setState(() => _dragging = false);
    _glide(target.toDouble());
    if (target != widget.index) widget.onTap(target);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final w = MediaQuery.of(context).size.width;
    final side = compact ? 64.0 : 24.0;
    final h = compact ? 54.0 : 66.0;
    final pad = compact ? 6.0 : 8.0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      left: side,
      right: side,
      bottom: (compact ? 2 : 6) + widget.bottom,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              color: const Color(0xFF28202C).withValues(alpha: .55),
              border: Border.all(color: const Color(0x2EFFECD6)),
            ),
            child: LayoutBuilder(builder: (context, box) {
              final slot = box.maxWidth / 4;
              final grow = slot * _stretch;
              final lensH = box.maxHeight * (1 - _stretch * .22);
              return GestureDetector(
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: (d) => _dragUpdate(d, slot),
                onHorizontalDragEnd: (d) => _dragEnd(d, slot),
                child: Stack(children: [
                  Positioned(
                    left: _pos * slot - grow / 2,
                    top: (box.maxHeight - lensH) / 2,
                    width: slot + grow,
                    height: lensH,
                    child: AnimatedScale(
                      scale: _dragging ? 1.06 : 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _GlassLens(radius: lensH / 2),
                    ),
                  ),
                  Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (var i = 0; i < _TabBar._icons.length; i++)
                      Expanded(
                        child: Semantics(
                          label: _TabBar._icons[i].$2,
                          button: true,
                          selected: i == widget.index,
                          child: GestureDetector(
                            onTap: () => widget.onTap(i),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(_TabBar._icons[i].$1,
                                size: compact ? 21 : (w < 360 ? 22 : 25),
                                // Icons light up as the lens passes over them.
                                color: Color.lerp(C.faint, C.amberLight,
                                    (1 - (i - _pos).abs()).clamp(0, 1).toDouble())),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Semantics(
                        label: 'Explore',
                        button: true,
                        child: GestureDetector(
                          onTap: widget.onExplore,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(LucideIcons.layoutGrid,
                              size: compact ? 21 : (w < 360 ? 22 : 25), color: C.faint),
                        ),
                      ),
                    ),
                  ]),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Clear, warm-tinted glass: a bright specular rim on top, a faint amber
/// caustic at the bottom, and a soft drop so it floats over the bar.
class _GlassLens extends StatelessWidget {
  const _GlassLens({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .20),
            Colors.white.withValues(alpha: .06),
            C.amber.withValues(alpha: .16),
          ],
          stops: const [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -6),
        ],
      ),
      child: CustomPaint(painter: _RimPainter(radius)),
    );
  }
}

/// Gradient hairline: bright along the top edge, fading to a warm glint below.
class _RimPainter extends CustomPainter {
  _RimPainter(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final rr = RRect.fromRectAndRadius(rect.deflate(.5), Radius.circular(radius));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .55),
            Colors.white.withValues(alpha: .08),
            C.amberLight.withValues(alpha: .35),
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.radius != radius;
}

class _YunButton extends StatefulWidget {
  const _YunButton({required this.bottom, required this.compact});
  final double bottom;
  final bool compact;
  @override
  State<_YunButton> createState() => _YunButtonState();
}

class _YunButtonState extends State<_YunButton> with TickerProviderStateMixin {
  late final _ring =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ring.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final base = widget.bottom + (widget.compact ? 70 : 86);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      right: 22,
      bottom: base,
      child: GestureDetector(
        onTap: () => openChat(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
                offset: Offset(0, -5 * Curves.easeInOut.transform(_bob.value)),
                child: child),
            child: Glass(
              radius: 13,
              tint: .12,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Text('Ask ${app.botName}', style: T.ui(12, w: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 60,
            height: 72,
            child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
              Positioned(
                bottom: 4,
                child: AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) => Transform.scale(
                    scale: .85 + .5 * _ring.value,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: C.amber.withValues(alpha: .5 * (1 - _ring.value)),
                            width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: C.yunGradient,
                    boxShadow: [
                      BoxShadow(
                          color: C.rose.withValues(alpha: .7),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                          spreadRadius: -10)
                    ],
                  ),
                ),
              ),
              // Mascot peeks out above the circle; bottom half is clipped to it.
              Positioned(
                bottom: 4,
                child: ClipPath(
                  clipper: _PeekClipper(),
                  child: const SizedBox(width: 72, height: 72, child: Mascot(size: 72)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Everything above the circle's centre, plus the circle itself.
class _PeekClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const r = 26.0;
    final c = Offset(s.width / 2, s.height - r);
    return Path()
      ..addRect(Rect.fromLTRB(0, 0, s.width, c.dy))
      ..addOval(Rect.fromCircle(center: c, radius: r - .5));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
