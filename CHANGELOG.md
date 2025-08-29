## 1.0.0

### 🎉 Initial Release

#### Features

- **Indoor Positioning**: Complete integration with Mapxus positioning SDK 2.3.1
- **Real-time Updates**: Stream-based position updates with location coordinates and accuracy
- **State Management**: Full positioning lifecycle control (init, start, pause, resume, stop)
- **Error Handling**: Comprehensive error reporting through position stream
- **Android Support**: Native Android implementation with proper permission handling

#### Platform Support

- ✅ Android (API level 24+)
- ❌ iOS (planned for future release)

#### API Methods

- `MapxusPositioning.init(appId, secret)` - Initialize positioning client
- `MapxusPositioning.start()` - Start positioning service
- `MapxusPositioning.pause()` - Pause positioning service
- `MapxusPositioning.resume()` - Resume positioning service
- `MapxusPositioning.stop()` - Stop positioning service
- `MapxusPositioning.positionStream` - Real-time position updates stream

#### Dependencies

- Mapxus Positioning SDK: 2.3.1
- Flutter: >=3.3.0
- Dart: >=3.8.1

#### Known Issues

- Requires valid Mapxus developer credentials for initialization
- Internet connectivity required for initial credential validation
- Location permissions must be granted for proper functionality
