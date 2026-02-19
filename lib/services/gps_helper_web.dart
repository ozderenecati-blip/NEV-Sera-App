import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'gps_helper.dart';

Future<GpsKonum> getCurrentPosition() async {
  final completer = Completer<GpsKonum>();

  final successCallback = (web.GeolocationPosition position) {
    final coords = position.coords;
    completer.complete(GpsKonum(
      latitude: coords.latitude.toDouble(),
      longitude: coords.longitude.toDouble(),
      accuracy: coords.accuracy.toDouble(),
    ));
  };

  final errorCallback = (web.GeolocationPositionError error) {
    completer.completeError('GPS alınamadı: ${error.message} (kod: ${error.code})');
  };

  final options = web.PositionOptions(
    enableHighAccuracy: true,
    timeout: 15000,
    maximumAge: 0,
  );

  web.window.navigator.geolocation.getCurrentPosition(
    successCallback.toJS,
    errorCallback.toJS,
    options,
  );

  return completer.future;
}
