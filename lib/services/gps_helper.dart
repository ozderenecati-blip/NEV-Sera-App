import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web GPS: conditional import
import 'gps_helper_stub.dart'
    if (dart.library.js_interop) 'gps_helper_web.dart' as web_gps;

// Native GPS: conditional import
import 'gps_helper_stub.dart'
    if (dart.library.io) 'gps_helper_native.dart' as native_gps;

/// Platform-bağımsız GPS koordinat sınıfı
class GpsKonum {
  final double latitude;
  final double longitude;
  final double accuracy;
  GpsKonum({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
  });
}

/// İki GPS noktası arası mesafe (Haversine, metre)
double gpsDistanceBetween(
    double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0; // Dünya yarıçapı (metre)
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRad(double deg) => deg * pi / 180;

/// GPS konumu al (web ve native için)
Future<GpsKonum> getCurrentGpsPosition() async {
  if (kIsWeb) {
    return web_gps.getCurrentPosition();
  } else {
    return native_gps.getCurrentPosition();
  }
}
