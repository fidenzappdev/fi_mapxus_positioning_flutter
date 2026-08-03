package com.fidenz.mapxus_positioning_flutter;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.LifecycleRegistry;

import com.mapxus.positioning.positioning.api.ErrorInfo;
import com.mapxus.positioning.positioning.api.MapxusLocation;
import com.mapxus.positioning.positioning.api.MapxusPositioningClient;
import com.mapxus.positioning.positioning.api.MapxusPositioningListener;
import com.mapxus.positioning.positioning.api.PositioningState;

import java.util.HashMap;
import java.util.Map;

/**
 * MapxusPositioningForegroundService keeps the Mapxus positioning client alive
 * even after the user closes the app from the recent-apps list.
 *
 * Survival strategy:
 * ─────────────────
 * 1. Credentials (appId / secret / notification text) are persisted to
 *    SharedPreferences the moment the service starts, so they are available
 *    across process restarts.
 *
 * 2. onStartCommand() handles a null intent (Android system restart after the
 *    service was killed) by reading credentials from SharedPreferences and
 *    resuming positioning automatically — instead of stopping.
 *
 * 3. onTaskRemoved() is called when the user swipes the app away from recents.
 *    We use AlarmManager to schedule an immediate restart of the service so
 *    positioning continues uninterrupted.
 *
 * 4. START_STICKY ensures Android itself also tries to restart the service if
 *    it is killed due to low memory.
 *
 * Event delivery:
 * ───────────────
 * Events are forwarded via the static MapxusServiceEventListener which is set
 * by MapxusPositioningFlutterPlugin. When the Flutter engine is live the events
 * flow directly; when the engine is gone they are buffered in the plugin's
 * static pendingForegroundEvents list and delivered on the next app open.
 */
public class MapxusPositioningForegroundService extends Service implements LifecycleOwner {

    private static final String TAG = "MapxusFGService";

    private static final String CHANNEL_ID       = "mapxus_positioning_fg_channel";
    private static final int    NOTIFICATION_ID   = 8431;

    /** SharedPreferences file used to persist credentials across restarts. */
    private static final String PREFS_NAME = "mapxus_fg_service_prefs";

    // ── Intent actions ────────────────────────────────────────────────────────
    public static final String ACTION_START = "com.fidenz.mapxus_positioning_flutter.ACTION_START";
    public static final String ACTION_STOP  = "com.fidenz.mapxus_positioning_flutter.ACTION_STOP";

    // ── Intent / SharedPreferences keys ──────────────────────────────────────
    public static final String EXTRA_APP_ID               = "appId";
    public static final String EXTRA_SECRET               = "secret";
    public static final String EXTRA_NOTIFICATION_TITLE   = "notificationTitle";
    public static final String EXTRA_NOTIFICATION_CONTENT = "notificationContent";

    // ── Static event listener (set by the plugin) ─────────────────────────────
    private static MapxusServiceEventListener eventListener;

    // ── Instance state ────────────────────────────────────────────────────────
    private MapxusPositioningClient positioningClient;
    /** True once start() has been called and the SDK has not yet emitted STOPPED. */
    private boolean positioningActive = false;
    private final LifecycleRegistry lifecycleRegistry = new LifecycleRegistry(this);

    // ─────────────────────────────────────────────────────────────────────────
    // Event Listener Interface
    // ─────────────────────────────────────────────────────────────────────────

    public interface MapxusServiceEventListener {
        void onServiceLocationEvent(Map<String, Object> event);
        void onServiceStateEvent(Map<String, Object> event);
        void onServiceErrorEvent(Map<String, Object> event);
        void onServiceOrientationEvent(Map<String, Object> event);
    }

