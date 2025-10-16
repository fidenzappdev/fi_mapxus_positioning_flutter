package com.fidenz.mapxus_positioning_flutter;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.content.Context;
import android.app.Activity;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.plugin.common.EventChannel;

import com.mapxus.positioning.positioning.api.ErrorInfo;
import com.mapxus.positioning.positioning.api.MapxusLocation;
import com.mapxus.positioning.positioning.api.MapxusPositioningClient;
import com.mapxus.positioning.positioning.api.MapxusPositioningListener;
import com.mapxus.positioning.positioning.api.PositioningState;

import java.util.HashMap;
import java.util.Map;

/**
 * The MapxusPositioningFlutterPlugin serves as the bridge between Flutter and the native
 * Android Mapxus Positioning SDK.
 *
 * This plugin provides methods for initializing, starting, pausing, resuming,
 * and stopping the MapxusPositioningClient and broadcasts real-time events
 * (location updates, state changes, errors, and orientation changes)
 * back to Flutter using an EventChannel.
 */
public class MapxusPositioningFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    // MethodChannel for handling method calls from Flutter to native Android.
    private MethodChannel channel;

    // EventChannel for broadcasting live positioning data (e.g. location, state changes) to Flutter.
    private EventChannel eventChannel;

    // EventSink for sending continuous events to Flutter.
    private EventChannel.EventSink eventSink;

    // Mapxus Positioning client instance.
    private MapxusPositioningClient positioningClient;

    // Listener for receiving Mapxus positioning updates.
    public MapxusPositioningListener positioningListener;

    // Context and activity references required for initializing SDK components.
    private Context context;
    private Activity activity;

    // Internal flags to track the Mapxus client state.
    private boolean started;
    private boolean paused;
    private boolean initialized;

    // Tag for logging.
    private static final String TAG = "MapxusFlutterPlugin";

    // Helper class for sending structured success/error responses to Flutter.
    private PluginResponseHelper responseHelper;

    /**
     * Called when the plugin is attached to the Flutter engine.
     * Initializes both MethodChannel and EventChannel for Flutter communication.
     */
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        responseHelper = new PluginResponseHelper(context);

        // Set up the communication channel for method calls.
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "mapxus_positioning_flutter");

        // Set up the event channel for broadcasting updates.
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "mapxus_positioning_stream");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                // Store reference when Flutter begins listening for event updates.
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                // Remove reference when Flutter stops listening.
                eventSink = null;
            }
        });

        channel.setMethodCallHandler(this);
    }

    /**
     * Handles method calls invoked from Flutter via the MethodChannel.
     * Routes each method call to the corresponding handler.
     */
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);

        } else if(call.method.equals("init")) {
            handleInit(call, result);

        } else if(call.method.equals("start")) {
            handleStart(result);

        } else if(call.method.equals("pause")) {
            handlePause(result);

        } else if(call.method.equals("resume")) {
            handleResume(result);

        } else if (call.method.equals("isInitialized")) {
            boolean initialized = (positioningClient != null);
            result.success(initialized);

        } else if (call.method.equals("stop")) {
            handleStop(result);

        } else {
            result.notImplemented();
        }
    }

    /**
     * Initializes the Mapxus Positioning Client using the provided appId and secret.
     * Prevents multiple initializations and handles error states gracefully.
     */
    private void handleInit(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            if (!initialized) {
                String appId = call.argument("appId");
                String secret = call.argument("secret");

                positioningClient = MapxusPositioningClient.getInstance(
                        (LifecycleOwner) activity,
                        context,
                        appId,
                        secret
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

    /**
     * Starts the Mapxus Positioning service.
     * Registers the positioning listener and sends state change updates to Flutter.
     */
    private void handleStart(@NonNull MethodChannel.Result result) {
        try {
            if (initialized) {
                if (!started) {
                    positioningClient.addPositioningListener(mapxusPositioningListener);
                    positioningClient.start();
                    started = true;

                    // Send state update to Flutter
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
                responseHelper.sendResponse(result, false, "MapxusPositioningClient is not initialized");
                started = false;
            }
        } catch (Exception e) {
            started = false;
            responseHelper.sendError(result, "START_FAILED", "Error starting MapxusPositioningClient: " + e.getMessage());
        }
    }

    /**
     * Stops the Mapxus Positioning service and clears references.
     * Sends stop state notification to Flutter.
     */
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

    /**
     * Pauses the Mapxus Positioning service.
     * Sends a "paused" state event to Flutter.
     */
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

    /**
     * Resumes the Mapxus Positioning service if previously paused.
     * Sends a "resumed" event to Flutter.
     */
    private void handleResume(@NonNull MethodChannel.Result result) {
        try {
            if (positioningClient != null && paused) {
                positioningClient.resume();
                if (paused) {
                    paused = false;
                }

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

    /**
     * The listener for Mapxus Positioning events.
     * Handles state changes, errors, orientation, and location updates.
     */
    public final MapxusPositioningListener mapxusPositioningListener = new MapxusPositioningListener() {
        @Override
        public void onStateChange(PositioningState positionerState) {
            Map<String, Object> event = new HashMap<>();
            event.put("type", "stateChange");

            switch (positionerState) {
                case STOPPED: {
                    event.put("state", "stopped");
                    if (eventSink != null) {
                        eventSink.success(event);
                    }
                    break;
                }
                case RUNNING: {
                    event.put("state", "running");
                    if (eventSink != null) {
                        eventSink.success(event);
                    }
                    break;
                }
                default:
                    break;
            }
        }

        @Override
        public void onError(ErrorInfo errorInfo) {
            Log.e(TAG, errorInfo.getErrorMessage());
            if (eventSink != null) {
                MapxusEventUtil.sendEventError(eventSink, errorInfo.getErrorMessage());
            }
        }

        @Override
        public void onOrientationChange(float orientation, int sensorAccuracy) {
            if (eventSink != null) {
                MapxusEventUtil.sendOrientationEvent(eventSink, orientation, sensorAccuracy);
            }
        }

        @Override
        public void onLocationChange(MapxusLocation location) {
            if (eventSink != null) {
                MapxusEventUtil.sendLocationEvent(eventSink, location);
            }
        }
    };

    /**
     * Lifecycle: Called when plugin is attached to a Flutter activity.
     * Stores a reference to the current Android Activity.
     */
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override public void onDetachedFromActivityForConfigChanges() {}
    @Override public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {}
    @Override public void onDetachedFromActivity() {}

    /**
     * Called when the plugin is detached from the Flutter engine.
     * Cleans up method channel handlers.
     */
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
