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
- `lib/screens/`: Home, Prayer, Quran, Settings, Journey, and the Yun/Ayu chat
- `test/widget_test.dart`: checks the zone lookup against real Malaysian locations

## Not built yet

- Adhan notifications and audio (the settings are saved, but nothing is scheduled yet)
- Quran reader and recitation audio (the list, bookmarks and reading position work)
- Yun/Ayu AI answers (replies are scripted; prayer-time answers use real data)
- Live Qibla compass (the bearing is correct; the dial doesn't rotate with the phone yet)

## Design mockups

`design/index.html` is the clickable HTML mockup the app was built from (open it in a browser).
`design/card-options.html` and `design/ayah-options.html` are earlier design explorations.