    public static void setEventListener(@Nullable MapxusServiceEventListener listener) {
        eventListener = listener;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Service Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    @Override
    public void onCreate() {
        super.onCreate();
        lifecycleRegistry.setCurrentState(Lifecycle.State.CREATED);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null || ACTION_START.equals(intent.getAction())) {
            // ── Determine credentials ──────────────────────────────────────
            // When intent == null, Android is restarting the service after it
            // was killed (START_STICKY). We restore credentials from prefs.
            // When intent != null (normal start), we also save them to prefs
            // so they are available for future restarts.

            String appId, secret, title, content;

            if (intent != null) {
                appId   = intent.getStringExtra(EXTRA_APP_ID);
                secret  = intent.getStringExtra(EXTRA_SECRET);
                title   = intent.getStringExtra(EXTRA_NOTIFICATION_TITLE);
                content = intent.getStringExtra(EXTRA_NOTIFICATION_CONTENT);

                if (appId != null && secret != null) {
                    // Normal start with full credentials — persist them.
                    saveCredentials(appId, secret, title, content);
                } else {
                    // Intent present but no credentials (e.g. restart via
                    // MapxusServiceRestartReceiver / AlarmManager) — restore from prefs.
                    Log.d(TAG, "No credentials in intent — restoring from prefs");
                    SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
                    appId   = prefs.getString(EXTRA_APP_ID, null);
                    secret  = prefs.getString(EXTRA_SECRET, null);
                    title   = prefs.getString(EXTRA_NOTIFICATION_TITLE,   "Mapxus Positioning");
                    content = prefs.getString(EXTRA_NOTIFICATION_CONTENT, "Location tracking is active");
                }
            } else {
                // Null intent — Android system restart (START_STICKY).
                Log.d(TAG, "Service restarted by system — restoring credentials from prefs");
                SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
                appId   = prefs.getString(EXTRA_APP_ID, null);
                secret  = prefs.getString(EXTRA_SECRET, null);
                title   = prefs.getString(EXTRA_NOTIFICATION_TITLE,   "Mapxus Positioning");
                content = prefs.getString(EXTRA_NOTIFICATION_CONTENT, "Location tracking is active");
            }

            if (appId != null && secret != null) {
                startPositioning(appId, secret, title, content);
            } else {
                Log.e(TAG, "No credentials found — stopping service");
                stopSelf();
            }

        } else if (ACTION_STOP.equals(intent.getAction())) {
            clearCredentials();
            stopSelf();
        }

        return START_STICKY;
    }

    /**
     * Called when the user swipes the app away from the recent-apps list.
     *
     * With android:stopWithTask="false" in the manifest the service normally
     * keeps running, but aggressive OEM battery optimisers (Xiaomi, Samsung,
     * Huawei, etc.) may still kill it.  We schedule an AlarmManager broadcast
     * as a safety net so positioning resumes within ~1 second.
     *
     * Why a broadcast and not PendingIntent.getService()?
     * On Android 8+ (API 26), Context.startService() from a background context
     * throws IllegalStateException. We must call startForegroundService() which
     * is only reachable from a BroadcastReceiver in this path.
     */
    @Override
    public void onTaskRemoved(Intent rootIntent) {
        Log.d(TAG, "App removed from recents — scheduling safety-net restart via AlarmManager");

        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);

        // Only reschedule if credentials are saved (developer started the service).
        // clearCredentials() is called by stopForegroundService(), so if the developer
        // intentionally stopped the service we will NOT restart it.
        if (prefs.getString(EXTRA_APP_ID, null) != null) {
            // Target the BroadcastReceiver, which calls startForegroundService() properly.
            Intent broadcastIntent = new Intent(
                    getApplicationContext(), MapxusServiceRestartReceiver.class);

            int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    ? PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE
                    : PendingIntent.FLAG_ONE_SHOT;

            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                    getApplicationContext(), 1, broadcastIntent, flags);

