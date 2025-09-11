import 'package:flutter_test/flutter_test.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter_platform_interface.dart';
import 'package:mapxus_positioning_flutter/src/models/positioning_event.dart';
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
  Stream<dynamic> get positionStream =>
      Stream.value('{"type":"state","state":"RUNNING"}');

  @override
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
      expect(data, contains('state'));
    });

    test('eventStream returns typed events', () async {
      final stream = MapxusPositioning.eventStream;
      expect(stream, isA<Stream<PositioningEvent>>());

      final event = await stream.first;
      expect(event, isA<PositioningStateEvent>());
      expect((event as PositioningStateEvent).state, 'RUNNING');
    });
  });
}
