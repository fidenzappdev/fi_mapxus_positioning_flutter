import 'mapxus_positioning_flutter_platform_interface.dart';

class MapxusPositioning {
  /// Initialize the positioning client with your App ID and Secret.
  static Future<bool?> init(String appId, String secret) {
    return MapxusPositioningFlutterPlatform.instance.init(
      appId: appId,
      secret: secret,
    );
  }

  /// Start positioning.
  static Future<bool?> start() {
    return MapxusPositioningFlutterPlatform.instance.start();
  }

  /// Pause positioning.
  static Future<bool?> pause() {
    return MapxusPositioningFlutterPlatform.instance.pause();
  }

  /// Resume positioning.
  static Future<bool?> resume() {
    return MapxusPositioningFlutterPlatform.instance.resume();
  }

  /// Stop positioning.
  static Future<bool?> stop() {
    return MapxusPositioningFlutterPlatform.instance.stop();
  }

  /// Stream of positioning updates (state + location).
  static Stream<dynamic> get positionStream {
    return MapxusPositioningFlutterPlatform.instance.positionStream;
  }
}