            AlarmManager alarmManager = (AlarmManager) getSystemService(ALARM_SERVICE);
            if (alarmManager != null) {
                alarmManager.set(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        SystemClock.elapsedRealtime() + 1000,
                        pendingIntent
                );
            }
        }

        super.onTaskRemoved(rootIntent);
    }

    @Override
    public void onDestroy() {
        lifecycleRegistry.setCurrentState(Lifecycle.State.DESTROYED);
        stopPositioning();
        if (eventListener != null) {
            Map<String, Object> event = new HashMap<>();
            event.put("type", "stateChange");
            event.put("state", "foreground_service_stopped");
            eventListener.onServiceStateEvent(event);
        }
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @NonNull
    @Override
    public Lifecycle getLifecycle() {
        return lifecycleRegistry;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Credentials Persistence
    // ─────────────────────────────────────────────────────────────────────────

    private void saveCredentials(String appId, String secret, String title, String content) {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit()
                .putString(EXTRA_APP_ID,               appId)
                .putString(EXTRA_SECRET,               secret)
                .putString(EXTRA_NOTIFICATION_TITLE,   title   != null ? title   : "Mapxus Positioning")
                .putString(EXTRA_NOTIFICATION_CONTENT, content != null ? content : "Location tracking is active")
                .apply();
    }

    /**
     * Removes persisted credentials so the service does NOT restart automatically
     * after being stopped intentionally via stopForegroundService().
     */
    private void clearCredentials() {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit().clear().apply();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Positioning Logic
    // ─────────────────────────────────────────────────────────────────────────

    private void startPositioning(String appId, String secret, String title, String content) {
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, buildNotification(
                title   != null ? title   : "Mapxus Positioning",
                content != null ? content : "Location tracking is active"
        ));

        // Only advance to RESUMED if not already there.
        // On an AlarmManager restart the same service instance survives so the
        // lifecycle is already RESUMED — skipping the transition avoids the
        // unnecessary ON_PAUSE / ON_RESUME cycle on SDK lifecycle observers.
        if (!lifecycleRegistry.getCurrentState().isAtLeast(Lifecycle.State.RESUMED)) {
            lifecycleRegistry.setCurrentState(Lifecycle.State.STARTED);
            lifecycleRegistry.setCurrentState(Lifecycle.State.RESUMED);
        }

        if (positioningActive) {
            // The client is already running (same service instance, AlarmManager
            // restart). Calling start() again on the main thread while Flutter is
            // initialising blocks the first-frame render and causes a white screen.
            // The existing client continues emitting events — nothing to do here.
            Log.d(TAG, "Foreground positioning already active — skipping restart");
            return;
        }

        try {
            if (positioningClient == null) {
                positioningClient = MapxusPositioningClient.getInstance(
                        this, this, appId, secret);
                positioningClient.addPositioningListener(positioningListener);
            }
            positioningClient.start();
            Log.d(TAG, "Foreground positioning started");
        } catch (Exception e) {
            Log.e(TAG, "Failed to start foreground positioning: " + e.getMessage());
            if (eventListener != null) {
                Map<String, Object> event = new HashMap<>();
                event.put("type", "error");
                event.put("message", "Foreground service failed to start positioning: " + e.getMessage());
                event.put("code", -1);
                eventListener.onServiceErrorEvent(event);
            }
        }
    }

    private void stopPositioning() {
        positioningActive = false;
        if (positioningClient != null) {
            try {
                // Remove the listener before stopping so it is not left registered
                // on the SDK singleton. If we don't do this, the next call to
                // getInstance() returns the same instance and addPositioningListener
                // registers it a second time, causing every event to fire twice.
                positioningClient.removePositioningListener(positioningListener);
                positioningClient.stop();
            } catch (Exception e) {
                Log.e(TAG, "Error stopping positioning client: " + e.getMessage());
            }
            positioningClient = null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Positioning Listener
    // ─────────────────────────────────────────────────────────────────────────

    private final MapxusPositioningListener positioningListener = new MapxusPositioningListener() {

        @Override
        public void onStateChange(PositioningState positionerState) {
            if (eventListener == null) return;
            Map<String, Object> event = new HashMap<>();
            event.put("type", "stateChange");
            switch (positionerState) {
                case STOPPED:
                    positioningActive = false;
                    event.put("state", "stopped");
                    break;
                case RUNNING:
                    positioningActive = true;
                    event.put("state", "running");
                    break;
                default:
                    event.put("state", "unknown");
                    break;
            }
            eventListener.onServiceStateEvent(event);
        }

        @Override
        public void onError(ErrorInfo errorInfo) {
            if (eventListener == null) return;
            Map<String, Object> event = new HashMap<>();
            event.put("type", "error");
            event.put("message", errorInfo.getErrorMessage());
            event.put("code", errorInfo.getErrorCode());
            eventListener.onServiceErrorEvent(event);
        }

        @Override
        public void onOrientationChange(float orientation, int sensorAccuracy) {
            if (eventListener == null) return;
            eventListener.onServiceOrientationEvent(
                    MapxusEventUtil.orientationChangeEvent(orientation, sensorAccuracy));
        }

        @Override
        public void onLocationChange(MapxusLocation location) {
            if (eventListener == null) return;
            eventListener.onServiceLocationEvent(MapxusEventUtil.mapLocationEvent(location));
        }
    };

    // ─────────────────────────────────────────────────────────────────────────
    // Notification Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Mapxus Positioning Service", NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Used for background indoor positioning");
            channel.setShowBadge(false);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }
    }

    private Notification buildNotification(String title, String content) {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (launchIntent != null) {
            // Bring existing activity to front rather than stacking a new one on top.
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        }
        int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                : PendingIntent.FLAG_UPDATE_CURRENT;
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, launchIntent != null ? launchIntent : new Intent(), flags);

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(android.R.drawable.ic_menu_mylocation)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }
}
