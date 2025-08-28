import 'package:flutter_test/flutter_test.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

class MockPlatform extends Mock implements MapxusPositioningFlutterPlatform {
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
  Stream<dynamic> get positionStream =>
      Stream<dynamic>.fromIterable(['STATE:RUNNING', 'LOCATION:1,2,3']);
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
    final events = await MapxusPositioning.positionStream.toList();
    expect(events, ['STATE:RUNNING', 'LOCATION:1,2,3']);
  });
}
