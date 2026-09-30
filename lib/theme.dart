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

/// Amber pill button.
class AmberButton extends StatelessWidget {
  const AmberButton(
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
          gradient: enabled ? C.amberGradient : null,
          color: enabled ? null : C.sand.withValues(alpha: .1),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: C.amber.withValues(alpha: .45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -10)
                ]
              : null,
        ),
        child: Text(label,
            style: T.ui(16,
                w: FontWeight.w700, c: enabled ? C.ink : C.muted)),
      ),
    );
  }
}

/// Opens a frosted-glass bottom sheet.
Future<R?> showGlassSheet<R>(BuildContext context,
    {required Widget Function(BuildContext) builder, bool tall = false}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x590E0A10),
    builder: (ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return Padding(
        padding: EdgeInsets.fromLTRB(
            10, 0, 10, 10 + MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: h * .88),
          child: SizedBox(
            height: tall ? h * .86 : null,
            child: Glass(
              radius: 36,
              strong: true,
              blur: 34,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: C.sand.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  if (tall)
                    Expanded(child: builder(ctx))
                  else
                    Flexible(child: SingleChildScrollView(child: builder(ctx))),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
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
            Text(title, style: T.ui(22, w: FontWeight.w700, ls: -.02)),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!, style: T.ui(14, c: C.muted, w: FontWeight.w500)),
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
          color: selected
              ? C.amber.withValues(alpha: .16)
              : C.sand.withValues(alpha: .05),
          border: Border.all(
              color: selected
                  ? C.amber.withValues(alpha: .45)
                  : C.sand.withValues(alpha: .08)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: selected ? C.amber : C.sand2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.ui(15.5, w: FontWeight.w700)),
              if (sub != null)
                Text(sub!, style: T.ui(12.5, c: C.faint, w: FontWeight.w500)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? C.amber : C.sand.withValues(alpha: .3),
                  width: selected ? 6 : 2),
            ),
          ),
        ]),
      ),
    );
  }
}
