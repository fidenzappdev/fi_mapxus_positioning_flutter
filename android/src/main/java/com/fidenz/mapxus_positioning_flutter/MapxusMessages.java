package com.fidenz.mapxus_positioning_flutter;

/**
 * Utility class containing all success and error messages
 * used throughout the MapxusPositioningFlutterPlugin.
 */
public class MapxusMessages {

    // ✅ Success Messages
    public static final String INIT_SUCCESS = "MapxusPositioningClient initialized successfully";
    public static final String INIT_ALREADY = "MapxusPositioningClient is already initialized";

    public static final String START_SUCCESS = "MapxusPositioningClient started successfully";
    public static final String START_ALREADY = "MapxusPositioningClient is already started";

    public static final String STOP_SUCCESS = "MapxusPositioningClient service stopped successfully";
    public static final String STOP_NOT_STARTED = "MapxusPositioningClient has not started yet to be stopped";

    public static final String PAUSE_SUCCESS = "MapxusPositioningClient service paused successfully";
    public static final String RESUME_SUCCESS = "MapxusPositioningClient service resumed successfully";

    // ⚠️ Error Messages
    public static final String INIT_FAILED = "Error initializing MapxusPositioningClient";
    public static final String START_FAILED = "Error starting MapxusPositioningClient";
    public static final String STOP_FAILED = "Error stopping MapxusPositioningClient";
    public static final String PAUSE_FAILED = "Error pausing MapxusPositioningClient";
    public static final String RESUME_FAILED = "Error resuming MapxusPositioningClient";

    public static final String NOT_INITIALIZED = "MapxusPositioningClient is not initialized";
    public static final String NOT_STARTED = "MapxusPositioningClient not started or not initialized";
    public static final String NOT_PAUSED = "Positioning client not paused yet to resume";

    // 🔄 State change messages
    public static final String STATE_INITIALIZED = "initialized";
    public static final String STATE_RUNNING = "running";
    public static final String STATE_PAUSED = "paused";
    public static final String STATE_STOPPED = "stopped";

    private MapxusMessages() {
        // prevent instantiation
    }
}
