import 'package:flutter/services.dart';

import 'mapxus_positioning_flutter_platform_interface.dart';
import 'models/mapxus_event_model.dart';
import 'models/mapxus_method_response_model.dart';
import 'models/mapxus_sensor_result_model.dart';

/// The Android (and default) implementation of the plugin
/// using Flutter’s [MethodChannel] and [EventChannel].
///
/// This class communicates with native Android code through
/// platform channels to handle Mapxus Positioning SDK methods.
class MethodChannelMapxusPositioningFlutter extends MapxusPositioningFlutterPlatform {

  /// Defines the method channel used for invoking native methods.
  static const MethodChannel _channel =
  MethodChannel('mapxus_positioning_flutter');

  /// Defines the event channel used for receiving continuous data streams.
  static const EventChannel _eventChannel =
  EventChannel('mapxus_positioning_stream');

  /// Initializes the Mapxus Positioning SDK with the given [appId] and [secret].
  ///
  /// Returns a [MapxusMethodResponse] indicating whether initialization succeeded.
  @override
  Future<MapxusMethodResponse> init(String appId, String secret) async {
    try {
      final result =
      await _channel.invokeMethod<Map<dynamic, dynamic>>('init', {
        'appId': appId,
        'secret': secret,
      });
      return MapxusMethodResponse.fromMap({
        "success": result?['success'] ?? false,
        "message": result?['message'] ?? 'Unknown error'
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        "success": false,
        "message": e.toString(),
      });
    }
  }

  /// Starts the Mapxus positioning service.
  ///
  /// Returns a [MapxusMethodResponse] with success or error message.
  @override
  Future<MapxusMethodResponse> start() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('start');
      return MapxusMethodResponse.fromMap({
        "success": result?['success'] ?? false,
        "message": result?['message'] ?? 'Unknown error'
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        "success": false,
        "message": e.toString(),
      });
    }
  }

  /// Pauses the positioning service temporarily.
  ///
  /// Useful when the app moves to the background or needs to conserve resources.
  @override
  Future<MapxusMethodResponse> pause() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pause');
      return MapxusMethodResponse.fromMap({
        "success": result?['success'] ?? false,
        "message": result?['message'] ?? 'Unknown error'
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        "success": false,
        "message": e.toString(),
      });
    }
  }

  /// Resumes the positioning service after being paused.
  ///
  /// Returns a [MapxusMethodResponse] with status of the operation.
  @override
  Future<MapxusMethodResponse> resume() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('resume');
      return MapxusMethodResponse.fromMap({
        "success": result?['success'] ?? false,
        "message": result?['message'] ?? 'Unknown error'
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        "success": false,
        "message": e.toString(),
      });
    }
  }

  /// Stops the Mapxus positioning service completely.
  ///
  /// Once stopped, the service must be re-initialized before restarting.
  @override
  Future<MapxusMethodResponse> stop() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('stop');
      return MapxusMethodResponse.fromMap({
        "success": result?['success'] ?? false,
        "message": result?['message'] ?? 'Unknown error'
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        "success": false,
        "message": e.toString(),
      });
    }
  }

  /// Checks whether the Mapxus SDK has been initialized successfully.
  ///
  /// Returns `true` if initialized, otherwise `false`.
  @override
  Future<bool> isInitialized() async {
    return await _channel.invokeMethod('isInitialized');
  }

  /// Checks the status of required sensors and returns the status code and a descriptive message.
  @override
  Future<MapxusSensorResultModel> checkSensorStatus() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkSensorStatus');
    return MapxusSensorResultModel.fromMap(result!);
  }

  /// Starts the Android foreground service for background positioning.
  ///
  /// This keeps positioning active even after the user closes the app.
  /// Events are delivered through the same [events] stream.
  ///
  /// [appId] and [secret] are your Mapxus credentials.
  /// [notificationTitle] and [notificationContent] customise the persistent notification.
  @override
  Future<MapxusMethodResponse> startForegroundService({
    required String appId,
    required String secret,
    String notificationTitle = 'Mapxus Positioning',
    String notificationContent = 'Location tracking is active',
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startForegroundService',
        {
          'appId': appId,
          'secret': secret,
          'notificationTitle': notificationTitle,
          'notificationContent': notificationContent,
        },
      );
      return MapxusMethodResponse.fromMap({
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        'success': false,
        'message': e.toString(),
      });
    }
  }

  /// Stops the Android foreground service and removes the persistent notification.
  @override
  Future<MapxusMethodResponse> stopForegroundService() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('stopForegroundService');
      return MapxusMethodResponse.fromMap({
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        'success': false,
        'message': e.toString(),
      });
    }
  }

  /// Stores the raw Dart callback handles on the native side so the foreground
  /// service can start a headless Flutter engine when the app is closed.
  @override
  Future<MapxusMethodResponse> setBackgroundHandlerRaw({
    required int dispatcherHandle,
    required int userCallbackHandle,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'setBackgroundHandler',
        {
          'dispatcherHandle': dispatcherHandle,
          'userCallbackHandle': userCallbackHandle,
        },
      );
      return MapxusMethodResponse.fromMap({
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
      });
    } catch (e) {
      return MapxusMethodResponse.fromMap({
        'success': false,
        'message': e.toString(),
      });
    }
  }

  @override
  Future<bool> isForegroundServiceRunning() async {
    return await _channel.invokeMethod<bool>('isForegroundServiceRunning') ?? false;
  }

  /// Listens to event streams from the native side.
  ///
  /// Provides continuous updates, such as location changes,
  /// through a stream of [MapxusEvent] objects.
  @override
  Stream<MapxusEvent> get events => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic map) => MapxusEvent.fromMap(map));
}
