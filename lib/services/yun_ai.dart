import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/common.dart';
import 'prayer_service.dart';

/// Talks to the Yun server (server/yun-worker), which answers with Claude.
///
/// Configured at build time:
/// ```
/// flutter build ... --dart-define=YUN_API_URL=https://ilm-yun.YOU.workers.dev \
///                   --dart-define=YUN_APP_KEY=APP_KEY_SECRET
/// ```
/// Without them the chat falls back to its built-in answers.
class YunAi {
  YunAi._();

  static const _url = String.fromEnvironment('YUN_API_URL');
  static const _key = String.fromEnvironment('YUN_APP_KEY');

  static bool get configured => _url.isNotEmpty && _key.isNotEmpty;

  /// [history] is the conversation so far as (fromUser, text) pairs, ending
  /// with the user's new question.
  static Future<String> ask(List<(bool, String)> history) async {
    final app = AppState.instance;
    final now = DateTime.now();
    final (next, at, _) = app.nextPrayer(now);
    final base = _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
    final r = await http
        .post(
          Uri.parse('$base/chat'),
          headers: {'content-type': 'application/json', 'x-app-key': _key},
          body: jsonEncode({
            'messages': [
              for (final (me, text) in history.skip(
                  history.length > 20 ? history.length - 20 : 0))
                {'role': me ? 'user' : 'assistant', 'content': text},
            ],
            'context': {
              'name': app.userName,
              'botName': app.botName,
              'place': app.placeName,
              'today': now.toIso8601String().substring(0, 10),
              'prayerTimes': {
                for (final p in fardPrayers) p.label: hmA(app.today[p]),
              },
              'nextPrayer': '${next.label} at ${hmA(at)}',
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode == 200 && body is Map && body['reply'] is String) {
      return body['reply'] as String;
    }
    throw YunError(body is Map ? '${body['error']}' : 'http_${r.statusCode}');
  }
}

class YunError implements Exception {
  YunError(this.code);
  final String code;

  String get message => switch (code) {
        'rate_limited' => 'You\'re asking quickly. Give me a minute, then try again.',
        'refused' => 'I can\'t help with that one. Try asking another way.',
        'busy' => 'I\'m a little busy right now. Please try again shortly.',
        _ => 'I couldn\'t reach my answers just now. Check your connection and try again.',
      };
}
