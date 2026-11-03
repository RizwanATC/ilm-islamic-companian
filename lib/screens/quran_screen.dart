import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/quran_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';
import 'home_screen.dart' show ContinueReading;
import 'reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key, required this.controller});
  final ScrollController controller;
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int _tab = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final q = _q.toLowerCase().replaceAll(RegExp(r"[-' ]"), '');
    final list = q.isEmpty
        ? surahs
        : surahs
            .where((s) =>
                s.name.toLowerCase().replaceAll(RegExp(r"[-' ]"), '').contains(q) ||
                s.meaning.toLowerCase().contains(_q.toLowerCase()) ||
                s.arabic.contains(_q) ||
                '${s.number}' == _q.trim())
            .toList();
    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 200),
      children: [
        Row(children: [
          Expanded(
              child: Text('Al-Quran', style: T.ui(30, w: FontWeight.w700, ls: -.025))),
          GestureDetector(
            onTap: () => setState(() => _tab = 2),
            child: const Icon(LucideIcons.bookmark, size: 22, color: C.sand2),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: C.line(.12)))),
          child: TextField(
            onChanged: (v) => setState(() {
              _q = v;
              if (v.isNotEmpty) _tab = 0;
            }),
            style: T.ui(15, w: FontWeight.w500),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search surah by name, meaning or number',
              hintStyle: T.ui(15, c: C.faint, w: FontWeight.w500),
              prefixIcon: const Icon(LucideIcons.search, size: 19, color: C.faint),
              prefixIconConstraints: const BoxConstraints(minWidth: 30),
            ),
          ),
        ),
        const SizedBox(height: 26),
        ContinueReading(
          onPlay: () => openReader(context, surah(app.lastSurah),
              ayah: app.lastAyah, listen: true),
          trailing: 'Juz ${_juzOf(app.lastSurah, app.lastAyah)}',
        ),
        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: C.line(.1)))),
          child: Row(children: [
            for (final (i, t) in [(0, 'Surah'), (1, 'Juz'), (2, 'Saved')])
              GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 26),
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: _tab == i ? C.amber : Colors.transparent,
                            width: 2)),
                  ),
                  child: Text(t,
                      style: T.ui(15,
                          w: FontWeight.w700, c: _tab == i ? C.sand : C.faint)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        if (_tab == 0) ...[
          for (final s in list) _SurahRow(s),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text('No surah matches "$_q"',
                  textAlign: TextAlign.center, style: T.ui(14, c: C.faint)),
            ),
        ],
        if (_tab == 1)
          for (var j = 0; j < 30; j++) _JuzRow(j),
        if (_tab == 2) ...[
          for (final n in (app.bookmarks.toList()..sort())) _SurahRow(surah(n)),
          if (app.bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text('Nothing saved yet. Tap a surah, then "Save to bookmarks".',
                  textAlign: TextAlign.center, style: T.ui(14, c: C.faint)),
            ),
        ],
      ],
    );
  }

  static int _juzOf(int s, int a) {
    var j = 1;
    for (var i = 0; i < juzStarts.length; i++) {
      final (ss, aa) = juzStarts[i];
      if (s > ss || (s == ss && a >= aa)) j = i + 1;
    }
    return j;
  }
}

class _NumberStar extends StatelessWidget {
  const _NumberStar(this.n);
  final int n;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 38,
        height: 38,
        child: Stack(alignment: Alignment.center, children: [
          SvgPicture.asset('assets/img/star8.svg', width: 38, height: 38),
          Text('$n', style: T.ui(n > 99 ? 11 : 13, c: C.amber, w: FontWeight.w700)),
        ]),
      );
}

class _SurahRow extends StatelessWidget {
  const _SurahRow(this.s);
  final Surah s;
  @override
  Widget build(BuildContext context) {
    final last = AppState.instance.lastSurah == s.number;
    final row = GestureDetector(
      onTap: () => showSurahSheet(context, s),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line()))),
        child: Row(children: [
          _NumberStar(s.number),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: T.ui(16, w: FontWeight.w700, c: last ? C.sage : C.sand)),
              const SizedBox(height: 2),
              Text('${last ? 'Last read · ' : ''}${s.meaning} · ${s.ayahs} ayahs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.ui(12.5, c: last ? C.sage : C.faint, w: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(s.arabic,
              textDirection: TextDirection.rtl,
              style: T.arabic(22, c: last ? C.sage : C.sand2, h: 1.5)),
        ]),
      ),
    );
    if (!last) return row;
    return Stack(children: [
      Positioned.fill(
        left: -20,
        right: -20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              C.sage.withValues(alpha: .12),
              Colors.transparent,
            ], stops: const [0, .7]),
          ),
        ),
      ),
      row,
    ]);
  }
}

class _JuzRow extends StatelessWidget {
  const _JuzRow(this.j);
  final int j;
  @override
  Widget build(BuildContext context) {
    final (sn, a) = juzStarts[j];
    final s = surah(sn);
    return GestureDetector(
      onTap: () => openReader(context, s, ayah: a),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line()))),
        child: Row(children: [
          _NumberStar(j + 1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Juz ${j + 1}', style: T.ui(16, w: FontWeight.w700)),
              Text('Starts at ${s.name} $sn:$a',
                  style: T.ui(12.5, c: C.faint, w: FontWeight.w500)),
            ]),
          ),
          const Icon(LucideIcons.chevronRight, size: 16, color: C.faint),
        ]),
      ),
    );
  }
}
