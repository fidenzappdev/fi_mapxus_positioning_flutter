import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mapxus_positioning_flutter_method_channel.dart';
import 'src/models/positioning_event.dart';

abstract class MapxusPositioningFlutterPlatform extends PlatformInterface {
  /// Constructs a MapxusPositioningFlutterPlatform.
  MapxusPositioningFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MapxusPositioningFlutterPlatform _instance =
      MethodChannelMapxusPositioningFlutter();

  /// The default instance of [MapxusPositioningFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMapxusPositioningFlutter].
  static MapxusPositioningFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MapxusPositioningFlutterPlatform] when
  /// they register themselves.
  static set instance(MapxusPositioningFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the positioning client.
  Future<bool?> init({required String appId, required String secret}) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Starts positioning.
  Future<bool?> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Pauses positioning.
  Future<bool?> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Resumes positioning.
  Future<bool?> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  /// Stops positioning.
  Future<bool?> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Event stream for state and location updates.
  Stream<dynamic> get positionStream {
    throw UnimplementedError('positionStream has not been implemented.');
  }

  /// Typed event stream for positioning events.
  Stream<PositioningEvent> get eventStream {
    return positionStream.map((data) {
      if (data is String) {
        return PositioningEvent.fromJson(data);
      }
      // For backward compatibility, handle legacy string formats
      if (data.toString().startsWith('STATE:')) {
        return PositioningStateEvent(state: data.toString().substring(6));
      } else if (data.toString().startsWith('LOCATION:')) {
        final parts = data.toString().substring(9).split(',');
        if (parts.length >= 3) {
          return PositioningLocationEvent(
            latitude: double.tryParse(parts[0]) ?? 0.0,
            longitude: double.tryParse(parts[1]) ?? 0.0,
            accuracy: parts.length > 3 ? double.tryParse(parts[3]) ?? 0.0 : 0.0,
            venueId: parts.length > 2 ? parts[2] : null,
            buildingId: parts.length > 4 ? parts[4] : null,
            floor: null,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
      throw ArgumentError('Unknown event format: $data');
    });
  }
}
