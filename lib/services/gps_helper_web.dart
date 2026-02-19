import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'gps_helper.dart';

Future<GpsKonum> getCurrentPosition() async {
  final completer = Completer<GpsKonum>();

  final geo = html.window.navigator.geolocation;

  geo.getCurrentPosition(
    enableHighAccuracy: true,
    timeout: const Duration(seconds: 15),
  ).then((pos) {
    completer.complete(GpsKonum(
      latitude: pos.coords!.latitude! as double,
      longitude: pos.coords!.longitude! as double,
      accuracy: (pos.coords!.accuracy ?? 0) as double,
    ));
  }).catchError((error) {
    completer.completeError('GPS alınamadı: $error');
  });

  return completer.future;
}
