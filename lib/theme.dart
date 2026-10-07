import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ilm colour palette: "Quiet ink" background with warm amber accents.
class C {
  static const bg = Color(0xFF141118);
  static const ink = Color(0xFF15121B);
  static const sand = Color(0xFFF7ECDC);
  static const sand2 = Color(0xFFE9D8C0);
  static const muted = Color(0xFFC8B6A4);
  static const faint = Color(0xFF9D8C80);
  static const amber = Color(0xFFF1B56E);
  static const amberLight = Color(0xFFF7C589);
  static const amberDeep = Color(0xFFE9A25E);
  static const sage = Color(0xFFA7C4AE);
  static const rose = Color(0xFFE0787A);
  static const plum = Color(0xFF9E5E78);
  static const flame = Color(0xFFF7A55A);
  static const lockNode = Color(0xFF221D27);

  static Color line([double a = .07]) => sand.withValues(alpha: a);

  static const amberGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [amberLight, amberDeep],
  );
  static const yunGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amberLight, rose, plum],
    stops: [0, .6, 1],
  );
}

/// Palette for content sitting on an orange glass sheet. White carries the
/// text; dark ink marks what is selected or actionable.
class S {
  static const text = Colors.white;
  static final muted = Colors.white.withValues(alpha: .86);
  static final faint = Colors.white.withValues(alpha: .7);
  static const accent = C.ink;
  static Color fill([double a = .16]) => Colors.white.withValues(alpha: a);
  static Color line([double a = .28]) => Colors.white.withValues(alpha: a);
}

class T {
  static TextStyle ui(double size,
          {FontWeight w = FontWeight.w600,
          Color c = C.sand,
          double ls = 0,
          double? h}) =>
      GoogleFonts.urbanist(
          fontSize: size,
          fontWeight: w,
          color: c,
          letterSpacing: size * ls,
          height: h,
          fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle arabic(double size, {Color c = C.sand, double h = 2}) =>
      GoogleFonts.scheherazadeNew(fontSize: size, color: c, height: h);

  static TextStyle calligraphy(double size, {Color c = C.sage}) =>
      GoogleFonts.arefRuqaa(
          fontSize: size, color: c, fontWeight: FontWeight.w700, height: 1.3);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.amber,
      secondary: C.sage,
      surface: C.bg,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: GoogleFonts.urbanistTextTheme(base.textTheme)
        .apply(bodyColor: C.sand, displayColor: C.sand),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.amber,
      selectionColor: Color(0x55F1B56E),
      selectionHandleColor: C.amber,
    ),
  );
}

/// Frosted glass surface used for the tab bar, sheets and the ayah card.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.blur = 24,
    this.tint = .09,
    this.strong = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double tint;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: strong
                  ? [
                      const Color(0xFF2C202E).withValues(alpha: .72),
                      const Color(0xFF1E1822).withValues(alpha: .78),
                    ]
                  : [
                      Colors.white.withValues(alpha: tint + .04),
                      Colors.white.withValues(alpha: tint - .04),
                    ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Thin horizontal rule used between cardless rows.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.alpha = .07});
  final double alpha;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: C.line(alpha));
}

/// Primary action at the foot of a sheet: solid white on the orange glass.
class SheetButton extends StatelessWidget {
  const SheetButton(
      {super.key, required this.label, this.onTap, this.enabled = true});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: enabled ? Colors.white : S.fill(.18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: const Color(0xFF7A3F12).withValues(alpha: .35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -8)
                ]
              : null,
        ),
        child: Text(label,
            style: T.ui(16,
                w: FontWeight.w700, c: enabled ? C.ink : S.faint)),
      ),
    );
  }
}

/// Orange glass bottom sheet, anchored to the bottom edge with rounded top
/// corners. [heightFactor] fixes its height as a share of the screen; [tall]
/// is the same at .86. Otherwise it hugs its content.
Future<R?> showGlassSheet<R>(BuildContext context,
    {required Widget Function(BuildContext) builder,
    bool tall = false,
    double? heightFactor}) {
  final fixed = heightFactor ?? (tall ? .86 : null);
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C0E0A10),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SheetSurface(
          height: fixed == null ? null : mq.size.height * fixed,
          maxHeight: mq.size.height * .88,
          bottomInset: mq.viewInsets.bottom > 0 ? 0 : mq.viewPadding.bottom,
          child: fixed != null
              ? builder(ctx)
              : Flexible(child: SingleChildScrollView(child: builder(ctx))),
        ),
      );
    },
  );
}

/// The orange glass itself: blur, translucent amber, bright top rim, handle.
class SheetSurface extends StatelessWidget {
  const SheetSurface(
      {super.key,
      required this.child,
      this.height,
      required this.maxHeight,
      this.bottomInset = 0});
  final Widget child;
  final double? height;
  final double maxHeight;
  final double bottomInset;

  static const _radius = BorderRadius.vertical(top: Radius.circular(32));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
        child: Container(
          height: height,
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: EdgeInsets.fromLTRB(22, 10, 22, bottomInset + 14),
          decoration: BoxDecoration(
            borderRadius: _radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                C.amberLight.withValues(alpha: .72),
                C.amberDeep.withValues(alpha: .62),
              ],
            ),
            border: Border(top: BorderSide(color: S.line(.55))),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: S.text),
            child: Column(
              mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: S.line(.55),
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                if (height != null) Expanded(child: child) else child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Title + optional subtitle used at the top of sheets.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.sub});
  final String title;
  final String? sub;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: T.ui(22, w: FontWeight.w700, c: S.text, ls: -.02)),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!, style: T.ui(14, c: S.muted, w: FontWeight.w500)),
            ],
          ],
        ),
      );
}

/// Selectable row used inside sheets.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? sub;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? S.fill(.32) : S.fill(.12),
          border: Border.all(color: selected ? Colors.white : S.line(.22)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: selected ? S.accent : S.text),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.ui(15.5, w: FontWeight.w700, c: S.text)),
              if (sub != null)
                Text(sub!, style: T.ui(12.5, c: S.muted, w: FontWeight.w500)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? S.accent : S.line(.6),
                  width: selected ? 6 : 2),
            ),
          ),
        ]),
      ),
    );
  }
}
