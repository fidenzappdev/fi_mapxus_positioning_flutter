package com.fidenz.mapxus_positioning_flutter;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;

public final class SensorUtils {
    private SensorUtils() {
        throw new IllegalStateException("Utility class");
    }

    /**
     * Sensor status codes
     * 200 -> All sensors available
     * 201 -> Gyroscope missing but accelerometer + compass available
     * 404 -> No sensors available
     * 202 -> Partial sensors available
     */
    public static int checkSensorStatus(Context context) {

        SensorManager sensorManager =
                (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);

        if (sensorManager == null) {
            return 404;
        }

        boolean hasAccelerometer =
                sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null;

        boolean hasGyroscope =
                sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null;

        boolean hasCompass =
                sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null;

        if (!hasAccelerometer && !hasGyroscope && !hasCompass) {
            return 404;
        }

        if (hasAccelerometer && hasGyroscope && hasCompass) {
            return 200;
        }

        if (!hasGyroscope && hasAccelerometer && hasCompass) {
            return 201;
        }

        return 202;
    }

    public static String getSensorStatusMessage(int statusCode) {
        switch (statusCode) {
            case 200:
                return "All sensors available";
            case 201:
                return "Gyroscope missing but accelerometer and compass available";
            case 202:
                return "Partial sensors available";
            case 404:
                return "No sensors available";
            default:
                return "Unknown sensor status";
        }
    }
}