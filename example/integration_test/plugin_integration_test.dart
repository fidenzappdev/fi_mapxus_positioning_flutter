import 'package:flutter_test/flutter_test.dart';
import 'package:fi_mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MapxusPositioning integration test', (tester) async {
    // Initialize positioning client
    final initResult = await MapxusPositioning.init(
      'YOUR_APP_ID',
      'YOUR_SECRET',
    );
    expect(initResult, true);

    // Start positioning
    final startResult = await MapxusPositioning.start();
    expect(startResult, true);

    // Listen to stream for a few events
    final events = <dynamic>[];
    final typedEvents = <PositioningEvent>[];
    final subscription = MapxusPositioning.positionStream.listen(events.add);
    final typedSubscription = MapxusPositioning.eventStream.listen(
      typedEvents.add,
    );

    // Wait for some events
    await Future.delayed(Duration(seconds: 5));

    // Ensure at least one event received
    expect(events.isNotEmpty, true);
    expect(typedEvents.isNotEmpty, true);

    // Stop positioning
    final stopResult = await MapxusPositioning.stop();
    expect(stopResult, true);

    await subscription.cancel();
    await typedSubscription.cancel();
  });
}
