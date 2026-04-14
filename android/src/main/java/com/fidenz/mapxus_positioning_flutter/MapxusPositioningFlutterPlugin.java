package com.fidenz.mapxus_positioning_flutter;

import androidx.annotation.NonNull;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.view.FlutterCallbackInformation;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.app.Activity;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.plugin.common.EventChannel;

import com.mapxus.positioning.positioning.api.ErrorInfo;
import com.mapxus.positioning.positioning.api.MapxusLocation;
import com.mapxus.positioning.positioning.api.MapxusPositioningClient;
import com.mapxus.positioning.positioning.api.MapxusPositioningListener;
import com.mapxus.positioning.positioning.api.PositioningState;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * MapxusPositioningFlutterPlugin — bridge between Flutter and the Mapxus SDK.
 *
 * Event routing overview
 * ──────────────────────
 * ┌─────────────────┬────────────────────────────────────────────────────────┐
 * │ App state       │ Where events go                                        │
 * ├─────────────────┼────────────────────────────────────────────────────────┤
 * │ App open        │ activeEventSink → Flutter EventChannel (live stream)   │
 * │ App closed +    │ backgroundDispatchChannel → headless Flutter engine    │
 * │   bg handler    │ → developer's @pragma('vm:entry-point') callback       │
 * │ App closed,     │ pendingForegroundEvents buffer → flushed on next open  │
 * │   no bg handler │                                                        │
 * └─────────────────┴────────────────────────────────────────────────────────┘
 */
