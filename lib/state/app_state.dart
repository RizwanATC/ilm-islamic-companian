import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/prayer_service.dart';
import '../services/zone_service.dart';

enum Gender { female, male }

enum AdhanSound { makkah, madinah, chime, silent }

extension AdhanSoundX on AdhanSound {
  String get label => switch (this) {
        AdhanSound.makkah => 'Makkah',
        AdhanSound.madinah => 'Madinah',
        AdhanSound.chime => 'Gentle chime',
        AdhanSound.silent => 'Silent',
      };
  String get sub => switch (this) {
        AdhanSound.makkah => 'Full call to prayer',
        AdhanSound.madinah => 'Soft, slower call to prayer',
        AdhanSound.chime => 'A short tone',
        AdhanSound.silent => 'Notification only',
      };
}

/// Quran reciters for the audio player.
const reciters = [
  ('Abdul Rahman Al-Sudais', 'Murattal · Makkah'),
  ('Saad Al-Ghamdi', 'Murattal · Saudi Arabia'),
  ('Maher Al-Muaiqly', 'Murattal · Makkah'),
  ('Abdul Basit Abdus Samad', 'Mujawwad · Egypt'),
];

class JourneyStep {
  const JourneyStep(this.title, this.short, this.time, this.reward, this.detail,
      {this.prayer});
  final String title;
  final String short;
  final String time;
  final int reward;
  final String detail;
  final Prayer? prayer;
}

const journeySteps = [
  JourneyStep('Fajr & morning adhkar', 'Fajr', 'Fajr', 20,
      'Pray Fajr, then read the morning adhkar. About 3 minutes.',
      prayer: Prayer.fajr),
  JourneyStep('Read one page', 'Quran', 'Morning', 15,
      'Continue from where you stopped. One page is enough.'),
  JourneyStep('Dhuhr & learn a dua', 'Dhuhr', 'Dhuhr', 15,
      "Pray Dhuhr, then learn today's short dua.",
      prayer: Prayer.dhuhr),
  JourneyStep('Asr & reflect', 'Asr', 'Asr', 15,
      "Pray Asr, then spend a minute with today's ayah: “With hardship comes ease.” What ease have you seen this week?",
      prayer: Prayer.asr),
  JourneyStep('Maghrib & evening adhkar', 'Maghrib', 'Maghrib', 20,
      'Pray Maghrib, then read the evening adhkar.',
      prayer: Prayer.maghrib),
  JourneyStep('Isha & a good deed', 'Isha', 'Isha', 15,
      'Pray Isha, then do one kind thing: sadaqah, a kind word, or calling family.',
      prayer: Prayer.isha),
  JourneyStep('Sleep with Al-Mulk', 'Al-Mulk', 'Before bed', 20,
      'Recite Surah Al-Mulk or the dua before sleeping.'),
];

const levelNames = ['Seeker of Light', 'Traveller', 'Devoted', 'Steadfast'];

