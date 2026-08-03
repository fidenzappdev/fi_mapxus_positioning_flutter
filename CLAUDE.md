# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the example app
cd example && flutter run

# Run Dart unit tests
flutter test

# Run example integration tests (device/emulator required)
cd example && flutter test integration_test

# Build the Android plugin AAR (optional — validates Java compilation)
cd example && flutter build apk --debug
```

## Architecture

This is a Flutter plugin (Android-only) that bridges the Mapxus Indoor Positioning SDK to Dart via two platform channels:

- **`mapxus_positioning_flutter`** — `MethodChannel` for request/response calls (init, start, stop, pause, resume, startForegroundService, etc.)
- **`mapxus_positioning_stream`** — `EventChannel` for continuous event push (location, state, error, orientation)
- **`mapxus_positioning_bg_dispatch`** — `MethodChannel` on the headless background engine; used exclusively to deliver events to the developer's `@pragma('vm:entry-point')` callback when the app is closed.

### Dart layer

| File | Role |
|---|---|
| `lib/mapxus_positioning_flutter.dart` | Public singleton API + headless engine entry point (`_mapxusBackgroundMain`) |
| `lib/mapxus_positioning_flutter_platform_interface.dart` | Abstract platform interface |
| `lib/mapxus_positioning_flutter_method_channel.dart` | Concrete channel implementation; exposes `events` as a broadcast stream of `MapxusEvent` |
| `lib/models/mapxus_event_model.dart` | Event hierarchy: `MapxusLocationEvent`, `MapxusStateEvent`, `MapxusErrorEvent`, `PositioningOrientationEvent` |

### Android layer

| File | Role |
|---|---|
| `MapxusPositioningFlutterPlugin.java` | Plugin entry point; handles all method calls, owns the static event-routing state |
| `MapxusPositioningForegroundService.java` | `Service` + `LifecycleOwner`; runs the Mapxus SDK after the app is closed; restarts itself via `AlarmManager` on task removal |
| `MapxusServiceRestartReceiver.java` | `BroadcastReceiver` called by `AlarmManager`; calls `startForegroundService()` (required on API 26+) |
| `MapxusEventUtil.java` | Converts SDK objects (`MapxusLocation`, orientation) to `Map<String, Object>` for the event channel |
| `SensorUtils.java` / `PluginResponseHelper.java` | Sensor status check and standardised method response helpers |

### Event routing (critical to understand)

All foreground-service routing uses **static fields** on `MapxusPositioningFlutterPlugin` so state survives plugin-instance recreation when the Flutter engine restarts.

```
App open           → activeEventSink (live EventChannel) → Flutter events stream
App closed +
  bg handler set   → initBackgroundEngine → bgEventQueue → headless Dart engine
                     → developer's @pragma callback
App closed,
  no bg handler    → pendingForegroundEvents buffer → flushed on next app open (onListen)
```

- `onAttachedToEngine`: clears stale `activeEventSink`, destroys any background engine (prevents white-screen freeze from two simultaneous Dart isolates), then calls `reRegisterForegroundServiceListenerIfNeeded` to reconnect to a service that survived the app closure.
- `createServiceListener(context)` / `dispatchForegroundEvent(context, event)` — single shared implementation used by both start and re-register paths; routes events to the correct destination based on current state.
- Credentials (`appId`, `secret`, notification text, callback handles) are persisted to SharedPreferences (`mapxus_fg_service_prefs`) so the service can self-restart after a process kill without requiring the app to reopen.

### Key event type mapping

Native `type` string → Dart class:

| Native `type` | Dart class |
|---|---|
| `locationChange` | `MapxusLocationEvent` |
| `stateChange` | `MapxusStateEvent` |
| `error` | `MapxusErrorEvent` |
| `onOrientationChange` | `PositioningOrientationEvent` |

### Foreground service lifecycle

1. `startForegroundService(appId, secret, ...)` → saves credentials to SharedPreferences, starts `MapxusPositioningForegroundService`, registers the static `MapxusServiceEventListener`.
2. App closed (task removed) → `onTaskRemoved` fires → AlarmManager schedules a 1-second restart via `MapxusServiceRestartReceiver`.
3. App reopens → `onAttachedToEngine` → `reRegisterForegroundServiceListenerIfNeeded` → pending buffered events flushed on `onListen`.
4. `stopForegroundService()` → clears SharedPreferences (prevents auto-restart), sends `ACTION_STOP` intent.

### Background handler flow

```dart
await mapxus.setBackgroundHandler(onBackgroundLocation); // saves Dart callback handles to prefs
await mapxus.startForegroundService(appId: '...', secret: '...');
```

When the app is closed, the native `dispatchForegroundEvent` detects `bgUserCallbackHandle != -1`, calls `initBackgroundEngine` to spin up a headless Flutter engine running `_mapxusBackgroundMain()`, and routes events through `mapxus_positioning_bg_dispatch` → the developer's callback. Events that arrive before the engine signals "ready" are queued in `bgEventQueue`.
