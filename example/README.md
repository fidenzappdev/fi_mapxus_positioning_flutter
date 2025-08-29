# Mapxus Positioning Flutter Example

This example demonstrates how to use the `mapxus_positioning_flutter` plugin for indoor positioning.

## Features Demonstrated

- ✅ Initialize Mapxus positioning client
- ✅ Start and stop positioning services
- ✅ Listen to real-time position updates
- ✅ Handle positioning states and errors
- ✅ Simple UI for controlling positioning

## Prerequisites

1. **Mapxus Developer Account**

   - Sign up at [Mapxus Developer Portal](https://developer.mapxus.com/)
   - Create a new application to get your App ID and Secret
   - Note your app's package name: `com.fidenz.mapxus_positioning_flutter_example`

2. **Device Requirements**
   - Android device with API level 24+
   - Location permissions enabled
   - Bluetooth and WiFi enabled
   - Internet connectivity for initialization

## Setup

1. **Update Credentials**

   Open `lib/main.dart` and replace the placeholder credentials:

   ```dart
   final bool? result = await MapxusPositioning.init(
     'YOUR_MAPXUS_APP_ID',    // Replace with your actual App ID
     'YOUR_MAPXUS_SECRET',    // Replace with your actual Secret
   );
   ```

2. **Grant Permissions**

   The app will request location permissions at runtime. Make sure to allow them for proper functionality.

3. **Run the Example**
   ```bash
   flutter run
   ```

## Usage

1. **Initialize**: Tap "Initialize" to set up the positioning client with your credentials
2. **Start Positioning**: Once initialized, tap "Start Positioning" to begin location tracking
3. **Monitor Updates**: Watch the position events list for real-time location data and state changes
4. **Stop Positioning**: Tap "Stop Positioning" to end the positioning session

## Understanding the Output

The example displays two types of position updates:

- **State Updates**: `STATE:RUNNING`, `STATE:STOPPED`, etc.
- **Location Updates**: `LOCATION:latitude,longitude,accuracy`

Example output:

```
Position: STATE:RUNNING
Position: LOCATION:1.3521,103.8198,5.2
Position: LOCATION:1.3522,103.8199,4.8
```

## Troubleshooting

### Common Issues

1. **Initialization Fails**

   - Verify your App ID and Secret are correct
   - Check internet connectivity
   - Ensure package name matches your Mapxus app configuration

2. **No Location Updates**

   - Grant location permissions
   - Enable Bluetooth and WiFi
   - Ensure you're in a Mapxus-enabled venue

3. **Permission Denied**
   - Check that location permissions are granted in device settings
   - For Android 11+, ensure "Precise location" is enabled

For more help, check the [main plugin documentation](../README.md).
