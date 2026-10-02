import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/quran_data.dart';
import '../services/prayer_service.dart';
import '../services/zone_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

// ------------------------------------------------------------------ qibla

void showQiblaSheet(BuildContext context) {
  final app = AppState.instance;
  final b = app.qiblaBearing;
  showGlassSheet(context, builder: (ctx) {
    return Column(children: [
      SheetTitle('Qibla',
          sub: '${b.toStringAsFixed(0)}° from true north · ${app.placeName}'),
      const SizedBox(height: 20),
      SizedBox(
        width: 230,
        height: 230,
        child: CustomPaint(painter: _QiblaPainter(b)),
      ),
      const SizedBox(height: 14),
      Text(
          'Face north, then turn until you face the gold arrow. '
          'A live compass needs the phone\'s magnetometer, which comes next.',
          textAlign: TextAlign.center,
          style: T.ui(13.5, c: S.muted, w: FontWeight.w500, h: 1.45)),
      const SizedBox(height: 18),
      SheetButton(label: 'Got it', onTap: () => Navigator.pop(ctx)),
    ]);
  });
}

class _QiblaPainter extends CustomPainter {
  _QiblaPainter(this.bearing);
  final double bearing;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = S.line(.45));
    for (var i = 0; i < 72; i++) {
      final a = i * math.pi / 36;
      final len = i % 18 == 0 ? 10.0 : 4.0;
      final p1 = c + Offset(math.sin(a), -math.cos(a)) * (r - 4);
      final p2 = c + Offset(math.sin(a), -math.cos(a)) * (r - 4 - len);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: i % 18 == 0 ? .9 : .4));
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: T.ui(13, w: FontWeight.w700, c: i == 0 ? S.accent : S.text)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          c + Offset(math.sin(a), -math.cos(a)) * (r - 26) - tp.size.center(Offset.zero));
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(bearing * math.pi / 180);
    final arrow = Path()
      ..moveTo(0, -r + 34)
      ..lineTo(12, 0)
      ..lineTo(-12, 0)
      ..close();
    canvas.drawPath(arrow, Paint()..color = C.ink);
    final tail = Path()
      ..moveTo(0, r - 40)
      ..lineTo(12, 0)
      ..lineTo(-12, 0)
      ..close();
    canvas.drawPath(tail, Paint()..color = S.line(.4));
    final kaaba = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -r + 26), width: 18, height: 18),
        const Radius.circular(3));
    canvas.drawRRect(kaaba, Paint()..color = C.ink);
    canvas.drawRRect(
        kaaba,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white);
    canvas.restore();
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_QiblaPainter old) => old.bearing != bearing;
}

// ------------------------------------------------------------------ method

void showMethodSheet(BuildContext context) {
  final app = AppState.instance;
  showGlassSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      if (app.inMalaysia) {
        return Column(children: [
          SheetTitle('Calculation method',
              sub: 'Official times for ${app.zoneCode}'),
          const SizedBox(height: 18),
          const OptionRow(
              icon: LucideIcons.badgeCheck,
              title: 'JAKIM e-Solat',
              sub: 'Jabatan Kemajuan Islam Malaysia',
              selected: true),
          const SizedBox(height: 8),
          Text(
              'In Malaysia, Ilm uses the official JAKIM timetable for your zone. '
              'Other methods are used when you travel outside Malaysia.',
              style: T.ui(13.5, c: S.muted, w: FontWeight.w500, h: 1.45)),
          const SizedBox(height: 18),
          SheetButton(label: 'Done', onTap: () => Navigator.pop(ctx)),
        ]);
      }
      return Column(children: [
        const SheetTitle('Calculation method', sub: 'Used for Fajr and Isha angles'),
        const SizedBox(height: 18),
        for (final m in Method.values)
          OptionRow(
            icon: LucideIcons.calculator,
            title: m.label,
            sub: m.angles,
            selected: app.method == m,
            onTap: () async {
              await app.setMethod(m);
              set(() {});
            },
          ),
        const SizedBox(height: 10),
        SheetButton(label: 'Done', onTap: () => Navigator.pop(ctx)),
      ]);
    });
  });
}

// ------------------------------------------------------------------ adhan

