import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One ayah: Arabic text plus its translation.
class Ayah {
  const Ayah(this.number, this.arabic, this.translation);
  final int number;
  final String arabic;
  final String translation;
}

/// Translations offered in the reader.
enum Translation { en, ms }

extension TranslationX on Translation {
  String get label => switch (this) {
        Translation.en => 'English',
        Translation.ms => 'Bahasa Melayu',
      };
  String get short => switch (this) {
        Translation.en => 'EN',
        Translation.ms => 'MS',
      };
  String get edition => switch (this) {
        Translation.en => 'en.sahih',
        Translation.ms => 'ms.basmeih',
      };
}

const bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// Quran text from api.alquran.cloud (Uthmani script, Sahih International
/// and Abdullah Basmeih translations), saved on the phone after the first
/// download so each surah works offline afterwards.
class QuranText {
  QuranText._();
  static final instance = QuranText._();

  static const _api = 'https://api.alquran.cloud/v1/surah';
  final _memory = <int, Map<String, List<String>>>{};

  Translation translation = Translation.en;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    translation = Translation.values[
        (p.getInt('translation') ?? 0).clamp(0, Translation.values.length - 1)];
  }

  Future<void> setTranslation(Translation t) async {
    translation = t;
    final p = await SharedPreferences.getInstance();
    await p.setInt('translation', t.index);
  }

  /// All ayahs of [surah] with the current translation.
  Future<List<Ayah>> surah(int surah) async {
    final eds = _memory[surah] ?? await _load(surah);
    _memory[surah] = eds;
    final ar = eds['quran-uthmani']!;
    final tr = eds[translation.edition] ?? List.filled(ar.length, '');
    return [
      for (var i = 0; i < ar.length; i++)
        Ayah(i + 1, _clean(surah, i, ar[i]), tr[i]),
    ];
  }

  Future<Map<String, List<String>>> _load(int surah) async {
    final file = await _file(surah);
    if (await file.exists()) {
      try {
        return _parse(jsonDecode(await file.readAsString()));
      } catch (_) {
        // Corrupt cache: fall through and download again.
      }
    }
    final eds = ['quran-uthmani', for (final t in Translation.values) t.edition];
    final r = await http
        .get(Uri.parse('$_api/$surah/editions/${eds.join(',')}'))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw HttpException('Quran text unavailable (${r.statusCode})');
    }
    final body = utf8.decode(r.bodyBytes);
    final parsed = _parse(jsonDecode(body));
    await file.writeAsString(body);
    return parsed;
  }

  static Map<String, List<String>> _parse(dynamic json) {
    final out = <String, List<String>>{};
    for (final ed in (json['data'] as List)) {
      final id = ed['edition']['identifier'] as String;
      out[id] = [for (final a in (ed['ayahs'] as List)) a['text'] as String];
    }
    if (!out.containsKey('quran-uthmani')) {
      throw const FormatException('Quran text missing');
    }
    return out;
  }

  /// Strips the byte-order mark, and the bismillah the API prepends to the
  /// first ayah of each surah (the reader shows it as a header instead).
  static String _clean(int surah, int i, String s) {
    var t = s.replaceAll('﻿', '').trim();
    if (i == 0 && surah != 1 && t.startsWith(bismillah)) {
      t = t.substring(bismillah.length).trim();
    }
    return t;
  }

  Future<File> _file(int surah) async {
    final dir = await getApplicationSupportDirectory();
    final d = Directory('${dir.path}/quran');
    if (!await d.exists()) await d.create(recursive: true);
    return File('${d.path}/surah_$surah.json');
  }
}
