import 'package:flutter_test/flutter_test.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMapxusPositioningFlutterPlatform
    with MockPlatformInterfaceMixin
    implements MapxusPositioningFlutterPlatform {
  @override
  Future<bool?> init({required String appId, required String secret}) async =>
      true;

  @override
  Future<bool?> start() async => true;

  @override
  Future<bool?> pause() async => true;

  @override
  Future<bool?> resume() async => true;

  @override
  Future<bool?> stop() async => true;

  @override
  Stream<dynamic> get positionStream => Stream.value({'test': 'data'});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapxusPositioning', () {
    late MockMapxusPositioningFlutterPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockMapxusPositioningFlutterPlatform();
      MapxusPositioningFlutterPlatform.instance = mockPlatform;
    });

    test('init calls platform method', () async {
      final result = await MapxusPositioning.init('test_app_id', 'test_secret');
      expect(result, true);
    });

    test('start calls platform method', () async {
      final result = await MapxusPositioning.start();
      expect(result, true);
    });

    test('pause calls platform method', () async {
      final result = await MapxusPositioning.pause();
      expect(result, true);
    });

    test('resume calls platform method', () async {
      final result = await MapxusPositioning.resume();
      expect(result, true);
    });

    test('stop calls platform method', () async {
      final result = await MapxusPositioning.stop();
      expect(result, true);
    });

    test('positionStream returns stream from platform', () async {
      final stream = MapxusPositioning.positionStream;
      expect(stream, isA<Stream<dynamic>>());

      final data = await stream.first;
      expect(data, {'test': 'data'});
    });
  });
}
