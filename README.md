# Ilm

Prayer times, Quran and a daily journey for iOS and Android, built with Flutter.

## Run

Open this folder in VS Code (with the Flutter extension), pick a device in the status bar, then press F5.
Or from a terminal: `flutter run`.

## How prayer times work

- **In Malaysia:** the phone's GPS position is matched against the district polygons in
  `assets/data/malaysia.district-jakim.geojson` (point-in-polygon) to get the JAKIM zone code,
  e.g. `WLY01`. Official times for that zone come from JAKIM e-Solat and are cached per month.
- **Outside Malaysia:** times are calculated on the device with the `adhan` library, using the
  method chosen in Settings.
- If JAKIM is unreachable, the app falls back to `adhan` with JAKIM's 20°/18° angles.
- Users can also pick a zone manually in Settings → Prayer zone.

## Project layout

- `lib/services/zone_service.dart`: GeoJSON loading and zone lookup
- `lib/services/prayer_service.dart`: JAKIM fetch/cache and adhan calculation
- `lib/state/app_state.dart`: settings, prayed marks, journey progress (saved on device)
- `lib/services/prayer_alerts.dart`, `recitation.dart`, `quran_text.dart`, `yun_ai.dart`: alerts, audio, Quran text, AI chat
- `lib/screens/`: Home, Prayer, Quran, the Quran reader, Settings, Journey, and the Yun/Ayu chat
- `server/yun-worker/`: the Cloudflare Worker behind the Yun/Ayu chat
- `test/widget_test.dart`: checks the zone lookup against real Malaysian locations

## Features that use the network

- **Quran reader:** text from api.alquran.cloud (Uthmani script, Sahih International and
  Abdullah Basmeih translations), saved on the phone after a surah is first opened.
  Recitation streams from everyayah.com, ayah by ayah, and the reader follows along.
- **Prayer alerts:** scheduled on the device for the next 7 days and rebuilt when the app opens
  or settings change. The adhan recording is by Aaqib Azeez (Wikimedia Commons, CC BY-SA 4.0).
- **Qibla:** the compass dial turns with the phone's magnetometer.
- **Yun/Ayu answers:** come from Claude through the small server in `server/yun-worker`
  (see its README to deploy). Build the app with
  `--dart-define=YUN_API_URL=... --dart-define=YUN_APP_KEY=...` to turn it on; without them
  the chat uses its built-in sample answers.

## Design mockups

`design/index.html` is the clickable HTML mockup the app was built from (open it in a browser).
`design/card-options.html` and `design/ayah-options.html` are earlier design explorations.
