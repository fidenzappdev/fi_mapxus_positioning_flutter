import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'mapxus_positioning_flutter_method_channel.dart';
import 'models/mapxus_event_model.dart';
import 'models/mapxus_method_response_model.dart';
import 'models/mapxus_sensor_result_model.dart';

/// Platform interface for MapxusPositioningFlutter.
///
/// This defines the contract for all platform implementations.
/// The default implementation uses the MethodChannel on Android.
abstract class MapxusPositioningFlutterPlatform extends PlatformInterface {
  MapxusPositioningFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MapxusPositioningFlutterPlatform _instance =
  MethodChannelMapxusPositioningFlutter();

  /// The default instance of [MapxusPositioningFlutterPlatform] to use.
  static MapxusPositioningFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own class
  /// that extends [MapxusPositioningFlutterPlatform] when they register.
  static set instance(MapxusPositioningFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<MapxusMethodResponse> init(String appId, String secret);
  Future<MapxusMethodResponse> start();
  Future<MapxusMethodResponse> pause();
  Future<MapxusMethodResponse> resume();
  Future<MapxusMethodResponse> stop();
  Future<bool> isInitialized();
  Future<MapxusSensorResultModel> checkSensorStatus();
  Future<MapxusMethodResponse> startForegroundService({
    required String appId,
    required String secret,
    String notificationTitle,
    String notificationContent,
  });
  Future<MapxusMethodResponse> stopForegroundService();

  /// Returns true if the Android foreground service is currently running.
  /// Use this on app startup to restore UI state after the app was killed.
  Future<bool> isForegroundServiceRunning();

  /// Stores the raw Dart callback handles so the Android foreground service
  /// can start a headless Flutter engine and call the developer's handler.
  Future<MapxusMethodResponse> setBackgroundHandlerRaw({
    required int dispatcherHandle,
    required int userCallbackHandle,
  });

  Stream<MapxusEvent> get events;
}
