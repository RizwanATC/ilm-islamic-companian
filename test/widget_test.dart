import 'package:flutter_test/flutter_test.dart';
import 'package:ilm/services/prayer_service.dart';
import 'package:ilm/services/zone_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GeoJSON maps coordinates to JAKIM zones', () async {
    final z = ZoneService.instance;
    await z.load();
    expect(z.zones.length, 60);
    expect(z.find(3.1390, 101.6869)?.code, 'WLY01'); // Kuala Lumpur
    expect(z.find(2.9264, 101.6964)?.code, 'WLY01'); // Putrajaya
    expect(z.find(3.0733, 101.5185)?.code, 'SGR01'); // Shah Alam
    expect(z.find(5.4141, 100.3288)?.code, 'PNG01'); // George Town
    expect(z.find(1.4927, 103.7414)?.code, 'JHR02'); // Johor Bahru
    expect(z.find(1.3521, 103.8198), isNull); // Singapore
  });

  test('adhan calculates times outside Malaysia', () {
    final d = PrayerService.instance.calculate(
        lat: 21.4225, lng: 39.8262, date: DateTime(2026, 9, 30), method: Method.ummAlQura);
    expect(d[Prayer.fajr].isBefore(d[Prayer.dhuhr]), isTrue);
    expect(d[Prayer.maghrib].isBefore(d[Prayer.isha]), isTrue);
  });
}
