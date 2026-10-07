import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/prayer_service.dart';
import '../services/yun_ai.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Msg {
  _Msg(this.text,
      {this.me = false, this.arabic, this.typing = false, this.failed = false});
  String text;
  final bool me;
  String? arabic;
  bool typing;
  bool failed; // an error notice, kept out of the history sent to the AI
}

void openChat(BuildContext context) {
  showGlassSheet(context, tall: true, builder: (_) => const _Chat());
}

class _Chat extends StatefulWidget {
  const _Chat();
  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<_Msg> _msgs;
  bool _showSuggestions = true;

  static const _suggestions = [
    "What does today's ayah mean?",
    'When is the next prayer?',
    'Dua before sleeping',
  ];

  @override
  void initState() {
    super.initState();
    final app = AppState.instance;
    _msgs = [
      _Msg('Assalamu alaikum, ${app.userName} 🌙 I\'m ${app.botName}. Ask me about '
          'prayer times, the Quran, duas or anything on your mind.'),
    ];
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  _Msg _reply(String q) {
    final app = AppState.instance;
    final l = q.toLowerCase();
    if (l.contains('ayah') || l.contains('mean')) {
      return _Msg('Ash-Sharh 94:5–6 is a promise that ease always comes with '
          'hardship. Allah says it twice to reassure the heart. Scholars also note '
          'that "the hardship" is definite while "ease" is not, which many read as '
          'one hardship being met by more than one ease.');
    }
    if (l.contains('prayer') || l.contains('maghrib') || l.contains('time')) {
      final now = DateTime.now();
      final (p, at, _) = app.nextPrayer(now);
      return _Msg('${p.label} in ${app.placeName} is at ${hmA(at)}, about '
          '${inWords(at.difference(now))} from now. Today: '
          '${fardPrayers.map((e) => '${e.label} ${hm(app.today[e])}').join(', ')}.');
    }
    if (l.contains('sleep') || l.contains('dua')) {
      return _Msg('"In Your name, O Allah, I die and I live." (Sahih al-Bukhari)',
          arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا');
    }
    return _Msg('I can answer the suggested questions for now. Full answers '
        'arrive when ${app.botName} is connected to an AI service.');
  }

  void _ask(String q) {
    q = q.trim();
    if (q.isEmpty || (_msgs.isNotEmpty && _msgs.last.typing)) return;
    setState(() {
      _showSuggestions = false;
      _msgs.add(_Msg(q, me: true));
      _msgs.add(_Msg('', typing: true));
    });
    _toBottom();
    if (YunAi.configured) {
      _askAi();
    } else {
      Timer(const Duration(milliseconds: 1300), () => _answer(_reply(q)));
    }
  }

  Future<void> _askAi() async {
    // Everything after the greeting, minus the typing bubble.
    final history = [
      for (final m in _msgs.skip(1))
        if (!m.typing && !m.failed && m.text.isNotEmpty) (m.me, m.text),
    ];
    _Msg r;
    try {
      r = _Msg(await YunAi.ask(history));
    } on YunError catch (e) {
      r = _Msg(e.message, failed: true);
    } catch (_) {
      r = _Msg(YunError('network').message, failed: true);
    }
    _answer(r);
  }

  void _answer(_Msg r) {
    if (!mounted) return;
    setState(() {
      _msgs.last
        ..typing = false
        ..text = r.text
        ..arabic = r.arabic
        ..failed = r.failed;
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Column(children: [
      Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), gradient: C.yunGradient),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
              offset: const Offset(0, 6), child: const Mascot(size: 52)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.botName, style: T.ui(22, w: FontWeight.w700, c: S.text)),
            Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.white, blurRadius: 6)])),
              const SizedBox(width: 6),
              Text('Your Islamic companion', style: T.ui(13.5, c: S.muted)),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: S.fill(.22),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.x, size: 16, color: S.text),
          ),
        ),
      ]),
      Expanded(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 18),
          children: [
            for (final m in _msgs) _bubble(m),
            if (_showSuggestions)
              for (final s in _suggestions)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _ask(s),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: S.fill(.14),
                        border: Border.all(color: S.line(.6)),
                      ),
                      child: Text(s, style: T.ui(13.5, c: S.text, w: FontWeight.w700)),
                    ),
                  ),
                ),
          ],
        ),
      ),
      Row(children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: S.fill(.18),
              border: Border.all(color: S.line(.35)),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _input,
              style: T.ui(15, c: S.text, w: FontWeight.w600),
              cursorColor: Colors.white,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                _ask(v);
                _input.clear();
              },
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Ask ${app.botName} anything…',
                hintStyle: T.ui(15, c: S.faint, w: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _ask(_input.text);
            _input.clear();
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: const Icon(LucideIcons.arrowUp, size: 20, color: C.ink),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Text('${app.botName} can make mistakes. Check important rulings with a scholar.',
          textAlign: TextAlign.center, style: T.ui(11.5, c: S.faint)),
    ]);
  }

  Widget _bubble(_Msg m) {
    final me = m.me;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .7),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: me ? Colors.white : S.fill(.18),
          border: me ? null : Border.all(color: S.line(.3)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(me ? 18 : 6),
            bottomRight: Radius.circular(me ? 6 : 18),
          ),
        ),
        child: m.typing
            ? const _TypingDots()
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (m.arabic != null)
                  Text(m.arabic!, textDirection: TextDirection.rtl, style: T.arabic(20, c: S.text)),
                Text(m.text,
                    style: T.ui(14.5,
                        c: me ? C.ink : S.text,
                        w: me ? FontWeight.w600 : FontWeight.w500,
                        h: 1.5)),
              ]),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, -4 * (((_c.value * 3 - i) % 3) < 1 ? 1 : 0)),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
            ),
        ]),
      );
}
