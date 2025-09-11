import 'mapxus_positioning_flutter_platform_interface.dart';
import 'src/models/positioning_event.dart';

export 'src/models/positioning_event.dart';

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

  /// Typed stream of positioning events with parsed objects.
  static Stream<PositioningEvent> get eventStream {
    return MapxusPositioningFlutterPlatform.instance.eventStream;
  }

  /// Stream of location events only.
  static Stream<PositioningLocationEvent> get locationStream {
    return eventStream
        .where((event) => event is PositioningLocationEvent)
        .cast<PositioningLocationEvent>();
  }

  /// Stream of state events only.
  static Stream<PositioningStateEvent> get stateStream {
    return eventStream
        .where((event) => event is PositioningStateEvent)
        .cast<PositioningStateEvent>();
  }

  /// Stream of error events only.
  static Stream<PositioningErrorEvent> get errorStream {
    return eventStream
        .where((event) => event is PositioningErrorEvent)
        .cast<PositioningErrorEvent>();
  }

  /// Stream of orientation events only.
  static Stream<PositioningOrientationEvent> get orientationStream {
    return eventStream
        .where((event) => event is PositioningOrientationEvent)
        .cast<PositioningOrientationEvent>();
  }
}
