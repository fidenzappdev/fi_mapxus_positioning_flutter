# Mapxus Positioning Flutter

[![pub package](https://img.shields.io/pub/v/mapxus_positioning_flutter.svg)](https://pub.dev/packages/mapxus_positioning_flutter)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter plugin for Mapxus indoor positioning services. This plugin provides real-time location tracking and positioning state management for indoor navigation applications.

## Features

- 🏢 **Indoor Positioning**: Accurate indoor location tracking using Mapxus positioning technology
- 📡 **Real-time Updates**: Stream-based position updates with location data and positioning states
- 🎛️ **Lifecycle Management**: Full control over positioning with start, pause, resume, and stop operations
- 🔧 **Easy Integration**: Simple API for quick integration into Flutter applications
- 📱 **Android Support**: Native Android implementation with Mapxus SDK 2.3.1

## Installation

Add this plugin to your `pubspec.yaml`:

```yaml
dependencies:
  mapxus_positioning_flutter: ^1.0.0
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

## Usage

### Basic Implementation

```dart
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';

class PositioningExample extends StatefulWidget {
  @override
  _PositioningExampleState createState() => _PositioningExampleState();
}

class _PositioningExampleState extends State<PositioningExample> {
  bool _isInitialized = false;
  bool _isPositioning = false;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initializePositioning();
  }

  Future<void> _initializePositioning() async {
    try {
      final result = await MapxusPositioning.init(
        'YOUR_APP_ID',
        'YOUR_SECRET',
      );

      setState(() {
        _isInitialized = result ?? false;
      });

      if (_isInitialized) {
        _listenToPositionUpdates();
      }
    } catch (e) {
      print('Initialization failed: $e');
    }
  }

  void _listenToPositionUpdates() {
    _positionSubscription = MapxusPositioning.positionStream.listen(
      (data) {
        if (data.toString().startsWith('STATE:')) {
          print('Positioning state: ${data.toString().substring(6)}');
        } else if (data.toString().startsWith('LOCATION:')) {
          final locationData = data.toString().substring(9).split(',');
          final latitude = double.parse(locationData[0]);
          final longitude = double.parse(locationData[1]);
          final accuracy = double.parse(locationData[2]);

          print('Location: $latitude, $longitude (accuracy: $accuracy)');
        }
      },
      onError: (error) {
        print('Position stream error: $error');
      },
    );
  }

  Future<void> _startPositioning() async {
    if (!_isInitialized) return;

    try {
      final result = await MapxusPositioning.start();
      setState(() {
        _isPositioning = result ?? false;
      });
    } catch (e) {
      print('Failed to start positioning: $e');
    }
  }

  Future<void> _stopPositioning() async {
    try {
      final result = await MapxusPositioning.stop();
      setState(() {
        _isPositioning = !(result ?? true);
      });
    } catch (e) {
      print('Failed to stop positioning: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapxus Positioning')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Initialized: $_isInitialized'),
            Text('Positioning: $_isPositioning'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isInitialized && !_isPositioning ? _startPositioning : null,
              child: Text('Start Positioning'),
            ),
            ElevatedButton(
              onPressed: _isPositioning ? _stopPositioning : null,
              child: Text('Stop Positioning'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### Methods

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

#### `MapxusPositioning.positionStream`

A stream that provides real-time positioning updates.

- **Stream data types:**
  - `STATE:` + state name - Positioning state changes
  - `LOCATION:` + lat,lng,accuracy - Location updates
  - Error events for positioning failures

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
- Real-time position tracking
- State management
- Error handling
- UI integration

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

## Support

- 📖 [Documentation](https://github.com/fidenz-dev/mapxus_positioning_flutter/wiki)
- 🐛 [Issue Tracker](https://github.com/fidenz-dev/mapxus_positioning_flutter/issues)
- 💬 [Discussions](https://github.com/fidenz-dev/mapxus_positioning_flutter/discussions)

---

Made with ❤️ by [Fidenz Technologies](https://fidenz.com)
