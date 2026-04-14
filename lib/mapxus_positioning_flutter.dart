import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mapxus_positioning_flutter_platform_interface.dart';
import 'models/mapxus_event_model.dart';
import 'models/mapxus_method_response_model.dart';
import 'models/mapxus_sensor_result_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler type
// ─────────────────────────────────────────────────────────────────────────────

/// Signature for the function called by the foreground service when a
/// positioning event arrives and the app is closed.
///
/// The function **must** be a top-level function (not a method or closure)
/// and should be annotated with `@pragma('vm:entry-point')` to prevent the
/// Dart compiler from tree-shaking it in release builds.
///
/// Example:
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> onBackgroundLocation(MapxusEvent event) async {
///   if (event is MapxusLocationEvent) {
///     await MyApi.upload(event.latitude, event.longitude);
///   }
/// }
/// ```
typedef MapxusBackgroundHandler = Future<void> Function(MapxusEvent event);

// ─────────────────────────────────────────────────────────────────────────────
// Internal background engine entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Entry point executed inside the headless Flutter engine that the Android
/// foreground service starts when the app is closed.
///
/// DO NOT call this directly. The service invokes it automatically.
/// @pragma prevents tree-shaking in release builds.
@pragma('vm:entry-point')
Future<void> _mapxusBackgroundMain() async {
  // Required to use platform channels in a headless engine.
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel _bgChannel =
      MethodChannel('mapxus_positioning_bg_dispatch');

  // Register the event handler BEFORE calling 'ready'.
  // The native side flushes queued events immediately after receiving 'ready',
  // so if the handler were registered after the await it could miss those events.
  _bgChannel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'onBackgroundEvent') {
      final dynamic rawHandle = call.arguments['handle'];
      final dynamic rawEvent = call.arguments['event'];

      if (rawEvent is Map) {
        final int handle = (rawHandle as num).toInt();
        final callback = PluginUtilities.getCallbackFromHandle(
            CallbackHandle.fromRawHandle(handle));

        if (callback != null) {
          final event =
              MapxusEvent.fromMap(rawEvent.cast<dynamic, dynamic>());
          await (callback as MapxusBackgroundHandler)(event);
        }
      }
    }
  });

  // Tell the native side we are ready to receive events.
  await _bgChannel.invokeMethod<void>('ready');
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton wrapper for the MapxusPositioningFlutter plugin.
class MapxusPositioningFlutter {
  MapxusPositioningFlutter._();

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

  Future<MapxusSensorResultModel> checkSensorStatus() =>
      _platform.checkSensorStatus();

  /// Registers a background handler that is called by the Android foreground
  /// service with every positioning event even when the app is fully closed.
  ///
  /// [handler] **must** be a top-level function annotated with
  /// `@pragma('vm:entry-point')`.  Call this **before**
  /// [startForegroundService].
  ///
  /// ```dart
  /// @pragma('vm:entry-point')
  /// Future<void> onBackgroundLocation(MapxusEvent event) async {
  ///   if (event is MapxusLocationEvent) {
  ///     await MyApi.uploadLocation(event.latitude, event.longitude);
  ///   }
  /// }
  ///
  /// // In initState / main():
  /// await mapxus.setBackgroundHandler(onBackgroundLocation);
  /// await mapxus.startForegroundService(appId: '...', secret: '...');
  /// ```
  Future<MapxusMethodResponse> setBackgroundHandler(
      MapxusBackgroundHandler handler) async {
    // Get the raw handle for our internal dispatcher entry point.
    final CallbackHandle? dispatcherHandle =
        PluginUtilities.getCallbackHandle(_mapxusBackgroundMain);

    // Get the raw handle for the developer's callback.
    final CallbackHandle? userHandle =
        PluginUtilities.getCallbackHandle(handler);

    if (dispatcherHandle == null || userHandle == null) {
      return MapxusMethodResponse.fromMap({
        'success': false,
        'message': 'Could not get callback handle. '
            'Make sure the handler is a top-level function annotated '
            "with @pragma('vm:entry-point').",
      });
    }

    return _platform.setBackgroundHandlerRaw(
      dispatcherHandle: dispatcherHandle.toRawHandle(),
      userCallbackHandle: userHandle.toRawHandle(),
    );
  }

  /// Starts the Android foreground service so positioning continues after the
  /// app is closed. Events are delivered through the same [events] stream
  /// while the app is open, and through the [setBackgroundHandler] callback
  /// while the app is closed.
  Future<MapxusMethodResponse> startForegroundService({
    required String appId,
    required String secret,
    String notificationTitle = 'Mapxus Positioning',
    String notificationContent = 'Location tracking is active',
  }) =>
      _platform.startForegroundService(
        appId: appId,
        secret: secret,
        notificationTitle: notificationTitle,
        notificationContent: notificationContent,
      );

  /// Stops the foreground service and removes the persistent notification.
  Future<MapxusMethodResponse> stopForegroundService() =>
      _platform.stopForegroundService();

  /// Returns `true` if the Android foreground service is currently running.
  ///
  /// Call this in `initState` to restore [isForegroundServiceRunning] state
  /// after the app was killed and reopened while the service was active.
  Future<bool> isForegroundServiceRunning() =>
      _platform.isForegroundServiceRunning();

  Stream<MapxusEvent> get events => _platform.events;
}
