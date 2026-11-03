import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// everyayah.com folder for each entry in `reciters` (same order).
const _reciterFolders = [
  'Abdurrahmaan_As-Sudais_192kbps',
  'Ghamadi_40kbps',
  'MaherAlMuaiqly128kbps',
  'Abdul_Basit_Mujawwad_128kbps',
];

/// Ayah-by-ayah Quran recitation, streamed from everyayah.com.
///
/// One shared player for the whole app, so starting recitation anywhere
/// stops whatever else was playing.
class Recitation {
  Recitation._() {
    _player.currentIndexStream.listen((i) {
      if (i != null && i < _queue.length) current.value = _queue[i];
    });
    _player.playerStateStream.listen((s) {
      playing.value = s.playing && s.processingState != ProcessingState.completed;
      if (s.processingState == ProcessingState.completed) {
        current.value = null;
        playing.value = false;
      }
    });
  }
  static final instance = Recitation._();

  final _player = AudioPlayer();
  List<(int, int)> _queue = const [];

  /// The (surah, ayah) being recited, or null when stopped.
  final current = ValueNotifier<(int, int)?>(null);
  final playing = ValueNotifier<bool>(false);

  static Uri url(int surah, int ayah, int reciter) {
    final f = _reciterFolders[reciter.clamp(0, _reciterFolders.length - 1)];
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return Uri.parse('https://everyayah.com/data/$f/$s$a.mp3');
  }

  /// Recites [surah] from ayah [from] to [to] (inclusive), one after another.
  Future<void> play(int surah,
      {required int from, required int to, required int reciter}) async {
    _queue = [for (var a = from; a <= to; a++) (surah, a)];
    current.value = _queue.first;
    playing.value = true;
    try {
      await _player.setAudioSources([
        for (final (s, a) in _queue) AudioSource.uri(url(s, a, reciter)),
      ]);
      unawaited(_player.play());
    } catch (_) {
      current.value = null;
      playing.value = false;
      rethrow;
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> stop() async {
    await _player.stop();
    current.value = null;
    playing.value = false;
  }

  /// Whether [surah] (and [ayah], if given) is what's loaded right now.
  bool isOn(int surah, [int? ayah]) {
    final c = current.value;
    return c != null && c.$1 == surah && (ayah == null || c.$2 == ayah);
  }
}
