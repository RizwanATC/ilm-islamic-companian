import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 200),
      children: [
        Text('Settings', style: T.ui(30, w: FontWeight.w700, ls: -.025)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: C.line(.08)))),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE6A39A), C.plum]),
              ),
              child: Text(app.userName[0],
                  style: T.ui(20, w: FontWeight.w700, c: C.ink)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.userFull, style: T.ui(18, w: FontWeight.w700)),
                Text(app.placeName, style: T.ui(13, c: C.muted, w: FontWeight.w500)),
              ]),
            ),
          ]),
        ),
        _label('You'),
        _row(LucideIcons.heart, C.rose, 'Gender',
            trailing: _GenderSwitch(
              value: app.gender,
              onChanged: app.setGender,
            )),
        _label('Location'),
        _row(LucideIcons.locateFixed, C.sage, 'Auto location',
            trailing: _Toggle(value: app.autoLocation, onChanged: app.setAutoLocation)),
        _row(LucideIcons.mapPin, C.sage, 'Prayer zone',
            value: app.zoneCode ?? 'Outside Malaysia',
            onTap: () => showZoneSheet(context)),
        _label('Prayer'),
        _row(LucideIcons.calculator, C.amber, 'Calculation method',
            value: app.inMalaysia ? 'JAKIM' : app.method.label,
            onTap: () => showMethodSheet(context)),
        if (!app.inMalaysia)
          _row(LucideIcons.sunMedium, C.amber, 'Asr (Hanafi)',
              trailing: _Toggle(value: app.hanafi, onChanged: app.setHanafi)),
        _row(LucideIcons.volume2, C.amber, 'Adhan sound',
            value: app.adhanSound.label, onTap: () => showAdhanSheet(context)),
        _label('Quran'),
        _row(LucideIcons.mic, C.sage, 'Reciter',
            value: reciters[app.reciter].$1.split(' ').last,
            onTap: () => showReciterSheet(context)),
        _label('App'),
        _row(LucideIcons.vibrate, C.rose, 'Haptics',
            trailing: _Toggle(value: app.haptics, onChanged: app.setHaptics)),
        _row(LucideIcons.refreshCw, C.rose, 'Refresh prayer times',
            value: app.loading ? 'Loading…' : null, onTap: () => app.refreshTimes()),
        const SizedBox(height: 30),
        Text('Ilm 1.0 · Prayer times from JAKIM e-Solat in Malaysia',
            textAlign: TextAlign.center, style: T.ui(12, c: C.faint)),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 2),
        child: Text(t.toUpperCase(),
            style: T.ui(12, c: C.amber, w: FontWeight.w700, ls: .06)),
      );

  Widget _row(IconData i, Color c, String t,
      {String? value, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line()))),
        child: Row(children: [
          Icon(i, size: 21, color: c),
          const SizedBox(width: 14),
          Expanded(child: Text(t, style: T.ui(15.5))),
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: T.ui(14, c: C.faint, w: FontWeight.w500)),
            ),
          ?trailing,
          if (onTap != null && trailing == null) ...[
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: C.faint),
          ],
        ]),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});
  final bool value;
  final Future<void> Function(bool) onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: value ? C.sage : C.sand.withValues(alpha: .14),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: C.sand,
                boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      );
}

class _GenderSwitch extends StatelessWidget {
  const _GenderSwitch({required this.value, required this.onChanged});
  final Gender value;
  final Future<void> Function(Gender) onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: C.sand.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (g, t) in [(Gender.male, 'Male'), (Gender.female, 'Female')])
            GestureDetector(
              onTap: () => onChanged(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: value == g ? C.amberGradient : null,
                ),
                child: Text(t,
                    style: T.ui(13,
                        w: FontWeight.w700, c: value == g ? C.ink : C.muted)),
              ),
            ),
        ]),
      );
}
