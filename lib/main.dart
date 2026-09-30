import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens/chat_sheet.dart';
import 'screens/home_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
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
  final _controllers = List.generate(4, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 4; i++) {
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
            PrayerScreen(controller: _controllers[1], onOpenSettings: () => _open(3)),
            QuranScreen(controller: _controllers[2]),
            SettingsScreen(controller: _controllers[3]),
          ]),
          _YunButton(bottom: bottom, compact: _compact),
          _TabBar(index: _tab, compact: _compact, bottom: bottom, onTap: _open),
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

class _TabBar extends StatelessWidget {
  const _TabBar(
      {required this.index, required this.compact, required this.bottom, required this.onTap});
  final int index;
  final bool compact;
  final double bottom;
  final void Function(int) onTap;

  static const _icons = [
    (LucideIcons.house, 'Home'),
    (LucideIcons.landmark, 'Prayer'),
    (LucideIcons.bookOpen, 'Quran'),
    (LucideIcons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final side = compact ? 64.0 : 24.0;
    final h = compact ? 54.0 : 66.0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      left: side,
      right: side,
      bottom: (compact ? 12 : 18) + bottom,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              color: const Color(0xFF28202C).withValues(alpha: .55),
              border: Border.all(color: const Color(0x2EFFECD6)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Semantics(
                    label: _icons[i].$2,
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(h / 2),
                          gradient: i == index ? C.amberGradient : null,
                          boxShadow: i == index
                              ? [
                                  BoxShadow(
                                      color: C.amber.withValues(alpha: .55),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                      spreadRadius: -6)
                                ]
                              : null,
                        ),
                        child: Icon(_icons[i].$1,
                            size: compact ? 21 : (w < 360 ? 22 : 25),
                            color: i == index ? C.ink : C.faint),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
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
    final base = widget.bottom + (widget.compact ? 80 : 98);
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
