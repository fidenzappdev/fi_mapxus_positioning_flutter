import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mapxus_positioning_flutter_platform_interface.dart';
import 'src/models/positioning_event.dart';

/// An implementation of [MapxusPositioningFlutterPlatform] that uses method channels.
class MethodChannelMapxusPositioningFlutter
    extends MapxusPositioningFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mapxus_positioning');

  /// The event channel used to receive positioning updates.
  final eventChannel = const EventChannel('mapxus_positioning_stream');

  @override
  Future<bool?> init({required String appId, required String secret}) async {
    final result = await methodChannel.invokeMethod<bool>('init', {
      'appId': appId,
      'secret': secret,
    });
    return result;
  }

  @override
  Future<bool?> start() async {
    return await methodChannel.invokeMethod<bool>('start');
  }

  @override
  Future<bool?> pause() async {
    return await methodChannel.invokeMethod<bool>('pause');
  }

  @override
  Future<bool?> resume() async {
    return await methodChannel.invokeMethod<bool>('resume');
  }

  @override
  Future<bool?> stop() async {
    return await methodChannel.invokeMethod<bool>('stop');
  }

  @override
  Stream<dynamic> get positionStream {
    return eventChannel.receiveBroadcastStream();
  }
}
