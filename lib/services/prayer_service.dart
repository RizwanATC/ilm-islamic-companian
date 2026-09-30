import 'dart:convert';

import 'package:adhan/adhan.dart' as adhan;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Prayer { fajr, syuruk, dhuhr, asr, maghrib, isha }

extension PrayerX on Prayer {
  String get label => switch (this) {
        Prayer.fajr => 'Fajr',
        Prayer.syuruk => 'Syuruk',
        Prayer.dhuhr => 'Dhuhr',
        Prayer.asr => 'Asr',
        Prayer.maghrib => 'Maghrib',
        Prayer.isha => 'Isha',
      };

  /// Obligatory prayers (Syuruk is sunrise, not a prayer).
  bool get isFard => this != Prayer.syuruk;
}

const fardPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

class PrayerDay {
  PrayerDay({
    required this.date,
    required this.times,
    this.hijri,
    required this.source,
  });

  final DateTime date;
  final Map<Prayer, DateTime> times;

  /// Hijri date as yyyy-mm-dd when provided by JAKIM.
  final String? hijri;

  /// 'JAKIM' or the adhan calculation method name.
  final String source;

  DateTime operator [](Prayer p) => times[p]!;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hijri': hijri,
        'source': source,
        'times': {for (final e in times.entries) e.key.name: e.value.toIso8601String()},
      };

  static PrayerDay fromJson(Map<String, dynamic> j) => PrayerDay(
        date: DateTime.parse(j['date'] as String),
        hijri: j['hijri'] as String?,
        source: j['source'] as String,
        times: {
          for (final e in (j['times'] as Map<String, dynamic>).entries)
            Prayer.values.byName(e.key): DateTime.parse(e.value as String),
        },
      );
}

/// Calculation methods offered outside Malaysia.
enum Method { mwl, singapore, ummAlQura, egyptian, karachi, northAmerica, dubai }

extension MethodX on Method {
  String get label => switch (this) {
        Method.mwl => 'Muslim World League',
        Method.singapore => 'Singapore (MUIS)',
        Method.ummAlQura => 'Umm al-Qura',
        Method.egyptian => 'Egyptian',
        Method.karachi => 'Karachi',
        Method.northAmerica => 'ISNA',
        Method.dubai => 'Dubai',
      };

  String get angles => switch (this) {
        Method.mwl => '18° / 17°',
        Method.singapore => '20° / 18°',
        Method.ummAlQura => '18.5° / 90 min',
        Method.egyptian => '19.5° / 17.5°',
        Method.karachi => '18° / 18°',
        Method.northAmerica => '15° / 15°',
        Method.dubai => '18.2° / 18.2°',
      };

  adhan.CalculationMethod get adhanMethod => switch (this) {
        Method.mwl => adhan.CalculationMethod.muslim_world_league,
        Method.singapore => adhan.CalculationMethod.singapore,
        Method.ummAlQura => adhan.CalculationMethod.umm_al_qura,
        Method.egyptian => adhan.CalculationMethod.egyptian,
        Method.karachi => adhan.CalculationMethod.karachi,
        Method.northAmerica => adhan.CalculationMethod.north_america,
        Method.dubai => adhan.CalculationMethod.dubai,
      };
}

class PrayerService {
  PrayerService._();
  static final instance = PrayerService._();

  static const _jakimUrl =
      'https://www.e-solat.gov.my/index.php?r=esolatApi/TakwimSolat&period=month&zone=';
  static final _jakimDate = DateFormat('dd-MMM-yyyy', 'en_US');

  static String key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Fetches the current month from JAKIM e-Solat for [zone] and caches it.
  /// Returns an empty map on failure (callers fall back to adhan).
  Future<Map<String, PrayerDay>> jakimMonth(String zone) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'jakim:$zone:${DateFormat('yyyy-MM').format(DateTime.now())}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final m = (jsonDecode(cached) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PrayerDay.fromJson(v as Map<String, dynamic>)));
      if (m.isNotEmpty) return m;
    }
    try {
      final res = await http
          .get(Uri.parse('$_jakimUrl$zone'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return {};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['prayerTime'] as List? ?? const [];
      final out = <String, PrayerDay>{};
      for (final row in list) {
        final r = row as Map<String, dynamic>;
        final date = _jakimDate.parse(r['date'] as String);
        DateTime at(String k) {
          final parts = (r[k] as String).split(':');
          return DateTime(date.year, date.month, date.day, int.parse(parts[0]),
              int.parse(parts[1]));
        }

        out[key(date)] = PrayerDay(
          date: date,
          hijri: r['hijri'] as String?,
          source: 'JAKIM',
          times: {
            Prayer.fajr: at('fajr'),
            Prayer.syuruk: at('syuruk'),
            Prayer.dhuhr: at('dhuhr'),
            Prayer.asr: at('asr'),
            Prayer.maghrib: at('maghrib'),
            Prayer.isha: at('isha'),
          },
        );
      }
      if (out.isNotEmpty) {
        await prefs.setString(cacheKey,
            jsonEncode(out.map((k, v) => MapEntry(k, v.toJson()))));
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Calculates prayer times locally with the adhan library.
  PrayerDay calculate({
    required double lat,
    required double lng,
    required DateTime date,
    required Method method,
    bool hanafi = false,
  }) {
    final params = method.adhanMethod.getParameters()
      ..madhab = hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    final pt = adhan.PrayerTimes(
      adhan.Coordinates(lat, lng),
      adhan.DateComponents(date.year, date.month, date.day),
      params,
    );
    return PrayerDay(
      date: DateTime(date.year, date.month, date.day),
      source: method.label,
      times: {
        Prayer.fajr: pt.fajr,
        Prayer.syuruk: pt.sunrise,
        Prayer.dhuhr: pt.dhuhr,
        Prayer.asr: pt.asr,
        Prayer.maghrib: pt.maghrib,
        Prayer.isha: pt.isha,
      },
    );
  }

  /// Qibla bearing in degrees clockwise from true north.
  double qibla(double lat, double lng) =>
      adhan.Qibla(adhan.Coordinates(lat, lng)).direction;
}
