import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One district polygon from malaysia.district-jakim.geojson.
class District {
  District({
    required this.name,
    required this.state,
    required this.code,
    required this.polygons,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final String name;
  final String state;
  final String code;

  /// Each polygon is a list of rings; ring 0 is the outer boundary, the
  /// rest are holes. Rings are flat [lng, lat, lng, lat, ...] lists.
  final List<List<List<double>>> polygons;
  final double minLat, maxLat, minLng, maxLng;

  bool contains(double lat, double lng) {
    if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) {
      return false;
    }
    for (final poly in polygons) {
      if (poly.isEmpty || !_inRing(poly.first, lat, lng)) continue;
      var inHole = false;
      for (var i = 1; i < poly.length; i++) {
        if (_inRing(poly[i], lat, lng)) {
          inHole = true;
          break;
        }
      }
      if (!inHole) return true;
    }
    return false;
  }

  /// Ray casting point-in-polygon test.
  static bool _inRing(List<double> ring, double lat, double lng) {
    var inside = false;
    final n = ring.length ~/ 2;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i * 2], yi = ring[i * 2 + 1];
      final xj = ring[j * 2], yj = ring[j * 2 + 1];
      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// A JAKIM prayer zone (e.g. SGR01) and the districts it covers.
class Zone {
  Zone(this.code, this.state, this.districts);
  final String code;
  final String state;
  final List<String> districts;

  String get label => districts.join(', ');
}

const stateNames = {
  'JHR': 'Johor',
  'KDH': 'Kedah',
  'KTN': 'Kelantan',
  'MLK': 'Melaka',
  'NGS': 'Negeri Sembilan',
  'PHG': 'Pahang',
  'PLS': 'Perlis',
  'PNG': 'Pulau Pinang',
  'PRK': 'Perak',
  'SBH': 'Sabah',
  'SGR': 'Selangor',
  'SWK': 'Sarawak',
  'TRG': 'Terengganu',
  'WLY': 'Wilayah Persekutuan',
};

class ZoneService {
  ZoneService._();
  static final instance = ZoneService._();

  List<District> _districts = [];
  List<Zone> zones = [];
  bool get loaded => _districts.isNotEmpty;

  Future<void> load() async {
    if (loaded) return;
    final raw =
        await rootBundle.loadString('assets/data/malaysia.district-jakim.geojson');
    _districts = await compute(_parse, raw);
    final byCode = <String, Zone>{};
    for (final d in _districts) {
      byCode.putIfAbsent(d.code, () => Zone(d.code, d.state, []));
      if (!byCode[d.code]!.districts.contains(d.name)) {
        byCode[d.code]!.districts.add(d.name);
      }
    }
    zones = byCode.values.toList()..sort((a, b) => a.code.compareTo(b.code));
  }

  /// Returns the district that contains the point, or null if outside Malaysia.
  District? find(double lat, double lng) {
    for (final d in _districts) {
      if (d.contains(lat, lng)) return d;
    }
    return null;
  }

  Zone? zone(String code) {
    for (final z in zones) {
      if (z.code == code) return z;
    }
    return null;
  }
}

List<District> _parse(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final out = <District>[];
  for (final f in json['features'] as List) {
    final props = f['properties'] as Map<String, dynamic>;
    final geom = f['geometry'] as Map<String, dynamic>;
    final type = geom['type'] as String;
    final coords = geom['coordinates'] as List;
    final polys = <List<List<double>>>[];
    final rawPolys = type == 'Polygon' ? [coords] : coords;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in rawPolys) {
      final rings = <List<double>>[];
      for (final ring in p as List) {
        final flat = <double>[];
        for (final pt in ring as List) {
          final lng = (pt[0] as num).toDouble();
          final lat = (pt[1] as num).toDouble();
          flat
            ..add(lng)
            ..add(lat);
          if (lat < minLat) minLat = lat;
          if (lat > maxLat) maxLat = lat;
          if (lng < minLng) minLng = lng;
          if (lng > maxLng) maxLng = lng;
        }
        rings.add(flat);
      }
      polys.add(rings);
    }
    out.add(District(
      name: props['name'] as String,
      state: props['state'] as String,
      code: props['jakim_code'] as String,
      polygons: polys,
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    ));
  }
  return out;
}
