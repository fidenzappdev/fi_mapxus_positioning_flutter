import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelMapxusPositioningFlutter', () {
    late MethodChannelMapxusPositioningFlutter methodChannelPlugin;
    late MethodChannel methodChannel;
    late EventChannel eventChannel;

    const channel = MethodChannel('mapxus_positioning');
    const eventChannelName = 'mapxus_positioning_stream';

    setUp(() {
      methodChannelPlugin = MethodChannelMapxusPositioningFlutter();
      methodChannel = methodChannelPlugin.methodChannel;
      eventChannel = methodChannelPlugin.eventChannel;

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'init':
                return true;
              case 'start':
                return true;
              case 'pause':
                return true;
              case 'resume':
                return true;
              case 'stop':
                return true;
              case 'getPlatformVersion':
                return 'Android 11';
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('init returns true', () async {
      final result = await methodChannelPlugin.init(
        appId: 'test_app_id',
        secret: 'test_secret',
      );
      expect(result, true);
    });

    test('start returns true', () async {
      final result = await methodChannelPlugin.start();
      expect(result, true);
    });

    test('pause returns true', () async {
      final result = await methodChannelPlugin.pause();
      expect(result, true);
    });

    test('resume returns true', () async {
      final result = await methodChannelPlugin.resume();
      expect(result, true);
    });

    test('stop returns true', () async {
      final result = await methodChannelPlugin.stop();
      expect(result, true);
    });

    test('positionStream returns a stream', () {
      final stream = methodChannelPlugin.positionStream;
      expect(stream, isA<Stream<dynamic>>());
    });

    test('getPlatformVersion returns platform version', () async {
      final result = await methodChannelPlugin.getPlatformVersion();
      expect(result, 'Android 11');
    });

    test('init passes correct parameters', () async {
      const appId = 'test_app_id_123';
      const secret = 'test_secret_456';

      String? capturedAppId;
      String? capturedSecret;

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'init') {
              capturedAppId = methodCall.arguments['appId'];
              capturedSecret = methodCall.arguments['secret'];
              return true;
            }
            return null;
          });

      await methodChannelPlugin.init(appId: appId, secret: secret);

      expect(capturedAppId, appId);
      expect(capturedSecret, secret);
    });
  });
}
