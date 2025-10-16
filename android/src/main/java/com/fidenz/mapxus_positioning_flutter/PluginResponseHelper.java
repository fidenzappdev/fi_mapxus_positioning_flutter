package com.fidenz.mapxus_positioning_flutter;

import android.content.Context;
import android.widget.Toast;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * A helper class to standardize the structure of responses
 * sent back to Flutter through the MethodChannel.
 *
 * This ensures that all native method calls return a consistent
 * JSON-style map with the following fields:
 * - success (boolean)
 * - message (String)
 *
 * It also provides an easy way to send formatted error messages
 * or user feedback (via Toast) when operations fail.
 */
public class PluginResponseHelper {

    /** Android application context for UI-related operations like Toasts. */
    private final Context context;

    /**
     * Constructor to initialize PluginResponseHelper with the given context.
     *
     * @param context the application or activity context
     */
    public PluginResponseHelper(Context context) {
        this.context = context;
    }

    /**
     * Sends a structured success or failure response back to the Flutter side.
     *
     * @param result   the MethodChannel.Result object to send data back to Flutter
     * @param success  true if the operation was successful, false otherwise
     * @param message  a human-readable message describing the result
     */
    public void sendResponse(MethodChannel.Result result, boolean success, String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        response.put("message", message);
        result.success(response);
    }

    /**
     * Sends a structured error response to the Flutter side and
     * displays a Toast message on the Android device for debugging purposes.
     *
     * @param result   the MethodChannel.Result object used to send the error
     * @param code     a unique error code for identification
     * @param message  a descriptive error message
     */
    public void sendError(MethodChannel.Result result, String code, String message) {
        Toast.makeText(context, message, Toast.LENGTH_LONG).show();
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        result.success(response);
    }
}
