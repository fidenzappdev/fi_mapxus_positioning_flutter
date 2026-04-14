package com.fidenz.mapxus_positioning_flutter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

/**
 * BroadcastReceiver that restarts the MapxusPositioningForegroundService.
 *
 * Why a receiver instead of a direct PendingIntent.getService()?
 * ─────────────────────────────────────────────────────────────────
 * On Android 8+ (API 26+), calling Context.startService() from a background
 * context (such as an AlarmManager callback) throws:
 *
 *   IllegalStateException: Not allowed to start service Intent from background
 *
 * The correct call is Context.startForegroundService(), but PendingIntent has
 * no equivalent FLAG_START_FOREGROUND.  The standard workaround is to fire a
 * broadcast instead, and have this receiver call startForegroundService().
 */
public class MapxusServiceRestartReceiver extends BroadcastReceiver {

    private static final String TAG = "MapxusRestartReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "Restarting MapxusPositioningForegroundService after task removal");

        Intent serviceIntent = new Intent(context, MapxusPositioningForegroundService.class);
        serviceIntent.setAction(MapxusPositioningForegroundService.ACTION_START);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }
    }
}