void showAdhanSheet(BuildContext context) {
  final app = AppState.instance;
  showGlassSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      return Column(children: [
        const SheetTitle('Adhan sound', sub: 'How prayer alerts sound'),
        const SizedBox(height: 18),
        for (final s in AdhanSound.values)
          OptionRow(
            icon: switch (s) {
              AdhanSound.makkah || AdhanSound.madinah => LucideIcons.volume2,
              AdhanSound.chime => LucideIcons.bell,
              AdhanSound.silent => LucideIcons.bellOff,
            },
            title: s.label,
            sub: s.sub,
            selected: app.adhanSound == s,
            onTap: () async {
              await app.setAdhanSound(s);
              set(() {});
            },
          ),
        const SizedBox(height: 10),
        SheetButton(label: 'Save', onTap: () => Navigator.pop(ctx)),
      ]);
    });
  });
}

// ------------------------------------------------------------------ reciter

void showReciterSheet(BuildContext context) {
  final app = AppState.instance;
  showGlassSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      return Column(children: [
        const SheetTitle('Reciter', sub: 'Voice for Quran audio'),
        const SizedBox(height: 18),
        for (var i = 0; i < reciters.length; i++)
          OptionRow(
            icon: LucideIcons.mic,
            title: reciters[i].$1,
            sub: reciters[i].$2,
            selected: app.reciter == i,
            onTap: () async {
              await app.setReciter(i);
              set(() {});
            },
          ),
        const SizedBox(height: 10),
        SheetButton(label: 'Done', onTap: () => Navigator.pop(ctx)),
      ]);
    });
  });
}

// ------------------------------------------------------------------ zone

void showZoneSheet(BuildContext context) {
  final app = AppState.instance;
  final zones = ZoneService.instance.zones;
  showGlassSheet(context, tall: true, builder: (ctx) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SheetTitle('Prayer zone',
          sub: app.zoneCode == null
              ? 'You are outside Malaysia'
              : 'Current: ${app.zoneCode} · ${app.placeName}'),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          Navigator.pop(ctx);
          await app.setAutoLocation(true);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Icon(LucideIcons.locateFixed, size: 20, color: S.accent),
            const SizedBox(width: 12),
            Text('Use my location', style: T.ui(15, c: S.accent, w: FontWeight.w800)),
          ]),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: zones.length,
          itemBuilder: (ctx, i) {
            final z = zones[i];
            final newState = i == 0 || zones[i - 1].state != z.state;
            final sel = z.code == app.zoneCode;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (newState)
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 4),
                  child: Text((stateNames[z.state] ?? z.state).toUpperCase(),
                      style: T.ui(12, c: S.accent, w: FontWeight.w800, ls: .06)),
                ),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await app.setManualZone(z);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: S.line(.22)))),
                  child: Row(children: [
                    SizedBox(
                        width: 62,
                        child: Text(z.code,
                            style: T.ui(13.5,
                                w: FontWeight.w700, c: sel ? S.accent : S.text))),
                    Expanded(
                        child: Text(z.label,
                            style: T.ui(13.5, c: sel ? S.accent : S.muted, w: sel ? FontWeight.w700 : FontWeight.w500, h: 1.35))),
                    if (sel) const Icon(LucideIcons.check, size: 18, color: S.accent),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  });
}

// ------------------------------------------------------------------ surah

void showSurahSheet(BuildContext context, Surah s, {VoidCallback? onListen}) {
  final app = AppState.instance;
  showGlassSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      final saved = app.bookmarks.contains(s.number);
      return Column(children: [
        Row(children: [
          Expanded(
            child: SheetTitle(s.name,
                sub: '${s.meaning} · ${s.ayahs} ayahs · ${s.meccan ? 'Meccan' : 'Medinan'}'),
          ),
          Text(s.arabic, style: T.arabic(28, c: S.text, h: 1.4)),
        ]),
        const SizedBox(height: 18),
        OptionRow(
          icon: LucideIcons.bookOpen,
          title: app.lastSurah == s.number ? 'Continue reading' : 'Start reading here',
          sub: app.lastSurah == s.number
              ? 'You stopped at ayah ${app.lastAyah}'
              : 'Sets this as your reading spot',
          onTap: () async {
            await app.setLastRead(s.number, app.lastSurah == s.number ? app.lastAyah : 1);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
        OptionRow(
          icon: LucideIcons.play,
          title: 'Listen',
          sub: reciters[app.reciter].$1,
          onTap: () {
            Navigator.pop(ctx);
            showReciterSheet(context);
          },
        ),
        OptionRow(
          icon: saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
          title: saved ? 'Saved to bookmarks' : 'Save to bookmarks',
          sub: saved ? 'Tap to remove' : 'Find it on Home and in Saved',
          selected: saved,
          onTap: () async {
            await app.toggleBookmark(s.number);
            set(() {});
          },
        ),
      ]);
    });
  });
}
