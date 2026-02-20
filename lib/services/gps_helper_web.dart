import 'dart:async';
import 'dart:js_interop';
import 'gps_helper.dart';

@JS('navigator.geolocation.getCurrentPosition')
external void _jsGetCurrentPosition(
  JSFunction successCallback,
  JSFunction errorCallback,
  JSObject options,
);

Future<GpsKonum> getCurrentPosition() async {
  final completer = Completer<GpsKonum>();

  void onSuccess(JSObject position) {
    final coords = (position as _JSPosition).coords;
    completer.complete(GpsKonum(
      latitude: coords.latitude,
      longitude: coords.longitude,
      accuracy: coords.accuracy,
    ));
  }

  void onError(JSObject error) {
    final posError = error as _JSPositionError;
    final code = posError.code;
    final msg = posError.message;
    completer.completeError('GPS alınamadı: $msg (kod: $code)');
  }

  final options = _createPositionOptions();

  _jsGetCurrentPosition(
    onSuccess.toJS,
    onError.toJS,
    options,
  );

  return completer.future;
}

@JS()
@staticInterop
extension type _JSPosition._(JSObject _) implements JSObject {
  external _JSCoords get coords;
}

@JS()
@staticInterop
extension type _JSCoords._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
  external double get accuracy;
}

@JS()
@staticInterop
extension type _JSPositionError._(JSObject _) implements JSObject {
  external int get code;
  external String get message;
}

@JS('Object')
external JSObject _createJSObject();

JSObject _createPositionOptions() {
  final obj = _createJSObject();
  final opts = obj as _PositionOpts;
  opts.enableHighAccuracy = true;
  opts.timeout = 15000;
  opts.maximumAge = 0;
  return obj;
}

@JS()
@staticInterop
extension type _PositionOpts._(JSObject _) implements JSObject {
  external set enableHighAccuracy(bool value);
  external set timeout(int value);
  external set maximumAge(int value);
}