public class MapxusPositioningFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private static final String TAG = "MapxusFlutterPlugin";

    // ── Instance channels & references ────────────────────────────────────────
    private MethodChannel channel;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private MapxusPositioningClient positioningClient;
    public MapxusPositioningListener positioningListener;
    private Context context;
    private Activity activity;
    private boolean started;
    private boolean paused;
    private boolean initialized;
    private PluginResponseHelper responseHelper;

    // ── Static bridge — survives plugin instance recreation ───────────────────
    //
    // All foreground-service routing uses static fields so the state is
    // preserved across the plugin-instance lifecycle (Flutter engine restarts).

    /** Live sink to the main Flutter engine. Null when the app is closed. */
    private static volatile EventChannel.EventSink activeEventSink = null;

    /**
     * True while the main Flutter engine is attached (between onAttachedToEngine
     * and onDetachedFromEngine), even before the Dart side has called
     * receiveBroadcastStream() and activeEventSink is still null.
     *
     * Used by dispatchForegroundEvent to distinguish "app is opening, stream not
     * yet connected" (→ buffer in pendingForegroundEvents) from "app is truly
     * closed" (→ route through background engine if a handler is registered).
     * Without this flag, the background engine starts while the main engine is
     * still initialising, starving it and causing a blank/frozen screen.
     */
    private static volatile boolean isMainEngineActive = false;

    /** Events buffered while app is closed and no background handler is set. */
    private static final List<Map<String, Object>> pendingForegroundEvents = new ArrayList<>();
    private static final int MAX_PENDING_EVENTS = 500;

    /** Main-thread handler used by all static routing code. */
    private static final Handler fgHandler = new Handler(Looper.getMainLooper());

    // ── Background engine (headless Flutter for when app is closed) ───────────

    /** The headless engine running _mapxusBackgroundMain() in Dart. */
    private static FlutterEngine backgroundFlutterEngine = null;

    /** Method channel on the background engine for sending events to Dart. */
    private static MethodChannel backgroundDispatchChannel = null;

    /** True once the Dart background dispatcher has called back "ready". */
    private static volatile boolean bgEngineReady = false;

    /** Raw Dart handle for the developer's background callback function. */
    private static volatile long bgUserCallbackHandle = -1L;

    /** Events queued while the background engine is still initializing. */
    private static final List<Map<String, Object>> bgEventQueue = new ArrayList<>();

    // ─────────────────────────────────────────────────────────────────────────
    // FlutterPlugin lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // Clear any stale sink left over from a previously killed engine.
        // When the app is closed abruptly (task removed), the Flutter engine can
        // be torn down without calling EventChannel.StreamHandler.onCancel, so
        // activeEventSink is never nulled and keeps pointing at the dead engine.
        // Clearing it here ensures events aren't sent to a detached FlutterJNI.
        activeEventSink = null;
        // NOTE: isMainEngineActive is NOT set here. It is set in onAttachedToActivity,
        // which only fires when a real activity is attached (genuine app open).
        // onAttachedToEngine also fires for headless / Samsung phantom engines on task
        // removal, and setting the flag there would permanently block the background
        // handler. By the time any fgHandler.post() runs, onAttachedToActivity will
        // already have completed (same synchronous init sequence), so there is no race.

        // Destroy any background Flutter engine immediately.
        // Running two Dart isolates in the same process while the main engine is
        // initializing starves the main isolate and causes a white-screen freeze.
        destroyBackgroundEngine();

        context = binding.getApplicationContext();
        responseHelper = new PluginResponseHelper(context);

        channel = new MethodChannel(binding.getBinaryMessenger(), "mapxus_positioning_flutter");
        channel.setMethodCallHandler(this);

        eventChannel = new EventChannel(binding.getBinaryMessenger(), "mapxus_positioning_stream");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
                activeEventSink = events;
                flushPendingForegroundEvents(events);
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
                activeEventSink = null;
            }
        });

        // If the foreground service is already running (e.g. app was reopened),
        // re-attach the event listener so events flow to this new engine.
        reRegisterForegroundServiceListenerIfNeeded();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        isMainEngineActive = false;  // engine is gone; app is now truly closed
        channel.setMethodCallHandler(null);
        // Only clear the static sink if it still belongs to THIS engine instance.
        // When the background engine is destroyed (via destroyBackgroundEngine called
        // from onListen of the main engine), this method is invoked for the background
        // engine's plugin instance — at that point activeEventSink already points to
        // the main engine's sink and must NOT be cleared.
        if (activeEventSink == eventSink) {
            activeEventSink = null;
        }
        eventSink = null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Method call routing
    // ─────────────────────────────────────────────────────────────────────────

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "init":
                handleInit(call, result);
                break;
            case "start":
                handleStart(result);
                break;
            case "pause":
                handlePause(result);
                break;
            case "resume":
                handleResume(result);
                break;
            case "isInitialized":
                result.success(positioningClient != null);
                break;
            case "stop":
                handleStop(result);
                break;
            case "checkSensorStatus":
                handleCheckSensorStatus(result);
                break;
            case "setBackgroundHandler":
                handleSetBackgroundHandler(call, result);
                break;
            case "startForegroundService":
                handleStartForegroundService(call, result);
                break;
            case "stopForegroundService":
                handleStopForegroundService(result);
                break;
            case "isForegroundServiceRunning":
                handleIsForegroundServiceRunning(result);
                break;
            default:
                result.notImplemented();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Normal (foreground) positioning handlers
    // ─────────────────────────────────────────────────────────────────────────

    private void handleCheckSensorStatus(@NonNull MethodChannel.Result result) {
        int statusCode = SensorUtils.checkSensorStatus(context);
        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", statusCode);
        response.put("message", SensorUtils.getSensorStatusMessage(statusCode));
        result.success(response);
    }

    private void handleInit(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            if (!initialized) {
                positioningClient = MapxusPositioningClient.getInstance(
                        (LifecycleOwner) activity,
                        context,
                        call.argument("appId"),
                        call.argument("secret")
                );
                initialized = true;
                responseHelper.sendResponse(result, true, "MapxusPositioningClient initialized successfully");
            } else {
                responseHelper.sendResponse(result, false, "MapxusPositioningClient is already initialized");
            }
        } catch (Exception e) {
            initialized = false;
            responseHelper.sendError(result, "INIT_FAILED", "Error initializing MapxusPositioningClient: " + e.getMessage());
        }
    }

    private void handleStart(@NonNull MethodChannel.Result result) {
        try {
            if (initialized) {
                if (!started) {
                    positioningClient.addPositioningListener(mapxusPositioningListener);
                    positioningClient.start();
                    started = true;
                    if (eventSink != null) {
                        Map<String, Object> event = new HashMap<>();
                        event.put("type", "stateChange");
                        event.put("state", "initialized");
                        eventSink.success(event);
                    }
                    responseHelper.sendResponse(result, true, "MapxusPositioningClient started successfully");
                } else {
                    responseHelper.sendResponse(result, false, "MapxusPositioningClient is already started");
                }
            } else {
                started = false;
                responseHelper.sendResponse(result, false, "MapxusPositioningClient is not initialized");
            }
        } catch (Exception e) {
            started = false;
            responseHelper.sendError(result, "START_FAILED", "Error starting MapxusPositioningClient: " + e.getMessage());
        }
    }

    private void handleStop(@NonNull MethodChannel.Result result) {
        try {
            if (positioningClient != null) {
                positioningClient.stop();
                positioningClient = null;
                initialized = false;
                started = false;
                if (eventSink != null) {
                    Map<String, Object> event = new HashMap<>();
                    event.put("type", "stateChange");
                    event.put("state", "stopped");
                    eventSink.success(event);
                }
                responseHelper.sendResponse(result, true, "MapxusPositioningClient service stopped successfully");
            } else {
                responseHelper.sendResponse(result, false, "MapxusPositioningClient has not started yet to be stopped");
            }
        } catch (Exception e) {
            responseHelper.sendError(result, "STOP_FAILED", "Error stopping MapxusPositioningClient: " + e.getMessage());
        }
    }

    private void handlePause(@NonNull MethodChannel.Result result) {
        try {
            if (positioningClient != null && started) {
                positioningClient.pause();
                paused = true;
                if (eventSink != null) {
                    Map<String, Object> event = new HashMap<>();
                    event.put("type", "stateChange");
                    event.put("state", "paused");
                    eventSink.success(event);
                }
                responseHelper.sendResponse(result, true, "MapxusPositioningClient service paused successfully");
            } else {
                result.error("NOT_INITIALIZED_OR_STARTED", "Positioning client not started or not initialized", null);
            }
        } catch (Exception e) {
            responseHelper.sendError(result, "PAUSE_FAILED", "Error pausing MapxusPositioningClient: " + e.getMessage());
        }
    }

    private void handleResume(@NonNull MethodChannel.Result result) {
        try {
            if (positioningClient != null && paused) {
                positioningClient.resume();
                paused = false;
                if (eventSink != null) {
                    Map<String, Object> event = new HashMap<>();
                    event.put("type", "stateChange");
                    event.put("state", "started");
                    eventSink.success(event);
                }
                responseHelper.sendResponse(result, true, "MapxusPositioningClient service resumed successfully");
            } else {
                result.error("NOT_INITIALIZED", "Positioning client not paused yet to resume", null);
            }
        } catch (Exception e) {
            responseHelper.sendError(result, "RESUME_FAILED", "Error resuming MapxusPositioningClient: " + e.getMessage());
        }
    }

    public final MapxusPositioningListener mapxusPositioningListener = new MapxusPositioningListener() {
        @Override
        public void onStateChange(PositioningState positionerState) {
            Map<String, Object> event = new HashMap<>();
            event.put("type", "stateChange");
            switch (positionerState) {
                case STOPPED: event.put("state", "stopped"); break;
                case RUNNING: event.put("state", "running"); break;
                default: return;
            }
            if (eventSink != null) eventSink.success(event);
        }

        @Override
        public void onError(ErrorInfo errorInfo) {
            Log.e(TAG, errorInfo.getErrorMessage());
            if (eventSink != null) {
                MapxusEventUtil.sendEventError(eventSink, errorInfo.getErrorMessage(), errorInfo.getErrorCode());
            }
        }

        @Override
        public void onOrientationChange(float orientation, int sensorAccuracy) {
            if (eventSink != null) MapxusEventUtil.sendOrientationEvent(eventSink, orientation, sensorAccuracy);
        }

        @Override
        public void onLocationChange(MapxusLocation location) {
            if (eventSink != null) MapxusEventUtil.sendLocationEvent(eventSink, location);
        }
    };

    // ─────────────────────────────────────────────────────────────────────────
    // Background handler registration
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Saves the raw Dart callback handles (dispatcher + user's handler) to
     * SharedPreferences so they are available after a process restart.
     *
     * The dispatcher handle points to _mapxusBackgroundMain() in Dart.
     * The user handle points to the developer's registered callback.
     */
    private void handleSetBackgroundHandler(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            long dispatcherHandle = ((Number) call.argument("dispatcherHandle")).longValue();
            long userHandle       = ((Number) call.argument("userCallbackHandle")).longValue();

            context.getSharedPreferences("mapxus_fg_service_prefs", Context.MODE_PRIVATE).edit()
                    .putLong("bg_dispatcher_handle", dispatcherHandle)
                    .putLong("bg_user_handle", userHandle)
                    .apply();

            bgUserCallbackHandle = userHandle;
            responseHelper.sendResponse(result, true, "Background handler registered");
        } catch (Exception e) {
            responseHelper.sendError(result, "SET_BG_HANDLER_FAILED",
                    "Error registering background handler: " + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Foreground service handlers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Starts the foreground service and installs a static event listener.
     *
     * Events are sent directly to the Flutter stream while the app is open.
     * While the app is closed they are buffered in pendingForegroundEvents and
     * flushed when the app reopens and onListen fires.
     */
    private void handleIsForegroundServiceRunning(@NonNull MethodChannel.Result result) {
        SharedPreferences prefs = context.getSharedPreferences(
                "mapxus_fg_service_prefs", Context.MODE_PRIVATE);
        boolean running = prefs.getString(MapxusPositioningForegroundService.EXTRA_APP_ID, null) != null;
        result.success(running);
    }

    private void handleStartForegroundService(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            String appId           = call.argument("appId");
            String secret          = call.argument("secret");
            String notifTitle      = call.argument("notificationTitle");
            String notifContent    = call.argument("notificationContent");

            MapxusPositioningForegroundService.setEventListener(createServiceListener(context));

            Intent serviceIntent = new Intent(context, MapxusPositioningForegroundService.class);
            serviceIntent.setAction(MapxusPositioningForegroundService.ACTION_START);
            serviceIntent.putExtra(MapxusPositioningForegroundService.EXTRA_APP_ID,               appId);
            serviceIntent.putExtra(MapxusPositioningForegroundService.EXTRA_SECRET,               secret);
            serviceIntent.putExtra(MapxusPositioningForegroundService.EXTRA_NOTIFICATION_TITLE,   notifTitle);
            serviceIntent.putExtra(MapxusPositioningForegroundService.EXTRA_NOTIFICATION_CONTENT, notifContent);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent);
            } else {
                context.startService(serviceIntent);
            }

            responseHelper.sendResponse(result, true, "Mapxus foreground service started");
        } catch (Exception e) {
            responseHelper.sendError(result, "FOREGROUND_SERVICE_START_FAILED",
                    "Error starting foreground service: " + e.getMessage());
        }
    }

    private void handleStopForegroundService(@NonNull MethodChannel.Result result) {
        try {
            MapxusPositioningForegroundService.setEventListener(null);

            Intent serviceIntent = new Intent(context, MapxusPositioningForegroundService.class);
            serviceIntent.setAction(MapxusPositioningForegroundService.ACTION_STOP);
            context.startService(serviceIntent);

            responseHelper.sendResponse(result, true, "Mapxus foreground service stopped");
        } catch (Exception e) {
            responseHelper.sendError(result, "FOREGROUND_SERVICE_STOP_FAILED",
                    "Error stopping foreground service: " + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Background Flutter engine management (static)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Starts a headless Flutter engine that runs _mapxusBackgroundMain() in Dart.
     * The engine stays alive as long as the foreground service is running.
     *
     * Called lazily the first time an event arrives while the app is closed
     * and a background handler has been registered.
     */
    static synchronized void initBackgroundEngine(Context context) {
        if (backgroundFlutterEngine != null) return; // already initializing

        SharedPreferences prefs = context.getSharedPreferences(
                "mapxus_fg_service_prefs", Context.MODE_PRIVATE);
        final long dispatcherHandle = prefs.getLong("bg_dispatcher_handle", -1L);
        if (dispatcherHandle == -1L) {
            Log.w(TAG, "initBackgroundEngine: no dispatcher handle saved");
            return;
        }

        // Mark as "initializing" so we don't start a second engine.
        backgroundFlutterEngine = new FlutterEngine(context);

        // Flutter loader initialization can be slow — do it off the main thread.
        final Context appCtx = context.getApplicationContext();
        new Thread(() -> {
            try {
                FlutterInjector.instance().flutterLoader().startInitialization(appCtx);
                FlutterInjector.instance().flutterLoader().ensureInitializationComplete(appCtx, null);
            } catch (Exception e) {
                Log.e(TAG, "FlutterLoader init failed: " + e.getMessage());
                backgroundFlutterEngine = null;
                return;
            }

            // Engine creation and DartExecutor must run on the main thread.
            fgHandler.post(() -> {
                try {
                    FlutterCallbackInformation info =
                            FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle);
                    if (info == null) {
                        Log.e(TAG, "Callback info not found for dispatcher handle: " + dispatcherHandle);
                        backgroundFlutterEngine = null;
                        return;
                    }

                    backgroundFlutterEngine.getDartExecutor().executeDartCallback(
                            new DartExecutor.DartCallback(
                                    appCtx.getAssets(),
                                    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                                    info
                            )
                    );

                    // Set up the channel through which we'll send events to Dart.
                    MethodChannel channel = new MethodChannel(
                            backgroundFlutterEngine.getDartExecutor().getBinaryMessenger(),
                            "mapxus_positioning_bg_dispatch"
                    );

                    // Dart calls "ready" when _mapxusBackgroundMain() has finished
                    // setting up its handler and is ready to receive events.
                    channel.setMethodCallHandler((methodCall, methodResult) -> {
                        if ("ready".equals(methodCall.method)) {
                            backgroundDispatchChannel = channel;
                            bgEngineReady = true;
                            methodResult.success(null);
                            Log.d(TAG, "Background Dart engine ready. Flushing "
                                    + bgEventQueue.size() + " queued events.");
                            flushBgEventQueue(channel);
                        }
                    });

                    Log.d(TAG, "Background Flutter engine started");
                } catch (Exception e) {
                    Log.e(TAG, "Background engine setup failed: " + e.getMessage());
                    backgroundFlutterEngine = null;
                }
            });
        }).start();
    }

    /** Sends all events queued during engine initialisation to the Dart callback. */
    private static void flushBgEventQueue(MethodChannel channel) {
        synchronized (bgEventQueue) {
            for (Map<String, Object> event : bgEventQueue) {
                Map<String, Object> args = new HashMap<>();
                args.put("handle", bgUserCallbackHandle);
                args.put("event", event);
                channel.invokeMethod("onBackgroundEvent", args, null);
            }
            bgEventQueue.clear();
        }
    }

    /** Destroys the background engine and resets all related state. */
    static void destroyBackgroundEngine() {
        bgEngineReady = false;
        backgroundDispatchChannel = null;
        if (backgroundFlutterEngine != null) {
            backgroundFlutterEngine.destroy();
            backgroundFlutterEngine = null;
        }
        synchronized (bgEventQueue) {
            bgEventQueue.clear();
        }
        Log.d(TAG, "Background Flutter engine destroyed");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Pending event flush (for no-bg-handler buffering)
    // ─────────────────────────────────────────────────────────────────────────

    private static void flushPendingForegroundEvents(EventChannel.EventSink sink) {
        synchronized (pendingForegroundEvents) {
            if (!pendingForegroundEvents.isEmpty()) {
                Log.d(TAG, "Flushing " + pendingForegroundEvents.size() + " buffered foreground events");
                for (Map<String, Object> event : pendingForegroundEvents) {
                    sink.success(event);
                }
                pendingForegroundEvents.clear();
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Re-register listener when app reopens
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Re-attaches the foreground service event listener when the Flutter engine
     * restarts after the app was closed while the service was running.
     */
    private void reRegisterForegroundServiceListenerIfNeeded() {
        SharedPreferences prefs = context.getSharedPreferences(
                "mapxus_fg_service_prefs", Context.MODE_PRIVATE);
        if (prefs.getString(MapxusPositioningForegroundService.EXTRA_APP_ID, null) == null) {
            return; // Service was not running
        }

        MapxusPositioningForegroundService.setEventListener(createServiceListener(context));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Shared foreground service event routing
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Creates the foreground service event listener used both at service start
     * and on app reopen.
     *
     * Routing logic:
     *  • App open (activeEventSink != null)   → send directly to Flutter stream.
     *  • App closed + bg handler registered   → start headless engine if needed,
     *                                            queue to bgEventQueue (flushed
     *                                            once the engine signals "ready").
     *  • App closed, no bg handler            → buffer in pendingForegroundEvents
     *                                            (flushed on next app open).
     */
    private static MapxusPositioningForegroundService.MapxusServiceEventListener
    createServiceListener(Context context) {
        return new MapxusPositioningForegroundService.MapxusServiceEventListener() {
            @Override public void onServiceLocationEvent(Map<String, Object> e)    { dispatchForegroundEvent(context, e); }
            @Override public void onServiceStateEvent(Map<String, Object> e)       { dispatchForegroundEvent(context, e); }
            @Override public void onServiceErrorEvent(Map<String, Object> e)       { dispatchForegroundEvent(context, e); }
            @Override public void onServiceOrientationEvent(Map<String, Object> e) { dispatchForegroundEvent(context, e); }
        };
    }

    private static void dispatchForegroundEvent(Context context, Map<String, Object> event) {
        fgHandler.post(() -> {
            if (activeEventSink != null) {
                // App is open and stream is subscribed — send directly.
                activeEventSink.success(event);
                return;
            }

            if (isMainEngineActive) {
                // The main engine is attaching/initialising but the Dart side has
                // not yet called receiveBroadcastStream(). Buffer here; the events
                // will be delivered by flushPendingForegroundEvents() once onListen
                // fires. Starting the background engine now would create two Dart
                // isolates competing for the same process → blank/frozen screen.
                synchronized (pendingForegroundEvents) {
                    if (pendingForegroundEvents.size() < MAX_PENDING_EVENTS) {
                        pendingForegroundEvents.add(new HashMap<>(event));
                    }
                }
                return;
            }

            // App is truly closed. Check whether a background handler has been registered.
            SharedPreferences prefs = context.getSharedPreferences(
                    "mapxus_fg_service_prefs", Context.MODE_PRIVATE);
            long userHandle = prefs.getLong("bg_user_handle", -1L);

            if (userHandle != -1L) {
                // Background handler registered — route through the headless engine.
                bgUserCallbackHandle = userHandle;
                if (backgroundFlutterEngine == null) {
                    initBackgroundEngine(context);
                }
                if (bgEngineReady && backgroundDispatchChannel != null) {
                    Map<String, Object> args = new HashMap<>();
                    args.put("handle", bgUserCallbackHandle);
                    args.put("event", event);
                    backgroundDispatchChannel.invokeMethod("onBackgroundEvent", args, null);
                } else {
                    // Engine still initializing — queue; flushed once "ready" fires.
                    synchronized (bgEventQueue) {
                        if (bgEventQueue.size() < MAX_PENDING_EVENTS) {
                            bgEventQueue.add(new HashMap<>(event));
                        }
                    }
                }
            } else {
                // No background handler — buffer for delivery on next app open.
                synchronized (pendingForegroundEvents) {
                    if (pendingForegroundEvents.size() < MAX_PENDING_EVENTS) {
                        pendingForegroundEvents.add(new HashMap<>(event));
                    }
                }
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ActivityAware
    // ─────────────────────────────────────────────────────────────────────────

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        isMainEngineActive = true;  // real activity attached — genuine app open
    }

    @Override public void onDetachedFromActivityForConfigChanges() {}
    @Override public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }
    @Override public void onDetachedFromActivity() {
        isMainEngineActive = false;  // activity gone — treat as app closing
    }
}
