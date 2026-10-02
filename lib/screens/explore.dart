import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/duas.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Pushes a full page with the same soft rise-and-fade used by Journey.
void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, a, b) => Scaffold(
        body: ListenableBuilder(
          listenable: AppState.instance,
          builder: (context, _) => page,
        ),
      ),
      transitionsBuilder: (context, a, b, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .06),
              end: Offset.zero,
            ).animate(c),
            child: child,
          ),
        );
      },
    ),
  );
}

void openSettings(BuildContext context) =>
    openPage(context, const SettingsScreen(onBack: true));

void openDuas(BuildContext context) => openPage(context, const DuasScreen());

/// Back chevron in a small glass square, shared by pushed pages.
class BackGlassButton extends StatelessWidget {
  const BackGlassButton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Back',
    button: true,
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Glass(
        radius: 14,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(LucideIcons.chevronLeft, size: 18, color: C.sand),
        ),
      ),
    ),
  );
}

/// The Explore sheet: quick access to everything that isn't a main tab.
void showExploreSheet(BuildContext context) {
  showGlassSheet<void>(
    context,
    heightFactor: .5,
    builder: (ctx) {
      void go(void Function(BuildContext) open) {
        Navigator.pop(ctx);
        open(context);
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            'Explore',
            style: T.ui(22, w: FontWeight.w700, c: S.text, ls: -.02),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 18,
            crossAxisSpacing: 8,
            childAspectRatio: .78,
            children: [
              _ExploreItem(
                icon: LucideIcons.handHeart,
                title: 'Daily Duas',
                onTap: () => go(openDuas),
              ),
              _ExploreItem(
                icon: LucideIcons.settings,
                title: 'Settings',
                onTap: () => go(openSettings),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Grid cell: a glass icon square with its label underneath.
class _ExploreItem extends StatelessWidget {
  const _ExploreItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (AppState.instance.haptics) HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: .22),
              border: Border.all(color: Colors.white.withValues(alpha: .45)),
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: T.ui(13, w: FontWeight.w700, c: Colors.white, h: 1.2),
          ),
        ],
      ),
    ),
  );
}

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});
  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _q = '';

  bool _match(Dua d) {
    final q = _q.trim().toLowerCase();
    return q.isEmpty ||
        d.title.toLowerCase().contains(q) ||
        d.ms.toLowerCase().contains(q) ||
        d.en.toLowerCase().contains(q) ||
        d.latin.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final g in duaGroups)
        if (g.duas.any(_match)) (g.name, g.duas.where(_match).toList()),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        60,
      ),
      children: [
        Row(
          children: [
            const BackGlassButton(),
            const SizedBox(width: 12),
            Text('Daily Duas', style: T.ui(30, w: FontWeight.w700, ls: -.025)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: C.line(.12))),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: T.ui(15, w: FontWeight.w500),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search: eating, sleep, travel, makan…',
              hintStyle: T.ui(15, c: C.faint, w: FontWeight.w500),
              prefixIcon: const Icon(
                LucideIcons.search,
                size: 19,
                color: C.faint,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 30),
            ),
          ),
        ),
        for (final (name, duas) in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 26, bottom: 2),
            child: Text(
              name.toUpperCase(),
              style: T.ui(12, c: C.amber, w: FontWeight.w700, ls: .06),
            ),
          ),
          for (final d in duas) _DuaRow(d, group: name),
        ],
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              'No dua matches "$_q"',
              textAlign: TextAlign.center,
              style: T.ui(14, c: C.faint),
            ),
          ),
      ],
    );
  }
}

class _DuaRow extends StatelessWidget {
  const _DuaRow(this.d, {required this.group});
  final Dua d;
  final String group;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showDua(context, d, group),
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: C.line())),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: T.ui(16, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  d.ms,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.ui(12.5, c: C.faint, w: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.chevronRight, size: 16, color: C.faint),
        ],
      ),
    ),
  );
}

void _showDua(BuildContext context, Dua d, String group) {
  Widget label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      t.toUpperCase(),
      style: T.ui(11.5, c: S.accent, w: FontWeight.w800, ls: .06),
    ),
  );

  showGlassSheet(
    context,
    builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(d.title, sub: group),
          const SizedBox(height: 22),
          Text(
            d.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: T.arabic(d.arabic.length > 120 ? 23 : 28, c: S.text, h: 2),
          ),
          const SizedBox(height: 10),
          Text(
            d.latin,
            textAlign: TextAlign.center,
            style: T
                .ui(14, c: S.muted, w: FontWeight.w500, h: 1.5)
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: S.line()),
          const SizedBox(height: 18),
          label('Maksud'),
          Text(
            d.ms,
            style: T.ui(15, c: S.text, w: FontWeight.w600, h: 1.55),
          ),
          const SizedBox(height: 16),
          label('Meaning'),
          Text(
            d.en,
            style: T.ui(15, c: S.muted, w: FontWeight.w500, h: 1.55),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(LucideIcons.bookMarked, size: 15, color: S.faint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.source,
                  style: T.ui(13, c: S.faint, w: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SheetButton(
            label: 'Copy dua',
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: '${d.arabic}\n\n${d.latin}\n\n${d.ms}'),
              );
              Navigator.pop(ctx);
              showNoorToast(context, 'Dua copied');
            },
          ),
        ],
      );
    },
  );
}
