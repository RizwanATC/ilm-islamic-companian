import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/quran_data.dart';
import '../services/quran_text.dart';
import '../services/recitation.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';

/// Opens the reader for [s], scrolled to [ayah]. With [listen], recitation
/// starts from that ayah straight away.
Future<void> openReader(BuildContext context, Surah s,
    {int ayah = 1, bool listen = false}) {
  return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(surah: s, startAyah: ayah, listen: listen)));
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen(
      {super.key, required this.surah, this.startAyah = 1, this.listen = false});
  final Surah surah;
  final int startAyah;
  final bool listen;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _rec = Recitation.instance;
  final _keys = <int, GlobalKey>{};
  late Future<List<Ayah>> _ayahs = _load();
  String? _audioError;

  Surah get s => widget.surah;

  Future<List<Ayah>> _load() async {
    await QuranText.instance.loadPrefs();
    final list = await QuranText.instance.surah(s.number);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTo(widget.startAyah, jump: true);
      if (widget.listen) _play(widget.startAyah);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _rec.current.addListener(_follow);
  }

  @override
  void dispose() {
    _rec.current.removeListener(_follow);
    super.dispose();
  }

  /// Keeps the ayah being recited on screen and remembers it as read.
  void _follow() {
    final c = _rec.current.value;
    if (c == null || c.$1 != s.number || !mounted) return;
    _scrollTo(c.$2);
    AppState.instance.setLastRead(s.number, c.$2);
  }

  void _scrollTo(int ayah, {bool jump = false}) {
    final ctx = _keys[ayah]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: .25,
        duration: jump ? Duration.zero : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic);
  }

  Future<void> _play(int from) async {
    setState(() => _audioError = null);
    try {
      await _rec.play(s.number,
          from: from, to: s.ayahs, reciter: AppState.instance.reciter);
    } catch (_) {
      if (mounted) {
        setState(() => _audioError =
            'Couldn\'t load the recitation. Check your connection and try again.');
      }
    }
  }

  void _togglePlay() {
    if (_rec.isOn(s.number)) {
      _rec.playing.value ? _rec.pause() : _rec.resume();
    } else {
      final app = AppState.instance;
      _play(app.lastSurah == s.number ? app.lastAyah : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        FutureBuilder<List<Ayah>>(
          future: _ayahs,
          builder: (context, snap) {
            if (snap.hasError) return _error();
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: C.amber, strokeWidth: 2));
            }
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, top + 64, 20, 150),
              child: ListenableBuilder(
                listenable: Listenable.merge([_rec.current, AppState.instance]),
                builder: (context, _) {
                  final cur = _rec.current.value;
                  return Column(children: [
                  _header(),
                  for (final a in snap.data!)
                    _AyahView(
                      key: _keys.putIfAbsent(a.number, GlobalKey.new),
                      surah: s.number,
                      ayah: a,
                      active: cur != null && cur.$1 == s.number && cur.$2 == a.number,
                      onPlay: () => _play(a.number),
                    ),
                  ]);
                },
              ),
            );
          },
        ),
        _topBar(top),
        Positioned(left: 16, right: 16, bottom: 16, child: _player()),
      ]),
    );
  }

  Widget _topBar(double top) => Container(
        padding: EdgeInsets.fromLTRB(8, top + 4, 12, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [C.bg, C.bg.withValues(alpha: .92), C.bg.withValues(alpha: 0)],
            stops: const [0, .7, 1],
          ),
        ),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.chevronLeft, color: C.sand),
          ),
          Expanded(
            child: Text(s.name,
                overflow: TextOverflow.ellipsis,
                style: T.ui(18, w: FontWeight.w800, ls: -.01)),
          ),
          _translationToggle(),
        ]),
      );

  Widget _translationToggle() {
    final t = QuranText.instance.translation;
    return GestureDetector(
      onTap: () async {
        final next = Translation.values[(t.index + 1) % Translation.values.length];
        await QuranText.instance.setTranslation(next);
        setState(() => _ayahs = QuranText.instance.surah(s.number));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: C.sand.withValues(alpha: .08),
          border: Border.all(color: C.line(.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.languages, size: 15, color: C.sand2),
          const SizedBox(width: 6),
          Text(t.short, style: T.ui(13, w: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(children: [
          Text(s.arabic, style: T.arabic(40, c: C.amber, h: 1.5)),
          Text('${s.meaning} · ${s.ayahs} ayahs · ${s.meccan ? 'Meccan' : 'Medinan'}',
              textAlign: TextAlign.center,
              style: T.ui(13.5, c: C.muted, w: FontWeight.w600)),
          if (s.number != 1 && s.number != 9) ...[
            const SizedBox(height: 22),
            Text(bismillah,
                textDirection: TextDirection.rtl,
                style: T.arabic(26, c: C.sand, h: 1.8)),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: C.line(.1)),
        ]),
      );

  Widget _error() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.wifiOff, size: 32, color: C.faint),
            const SizedBox(height: 14),
            Text('Couldn\'t load ${s.name}',
                style: T.ui(17, w: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('The first time you open a surah it needs the internet. '
                'After that it works offline.',
                textAlign: TextAlign.center,
                style: T.ui(13.5, c: C.muted, w: FontWeight.w500, h: 1.45)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => setState(() => _ayahs = _load()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: C.amberGradient),
                child: Text('Try again',
                    style: T.ui(15, w: FontWeight.w800, c: C.ink)),
              ),
            ),
          ]),
        ),
      );

  Widget _player() {
    final app = AppState.instance;
    return Glass(
      radius: 24,
      strong: true,
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_audioError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 0, 8),
            child: Text(_audioError!,
                style: T.ui(12.5, c: C.rose, w: FontWeight.w600)),
          ),
        Row(children: [
          ValueListenableBuilder(
            valueListenable: _rec.playing,
            builder: (context, playing, _) {
              final on = playing && _rec.isOn(s.number);
              return GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, gradient: C.amberGradient),
                  child: Icon(on ? LucideIcons.pause : LucideIcons.play,
                      size: 19, color: C.ink),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await showReciterSheet(context);
                // Restart from the current ayah in the new voice.
                final c = _rec.current.value;
                if (c != null && c.$1 == s.number) _play(c.$2);
                if (mounted) setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: ValueListenableBuilder(
                valueListenable: _rec.current,
                builder: (context, cur, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        cur != null && cur.$1 == s.number
                            ? 'Ayah ${cur.$2} of ${s.ayahs}'
                            : app.lastSurah == s.number
                                ? 'Listen from ayah ${app.lastAyah}'
                                : 'Listen to ${s.name}',
                        style: T.ui(14.5, w: FontWeight.w800)),
                    Row(children: [
                      Flexible(
                        child: Text(reciters[app.reciter].$1,
                            overflow: TextOverflow.ellipsis,
                            style: T.ui(12, c: C.muted, w: FontWeight.w600)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronDown, size: 13, color: C.muted),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _rec.current,
            builder: (context, cur, _) => cur != null && cur.$1 == s.number
                ? GestureDetector(
                    onTap: _rec.stop,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(LucideIcons.square, size: 18, color: C.sand2),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ]),
      ]),
    );
  }
}

class _AyahView extends StatelessWidget {
  const _AyahView({
    super.key,
    required this.surah,
    required this.ayah,
    required this.active,
    required this.onPlay,
  });
  final int surah;
  final Ayah ayah;
  final bool active;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final last = app.lastSurah == surah && app.lastAyah == ayah.number;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: active ? C.amber.withValues(alpha: .1) : Colors.transparent,
        border: Border.all(
            color: active ? C.amber.withValues(alpha: .35) : Colors.transparent),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(alignment: Alignment.center, children: [
              SvgPicture.asset('assets/img/star8.svg', width: 32, height: 32),
              Text('${ayah.number}',
                  style: T.ui(ayah.number > 99 ? 10 : 12,
                      c: C.amber, w: FontWeight.w700)),
            ]),
          ),
          if (last && !active) ...[
            const SizedBox(width: 8),
            Text('Last read', style: T.ui(11.5, c: C.sage, w: FontWeight.w700)),
          ],
          const Spacer(),
          _icon(LucideIcons.play, 'Play from here', onPlay),
          _icon(
              last ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
              'Mark as last read',
              () => app.setLastRead(surah, ayah.number)),
        ]),
        const SizedBox(height: 10),
        Text(ayah.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: T.arabic(27, c: active ? C.amberLight : C.sand, h: 2.1)),
        const SizedBox(height: 8),
        Text(ayah.translation,
            style: T.ui(14.5, c: C.sand2, w: FontWeight.w500, h: 1.55)),
      ]),
    );
  }

  Widget _icon(IconData i, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(i, size: 17, color: C.faint),
          ),
        ),
      );
}
