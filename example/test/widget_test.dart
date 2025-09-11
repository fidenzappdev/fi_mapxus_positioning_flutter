import 'package:flutter_test/flutter_test.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter_platform_interface.dart';
import 'package:mapxus_positioning_flutter/src/models/positioning_event.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlatform
    with MockPlatformInterfaceMixin
    implements MapxusPositioningFlutterPlatform {
  @override
  Future<bool?> init({required String appId, required String secret}) async {
    return true;
  }

  @override
  Future<bool?> start() async {
    return true;
  }

  @override
  Future<bool?> pause() async {
    return true;
  }

  @override
  Future<bool?> resume() async {
    return true;
  }

  @override
  Future<bool?> stop() async {
    return true;
  }

  @override
  Stream<dynamic> get positionStream => Stream<dynamic>.fromIterable([
    '{"type":"state","state":"RUNNING"}',
    '{"type":"location","latitude":1.0,"longitude":2.0,"accuracy":3.0,"venueId":"venue1","buildingId":"building1","floor":"1","timestamp":1234567890}',
  ]);

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
  late MockPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockPlatform();
    MapxusPositioningFlutterPlatform.instance = mockPlatform;
  });

  test('init calls platform init', () async {
    final result = await MapxusPositioning.init('123', 'abc');
    expect(result, true);
  });

  test('start calls platform start', () async {
    final result = await MapxusPositioning.start();
    expect(result, true);
  });

  test('positionStream emits events', () async {
    final events = await MapxusPositioning.positionStream.take(2).toList();
    expect(events.length, 2);
    expect(events[0], contains('state'));
    expect(events[1], contains('location'));
  });

  test('eventStream emits typed events', () async {
    final events = await MapxusPositioning.eventStream.take(2).toList();
    expect(events.length, 2);
    expect(events[0], isA<PositioningStateEvent>());
    expect(events[1], isA<PositioningLocationEvent>());

    final stateEvent = events[0] as PositioningStateEvent;
    expect(stateEvent.state, 'RUNNING');

    final locationEvent = events[1] as PositioningLocationEvent;
    expect(locationEvent.latitude, 1.0);
    expect(locationEvent.longitude, 2.0);
    expect(locationEvent.accuracy, 3.0);
  });
}
