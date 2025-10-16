import 'mapxus_positioning_flutter_platform_interface.dart';
import 'models/mapxus_event_model.dart';
import 'models/mapxus_method_response_model.dart';

/// Singleton wrapper for the MapxusPositioningFlutter plugin.
///
/// This class provides a simple way to access the positioning
/// methods and event stream through a single instance.
class MapxusPositioningFlutter {
  // Private constructor
  MapxusPositioningFlutter._();

  // Singleton instance
  static final MapxusPositioningFlutter instance =
  MapxusPositioningFlutter._();

  final _platform = MapxusPositioningFlutterPlatform.instance;

  Future<MapxusMethodResponse> init(String appId, String secret) =>
      _platform.init(appId, secret);

  Future<MapxusMethodResponse> start() => _platform.start();

  Future<MapxusMethodResponse> pause() => _platform.pause();

  Future<MapxusMethodResponse> resume() => _platform.resume();

  Future<MapxusMethodResponse> stop() => _platform.stop();

  Future<bool> isInitialized() => _platform.isInitialized();

  Stream<MapxusEvent> get events => _platform.events;
}
