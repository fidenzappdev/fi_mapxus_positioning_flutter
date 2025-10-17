# Mapxus Positioning Flutter

[![pub package](https://img.shields.io/pub/v/mapxus_positioning_flutter.svg)](https://pub.dev/packages/fi_mapxus_positioning_flutter)
[![License](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg)](LICENSE)

A Flutter plugin for Mapxus indoor positioning services. This plugin provides real-time location tracking and positioning state management for indoor navigation applications.

> **Latest Updates (v1.0.0)**: Enhanced with typed event system, JSON format support, orientation tracking, and multiple filtered stream options while maintaining backward compatibility.

## Features

- 🏢 **Indoor Positioning**: Accurate indoor location tracking using Mapxus positioning technology
- 📡 **Real-time Updates**: Stream-based position updates with location data and positioning states
- 🎛️ **Lifecycle Management**: Full control over positioning with start, pause, resume, and stop operations
- 🔧 **Easy Integration**: Simple API for quick integration into Flutter applications
- 📱 **Android Support**: Native Android implementation with Mapxus SDK 2.3.1
- 🎯 **Typed Events**: Structured event system with dedicated objects for different event types
- 📊 **JSON Format**: Modern JSON-based event structure for better data handling
- 🧭 **Orientation Support**: Device orientation changes with accuracy information
- 🔄 **Backward Compatible**: Legacy string format still supported alongside new typed events

## Installation

Add this plugin to your `pubspec.yaml`:

```yaml
dependencies:
  mapxus_positioning_flutter: ^1.0.4
```

Then run:

```bash
flutter pub get
```

## Prerequisites

### Mapxus Account Setup

1. Create an account at [Mapxus Developer Portal](https://developer.mapxus.com/)
2. Create a new application to get your App ID and Secret
3. Configure your app's bundle identifier/package name in the Mapxus dashboard

### Android Configuration

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
```

For Android 6.0+, make sure to request location permissions at runtime.

> **ProGuard/R8 Note**: This plugin automatically includes the necessary ProGuard rules for release builds. No additional configuration is required!

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/models/mapxus_event_model.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startListener();
  }

  void startListener() {
    mapxus.events.listen((MapxusEvent event) {
      switch(event.type) {
        case 'location':
          MapxusLocationEvent locationEvent = event as MapxusLocationEvent;
          debugPrint("Location updated > Longitude: ${locationEvent.longitude} | Latitude: ${locationEvent.latitude}");
          setState(() {
            latestLocation = locationEvent;
          });
          break;
        case 'state':
          MapxusStateEvent stateEvent = event as MapxusStateEvent;
          setState(() {
            serviceState = stateEvent.state.toUpperCase();
          });
          break;
        case 'error':
          MapxusErrorEvent stateEvent = event as MapxusErrorEvent;
          setState(() {
            lastError = stateEvent.message.toUpperCase();
          });
          break;
        case 'orientation':
          PositioningOrientationEvent stateEvent = event as PositioningOrientationEvent;
          setState(() {
            orientation = event.orientation!;
            sensorAccuracy = event.accuracy!;
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
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("App came to foreground");
        resume();
        break;
      case AppLifecycleState.paused:
        pause();
        debugPrint("App went to background");
        break;
      default:
        break;
    }
  }

  void pause() async {
    var result = await mapxus.pause();
    debugPrint("Pause result > ${result.message}");
  }

  void resume() async {
    await mapxus.resume();
  }

  void init() async {
    await mapxus.init(
        "6f772bc659464f988cbe8ecb7faa4a5b",
        "47ae5790d3024f83a81c12e78966427a"
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  serviceState,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 30
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Orientation: ${orientation.toString()}  |  Accuracy: ${sensorAccuracy.toString()}",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                SizedBox(height: 15),
                Text(
                  "Latitude: ${getCoordinates(latestLocation, "lat")}",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                SizedBox(height: 5),
                Text(
                  "Longitude: ${getCoordinates(latestLocation, "lan")}",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                SizedBox(height: 40),
                OutlinedButton(
                    child: Text('Initialize'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      var result = await mapxus.init(
                          "6f772bc659464f988cbe8ecb7faa4a5b",
                          "47ae5790d3024f83a81c12e78966427a"
                      );
                      if(result.success) {
                        setState(() {
                          serviceState = "INITIALIZED";
                        });
                      } else {
                        setState(() {
                          lastError = result.message;
                        });
                      }
                    }
                ),
                SizedBox(height: 20,),
                OutlinedButton(
                    child: Text('Start'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await mapxus.start();
                    }
                ),
                SizedBox(height: 20,),
                OutlinedButton(
                    child: Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      pause();
                    }
                ),
                SizedBox(height: 20,),
                OutlinedButton(
                    child: Text('Resume'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await mapxus.resume();
                    }
                ),
                SizedBox(height: 20,),
                OutlinedButton(
                    child: Text('Check Initialized'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await mapxus.isInitialized();
                    }
                ),
                SizedBox(height: 20,),
                OutlinedButton(
                    child: Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await mapxus.stop();
                    }
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    "Last Error: ${lastError ?? "No error"}",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
        ),
      ),
    );
  }

  String getCoordinates(MapxusLocationEvent? location, String dataType) {
    if(location != null) {
      if(dataType == "lat") {
        return location.latitude.toString();
      } else {
        return location.longitude.toString();
      }
    } else {
      return "0";
    }
  }
}

```

## API Reference

### Methods

All methods return `Future<bool?>` where `true` indicates success.

#### `MapxusPositioning.init(String appId, String secret)`

Initializes the positioning client with your Mapxus credentials.

- **Parameters:**
    - `appId`: Your Mapxus application ID
    - `secret`: Your Mapxus application secret
- **Returns:** `Future<bool?>` - `true` if initialization succeeded

#### `MapxusPositioning.start()`

Starts the positioning service.

- **Returns:** `Future<bool?>` - `true` if positioning started successfully

#### `MapxusPositioning.pause()`

Pauses the positioning service without stopping it completely.

- **Returns:** `Future<bool?>` - `true` if positioning paused successfully

#### `MapxusPositioning.resume()`

Resumes a paused positioning service.

- **Returns:** `Future<bool?>` - `true` if positioning resumed successfully

#### `MapxusPositioning.stop()`

Stops the positioning service completely.

- **Returns:** `Future<bool?>` - `true` if positioning stopped successfully

### Streams

The plugin provides multiple stream options for receiving positioning updates, from raw data to filtered typed events.

#### `MapxusPositioning.positionStream`

A stream that provides real-time positioning updates in raw format (for backward compatibility).

#### `MapxusPositioning.eventStream`

A stream that provides typed positioning events as objects. **This is the recommended approach for new implementations.**

- **Event types:**
    - `PositioningLocationEvent` - Location updates with lat/lng, accuracy, venue info
    - `PositioningStateEvent` - Positioning state changes
    - `PositioningErrorEvent` - Error events with code and message
    - `PositioningOrientationEvent` - Device orientation changes

#### `MapxusPositioning.locationStream`

A filtered stream that only emits `PositioningLocationEvent` objects.

#### `MapxusPositioning.stateStream`

A filtered stream that only emits `PositioningStateEvent` objects.

#### `MapxusPositioning.errorStream`

A filtered stream that only emits `PositioningErrorEvent` objects.

#### `MapxusPositioning.orientationStream`

A filtered stream that only emits `PositioningOrientationEvent` objects.

### Event Objects

#### `PositioningLocationEvent`

```dart
class PositioningLocationEvent {
  final double latitude;
  final double longitude;
  final double accuracy;      // Accuracy in meters
  final String? venueId;      // Mapxus venue identifier
  final String? buildingId;   // Mapxus building identifier
  final String? floor;        // Floor level
  final int timestamp;        // Event timestamp
}
```

#### `PositioningStateEvent`

```dart
class PositioningStateEvent {
  final String state;         // STOPPED, RUNNING, PAUSED
}
```

#### `PositioningErrorEvent`

```dart
class PositioningErrorEvent {
  final int code;            // Error code
  final String message;      // Error description
}
```

#### `PositioningOrientationEvent`

```dart
class PositioningOrientationEvent {
  final double orientation;   // Orientation in degrees
  final int accuracy;        // Orientation accuracy level
}
```

**Positioning States:**

- `STOPPED` - Positioning service is stopped
- `RUNNING` - Positioning service is actively running
- `PAUSED` - Positioning service is paused

## Error Handling

The plugin provides error information through the position stream and method return values. Common issues:

### Authentication Errors

```
E/UserRemoteDataSource: mapxus validate appid fail
```

- **Cause**: Invalid App ID or Secret
- **Solution**: Verify your credentials in the Mapxus developer console

### Permission Errors

- **Cause**: Missing location permissions
- **Solution**: Request location permissions before initializing positioning

### Network Errors

- **Cause**: No internet connection during initialization
- **Solution**: Ensure device has internet connectivity for credential validation

## Example

Check out the [example app](example/) for a complete implementation showing:

- Initialization with credentials
- Real-time position tracking with both legacy and typed events
- State management and lifecycle handling
- Error handling and user feedback
- UI integration with live event display
- Comparison between legacy string format and new typed events

## Troubleshooting

### Common Issues

1. **"mapxus validate appid fail"**

    - Verify your App ID and Secret are correct
    - Check that your app's package name matches the one registered in Mapxus dashboard
    - Ensure your Mapxus account has positioning service enabled

2. **No location updates**

    - Verify location permissions are granted
    - Check that you're in a Mapxus-supported venue
    - Ensure Bluetooth and WiFi are enabled

3. **Initialization fails**

    - Check internet connectivity
    - Verify Mapxus service status
    - Review Android logs for detailed error messages

4. **Event parsing issues**
    - Ensure you're using the latest plugin version
    - Use typed `eventStream` instead of legacy `positionStream` for better error handling
    - Check that JSON events are properly formatted

## Platform Support

| Platform | Support          |
| -------- | ---------------- |
| Android  | ✅               |
| iOS      | ❌ (Coming soon) |

## Requirements

- Flutter >= 3.3.0
- Dart >= 3.8.1
- Android SDK >= 24

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and submit pull requests to help improve this plugin.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

Made with ❤️ by [Fidenz Technologies](https://fidenz.com)