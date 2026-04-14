import 'package:fi_mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:fi_mapxus_positioning_flutter/models/mapxus_event_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — must be a top-level function
// ─────────────────────────────────────────────────────────────────────────────

/// Called by the Android foreground service when a positioning event arrives
/// and the app is fully closed. Runs inside a headless Flutter engine.
@pragma('vm:entry-point')
Future<void> onBackgroundLocation(MapxusEvent event) async {
  if (event is MapxusLocationEvent) {
    // Only fires inside a Mapxus-supported indoor venue.
    debugPrint(
      'BG location: lat=${event.latitude}, lng=${event.longitude}',
    );
    // Add any background work here (HTTP calls, local DB writes, etc.)
  } else if (event is PositioningOrientationEvent) {
    debugPrint(
      'BG orientation: ${event.orientation?.toStringAsFixed(1)}° accuracy=${event.accuracy}',
    );
  } else if (event is MapxusStateEvent) {
    debugPrint('BG state: ${event.state}');
  } else if (event is MapxusErrorEvent) {
    debugPrint('BG error [${event.code}]: ${event.message}');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final mapxus = MapxusPositioningFlutter.instance;

  MapxusLocationEvent? latestLocation;
  String? lastError;
  String serviceState = "UNKNOWN";
  double orientation = 0.0;
  int sensorAccuracy = 0;
  bool isForegroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startListener();
    _restoreForegroundServiceState();
  }

  /// Checks if the foreground service is already running (e.g. the app was
  /// killed and reopened while the service was active) and restores state.
  Future<void> _restoreForegroundServiceState() async {
    final running = await mapxus.isForegroundServiceRunning();
    if (running && mounted) {
      setState(() {
        isForegroundServiceRunning = true;
        serviceState = "FOREGROUND SERVICE RUNNING";
      });
    }
  }

  void startListener() {
    mapxus.events.listen((MapxusEvent event) {
      switch (event.type) {
        case 'location':
          final locationEvent = event as MapxusLocationEvent;
          debugPrint("Location updated > ${locationEvent.rawData}");
          setState(() {
            latestLocation = locationEvent;
          });
          break;
        case 'state':
          final stateEvent = event as MapxusStateEvent;
          setState(() {
            serviceState = stateEvent.state.toUpperCase();
          });
          break;
        case 'error':
          final errorEvent = event as MapxusErrorEvent;
          setState(() {
            lastError = errorEvent.message.toUpperCase();
          });
          break;
        case 'orientation':
          final orientationEvent = event as PositioningOrientationEvent;
          setState(() {
            orientation = orientationEvent.orientation ?? 0.0;
            sensorAccuracy = orientationEvent.accuracy ?? 0;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Skip pause/resume lifecycle when foreground service is managing positioning.
    if (isForegroundServiceRunning) return;

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("App came to foreground");
        _resume();
        break;
      case AppLifecycleState.paused:
        _pause();
        debugPrint("App went to background");
        break;
      default:
        break;
    }
  }

  void _pause() async {
    final result = await mapxus.pause();
    debugPrint("Pause result > ${result.message}");
  }

  void _resume() async {
    await mapxus.resume();
  }

  Future<void> _startForegroundService() async {
    // Register background handler before starting the service.
    final handlerResult = await mapxus.setBackgroundHandler(onBackgroundLocation);
    if (!handlerResult.success) {
      setState(() => lastError = handlerResult.message);
      return;
    }

    final result = await mapxus.startForegroundService(
      appId: dotenv.env['APP_ID']!,
      secret: dotenv.env['SECRET']!,
      notificationTitle: 'Mapxus Indoor Positioning',
      notificationContent: 'Location tracking is active in the background',
    );

    if (result.success) {
      setState(() {
        isForegroundServiceRunning = true;
        lastError = null;
        serviceState = "FOREGROUND SERVICE RUNNING";
      });
    } else {
      setState(() => lastError = result.message);
    }

    debugPrint("Start FG service > ${result.message}");
  }

  Future<void> _stopForegroundService() async {
    final result = await mapxus.stopForegroundService();

    if (result.success) {
      setState(() {
        isForegroundServiceRunning = false;
        serviceState = "STOPPED";
        lastError = null;
      });
    } else {
      setState(() => lastError = result.message);
    }

    debugPrint("Stop FG service > ${result.message}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Text(
                  serviceState,
                  style: const TextStyle(color: Colors.black, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (isForegroundServiceRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Foreground service active',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  "Orientation: ${orientation.toStringAsFixed(1)}°  |  Accuracy: $sensorAccuracy",
                  style:
                      const TextStyle(color: Colors.black, fontSize: 13),
                ),
                const SizedBox(height: 15),
                Text(
                  "Latitude: ${_coordText(latestLocation, 'lat')}",
                  style: const TextStyle(color: Colors.black, fontSize: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  "Longitude: ${_coordText(latestLocation, 'lan')}",
                  style: const TextStyle(color: Colors.black, fontSize: 20),
                ),
                if (latestLocation != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    "Floor: ${latestLocation!.floor ?? '-'}",
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "Raw: ${latestLocation!.toMap()}",
                      style: const TextStyle(
                          color: Colors.black, fontSize: 12),
                    ),
                  ),
                ],

                // ── Standard controls ──────────────────────────────────────
                const SizedBox(height: 30),
                const Text(
                  'Standard Positioning',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                _button('Initialize', Colors.green, () async {
                  final sensor = await mapxus.checkSensorStatus();
                  debugPrint(
                      "Sensor > ${sensor.statusCode} | ${sensor.message}");
                  final result = await mapxus.init(
                    dotenv.env['APP_ID']!,
                    dotenv.env['SECRET']!,
                  );
                  if (result.success) {
                    setState(() => serviceState = "INITIALIZED");
                  } else {
                    setState(() => lastError = result.message);
                  }
                }),
                const SizedBox(height: 12),
                _button('Start', Colors.green, () async {
                  await mapxus.start();
                }),
                const SizedBox(height: 12),
                _button('Pause', Colors.orange, () async {
                  _pause();
                }),
                const SizedBox(height: 12),
                _button('Resume', Colors.green, () async {
                  await mapxus.resume();
                }),
                const SizedBox(height: 12),
                _button('Check Initialized', Colors.blue, () async {
                  final initialized = await mapxus.isInitialized();
                  debugPrint("Is initialized: $initialized");
                }),
                const SizedBox(height: 12),
                _button('Stop', Colors.red, () async {
                  await mapxus.stop();
                }),

                // ── Foreground service controls ────────────────────────────
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Foreground Service (Background Positioning)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Keeps positioning alive even after closing the app. '
                    'Requires ACCESS_FINE_LOCATION and POST_NOTIFICATIONS permissions.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                _button(
                  'Start Foreground Service',
                  Colors.green,
                  isForegroundServiceRunning ? null : _startForegroundService,
                ),
                const SizedBox(height: 12),
                _button(
                  'Stop Foreground Service',
                  Colors.red,
                  isForegroundServiceRunning ? _stopForegroundService : null,
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    "Last Error: ${lastError ?? "No error"}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label, Color color, VoidCallback? onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(foregroundColor: color),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  String _coordText(MapxusLocationEvent? location, String type) {
    if (location == null) return '0';
    return type == 'lat'
        ? location.latitude.toString()
        : location.longitude.toString();
  }
}