class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  late SharedPreferences _prefs;

  // ---------- profile ----------
  Gender gender = Gender.female;
  String get userName => gender == Gender.female ? 'Aisha' : 'Adam';
  String get userFull => '$userName Rahman';
  String get botName => gender == Gender.female ? 'Ayu' : 'Yun';

  // ---------- location & prayer times ----------
  bool autoLocation = true;
  bool loading = true;
  String? error;
  double lat = 3.1390, lng = 101.6869; // Kuala Lumpur default
  String? zoneCode = 'WLY01';
  String placeName = 'Kuala Lumpur';
  bool get inMalaysia => zoneCode != null;
  Method method = Method.mwl;
  bool hanafi = false;
  final Map<String, PrayerDay> _jakim = {};

  AdhanSound adhanSound = AdhanSound.makkah;
  Map<Prayer, bool> alerts = {for (final p in fardPrayers) p: p != Prayer.isha};
  int reciter = 0;
  bool haptics = true;

  // ---------- tracking ----------
  /// yyyy-MM-dd -> prayers marked as prayed.
  final Map<String, Set<Prayer>> prayed = {};

  // ---------- journey ----------
  int journeyDone = 0; // steps done today
  String journeyDate = '';
  int noor = 340;
  int level = 7;
  int get levelFloor => 300 + (level - 7) * 100;
  int get levelCeil => levelFloor + 100;
  String get levelName => levelNames[(level - 7).clamp(0, levelNames.length - 1)];
  int streak = 12;

  // ---------- quran ----------
  Set<int> bookmarks = {36, 67, 55};
  int lastSurah = 18;
  int lastAyah = 68;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    await ZoneService.instance.load();
    if (autoLocation) {
      await locate(notify: false);
    } else {
      _applyZone(zoneCode);
    }
    await refreshTimes();
  }

  void _load() {
    gender = Gender.values[_prefs.getInt('gender') ?? 0];
    autoLocation = _prefs.getBool('autoLocation') ?? true;
    zoneCode = _prefs.getString('zone') ?? zoneCode;
    lat = _prefs.getDouble('lat') ?? lat;
    lng = _prefs.getDouble('lng') ?? lng;
    placeName = _prefs.getString('place') ?? placeName;
    method = Method.values[_prefs.getInt('method') ?? 0];
    hanafi = _prefs.getBool('hanafi') ?? false;
    adhanSound = AdhanSound.values[_prefs.getInt('adhanSound') ?? 0];
    reciter = _prefs.getInt('reciter') ?? 0;
    haptics = _prefs.getBool('haptics') ?? true;
    final a = _prefs.getString('alerts');
    if (a != null) {
      final m = jsonDecode(a) as Map<String, dynamic>;
      alerts = {for (final e in m.entries) Prayer.values.byName(e.key): e.value as bool};
    }
    final p = _prefs.getString('prayed');
    if (p != null) {
      final m = jsonDecode(p) as Map<String, dynamic>;
      m.forEach((k, v) => prayed[k] =
          (v as List).map((e) => Prayer.values.byName(e as String)).toSet());
    }
    noor = _prefs.getInt('noor') ?? noor;
    level = _prefs.getInt('level') ?? level;
    streak = _prefs.getInt('streak') ?? streak;
    journeyDate = _prefs.getString('journeyDate') ?? '';
    journeyDone = journeyDate == PrayerService.key(DateTime.now())
        ? (_prefs.getInt('journeyDone') ?? 0)
        : 0;
    final b = _prefs.getStringList('bookmarks');
    if (b != null) bookmarks = b.map(int.parse).toSet();
    lastSurah = _prefs.getInt('lastSurah') ?? lastSurah;
    lastAyah = _prefs.getInt('lastAyah') ?? lastAyah;
  }

  // ---------------------------------------------------------------- location

  /// Reads GPS, then maps the coordinates to a JAKIM zone via the GeoJSON.
  Future<void> locate({bool notify = true}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        error = 'Location is off. Showing ${placeName.isEmpty ? 'saved' : placeName} times.';
        _applyZone(zoneCode);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
      lat = pos.latitude;
      lng = pos.longitude;
      final d = ZoneService.instance.find(lat, lng);
      if (d != null) {
        zoneCode = d.code;
        placeName = d.name;
      } else {
        zoneCode = null;
        placeName = '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
      }
      error = null;
      await _saveLocation();
    } catch (e) {
      error = 'Could not get your location. Showing saved times.';
      _applyZone(zoneCode);
    }
    if (notify) notifyListeners();
  }

  void _applyZone(String? code) {
    if (code == null) return;
    final z = ZoneService.instance.zone(code);
    if (z != null && placeName.isEmpty) placeName = z.districts.first;
  }

  Future<void> _saveLocation() async {
    if (zoneCode != null) {
      await _prefs.setString('zone', zoneCode!);
    } else {
      await _prefs.remove('zone');
    }
    await _prefs.setDouble('lat', lat);
    await _prefs.setDouble('lng', lng);
    await _prefs.setString('place', placeName);
  }

  Future<void> setManualZone(Zone z) async {
    autoLocation = false;
    zoneCode = z.code;
    placeName = z.districts.first;
    _jakim.clear();
    await _prefs.setBool('autoLocation', false);
    await _saveLocation();
    await refreshTimes();
  }

  Future<void> setAutoLocation(bool v) async {
    autoLocation = v;
    await _prefs.setBool('autoLocation', v);
    if (v) {
      loading = true;
      notifyListeners();
      await locate(notify: false);
      _jakim.clear();
      await refreshTimes();
    } else {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- times

  Future<void> refreshTimes() async {
    loading = true;
    notifyListeners();
    if (zoneCode != null) {
      final m = await PrayerService.instance.jakimMonth(zoneCode!);
      _jakim
        ..clear()
        ..addAll(m);
      if (m.isEmpty) {
        error ??= 'JAKIM e-Solat is unreachable. Showing calculated times.';
      }
    }
    loading = false;
    notifyListeners();
  }

  /// Prayer times for any date: JAKIM when in Malaysia and available,
  /// otherwise calculated locally with adhan.
  PrayerDay day(DateTime date) {
    final k = PrayerService.key(date);
    final j = _jakim[k];
    if (j != null) return j;
    return PrayerService.instance.calculate(
      lat: lat,
      lng: lng,
      date: date,
      // In Malaysia fall back to the 20°/18° angles JAKIM uses.
      method: inMalaysia ? Method.singapore : method,
      hanafi: hanafi,
    );
  }

  PrayerDay get today => day(DateTime.now());

  String get sourceLabel {
    final s = today.source;
    if (s == 'JAKIM') return 'JAKIM · $zoneCode';
    return inMalaysia ? 'Calculated (JAKIM angles)' : s;
  }

  /// The next fard prayer from [now]. Rolls over to tomorrow's Fajr after Isha.
  (Prayer, DateTime, PrayerDay) nextPrayer(DateTime now) {
    final t = today;
    for (final p in fardPrayers) {
      if (t[p].isAfter(now)) return (p, t[p], t);
    }
    final tm = day(now.add(const Duration(days: 1)));
    return (Prayer.fajr, tm[Prayer.fajr], tm);
  }

  double get qiblaBearing => PrayerService.instance.qibla(lat, lng);

  // ---------------------------------------------------------------- settings

  Future<void> setGender(Gender g) async {
    gender = g;
    await _prefs.setInt('gender', g.index);
    notifyListeners();
  }

  Future<void> setMethod(Method m) async {
    method = m;
    await _prefs.setInt('method', m.index);
    notifyListeners();
  }

  Future<void> setHanafi(bool v) async {
    hanafi = v;
    await _prefs.setBool('hanafi', v);
    notifyListeners();
  }

  Future<void> setAdhanSound(AdhanSound s) async {
    adhanSound = s;
    await _prefs.setInt('adhanSound', s.index);
    notifyListeners();
  }

  Future<void> setReciter(int i) async {
    reciter = i;
    await _prefs.setInt('reciter', i);
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    haptics = v;
    await _prefs.setBool('haptics', v);
    notifyListeners();
  }

  Future<void> toggleAlert(Prayer p) async {
    alerts[p] = !(alerts[p] ?? false);
    await _prefs.setString(
        'alerts', jsonEncode(alerts.map((k, v) => MapEntry(k.name, v))));
    notifyListeners();
  }

  // ---------------------------------------------------------------- tracking

  bool isPrayed(DateTime d, Prayer p) =>
      prayed[PrayerService.key(d)]?.contains(p) ?? false;

  Future<void> togglePrayed(DateTime d, Prayer p) async {
    final k = PrayerService.key(d);
    final s = prayed.putIfAbsent(k, () => {});
    s.contains(p) ? s.remove(p) : s.add(p);
    await _prefs.setString('prayed',
        jsonEncode(prayed.map((k, v) => MapEntry(k, v.map((e) => e.name).toList()))));
    notifyListeners();
  }

  // ---------------------------------------------------------------- journey

  /// Completes the current journey step. Returns (reward, levelledUp).
  Future<(int, bool)> completeStep() async {
    if (journeyDone >= journeySteps.length) return (0, false);
    var reward = journeySteps[journeyDone].reward;
    journeyDone++;
    if (journeyDone == journeySteps.length) {
      reward += 50;
      streak++;
      await _prefs.setInt('streak', streak);
    }
    noor += reward;
    var up = false;
    while (noor >= levelCeil) {
      level++;
      up = true;
    }
    journeyDate = PrayerService.key(DateTime.now());
    await _prefs.setString('journeyDate', journeyDate);
    await _prefs.setInt('journeyDone', journeyDone);
    await _prefs.setInt('noor', noor);
    await _prefs.setInt('level', level);
    notifyListeners();
    return (reward, up);
  }

  // ---------------------------------------------------------------- quran

  Future<void> toggleBookmark(int surah) async {
    bookmarks.contains(surah) ? bookmarks.remove(surah) : bookmarks.add(surah);
    await _prefs.setStringList(
        'bookmarks', bookmarks.map((e) => '$e').toList());
    notifyListeners();
  }

  Future<void> setLastRead(int surah, [int ayah = 1]) async {
    lastSurah = surah;
    lastAyah = ayah;
    await _prefs.setInt('lastSurah', surah);
    await _prefs.setInt('lastAyah', ayah);
    notifyListeners();
  }
}
