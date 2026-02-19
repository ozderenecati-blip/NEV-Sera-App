import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'gps_helper.dart';

Future<GpsKonum> getCurrentPosition() async {
  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
  );

  return GpsKonum(
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracy: pos.accuracy,
  );
}
