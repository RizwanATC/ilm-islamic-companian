import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/app_state.dart';
import 'prayer_service.dart';

/// Sound file name (no extension) for each adhan option. Android plays the
/// mp3 in res/raw, iOS plays the caf in Library/Sounds (copied from
/// assets/sounds on start, since iOS caps notification sounds at 30 s).
String? _soundFile(AdhanSound s) => switch (s) {
      AdhanSound.makkah => 'adhan',
      AdhanSound.madinah => 'takbir',
      AdhanSound.chime => 'chime',
      AdhanSound.silent => null,
    };

/// Schedules a local notification at each prayer time that has its alert on.
///
/// Covers the next [_days] days (at most 35 notifications, under the iOS
/// limit of 64) and is rebuilt every time the app starts or a setting that
/// affects the times or the sound changes.
class PrayerAlerts {
  PrayerAlerts._();
  static final instance = PrayerAlerts._();

  static const _days = 7;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_ilm'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (Platform.isIOS) await _installIosSounds();
    _ready = true;
    await requestPermission();
  }

  /// Asks for permission to post notifications (iOS, Android 13+).
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  /// Reschedules shortly after the last call, so several settings changes in
  /// a row only rebuild the schedule once.
  void reschedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _schedule);
  }

  Future<void> _schedule() async {
    if (!_ready) return;
    final app = AppState.instance;
    await _plugin.cancelAll();
    final details = _details(app.adhanSound);
    final mode = await _androidMode();
    final now = DateTime.now();
    for (var d = 0; d < _days; d++) {
      final day = app.day(DateTime(now.year, now.month, now.day + d));
      for (final p in fardPrayers) {
        final at = day[p];
        if (app.alerts[p] != true || !at.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: d * 10 + p.index,
          scheduledDate: tz.TZDateTime.from(at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
          title: '${p.label} · ${DateFormat('h:mm a').format(at)}',
          body: 'It’s time for ${p.label} in ${app.placeName}.',
        );
      }
    }
  }

  /// Fires a sample alert [after] from now with the current sound. Used to
  /// check sounds and permissions on a device.
  Future<void> test({Duration after = const Duration(seconds: 5)}) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: 999,
      scheduledDate:
          tz.TZDateTime.from(DateTime.now().add(after), tz.UTC),
      notificationDetails: _details(AppState.instance.adhanSound),
      androidScheduleMode: await _androidMode(),
      title: 'Test alert',
      body: 'This is how prayer alerts will sound.',
    );
  }

  Future<AndroidScheduleMode> _androidMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    // Without the exact-alarm permission Android may delay by a few minutes.
    return exact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _details(AdhanSound s) {
    final file = _soundFile(s);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        // Android fixes a channel's sound once created, so one channel each.
        'prayer_${s.name}',
        'Prayer alerts · ${s.label}',
        channelDescription: 'Alerts at prayer times',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: file != null,
        sound: file == null ? null : RawResourceAndroidNotificationSound(file),
      ),
      iOS: DarwinNotificationDetails(
        presentSound: file != null,
        sound: file == null ? null : '$file.caf',
      ),
    );
  }

  Future<void> _installIosSounds() async {
    try {
      final dir = Directory('${(await getLibraryDirectory()).path}/Sounds');
      await dir.create(recursive: true);
      for (final s in AdhanSound.values) {
        final f = _soundFile(s);
        if (f == null) continue;
        final out = File('${dir.path}/$f.caf');
        final data = await rootBundle.load('assets/sounds/$f.caf');
        if (await out.exists() && await out.length() == data.lengthInBytes) {
          continue;
        }
        await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
    } catch (e) {
      debugPrint('PrayerAlerts: could not install sounds: $e');
    }
  }
}
