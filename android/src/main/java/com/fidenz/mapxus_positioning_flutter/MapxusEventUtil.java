package com.fidenz.mapxus_positioning_flutter;

import com.mapxus.positioning.positioning.api.MapxusLocation;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class MapxusEventUtil {

    /**
     * Convert MapxusLocation to a Map<String, Object> for EventChannel
     */
    public static Map<String, Object> mapLocationEvent(MapxusLocation location) {
        Map<String, Object> event = new HashMap<>();
        event.put("type", "locationChange");

        if (location != null) {
            event.put("latitude", location.getLatitude());
            event.put("longitude", location.getLongitude());
            event.put("accuracy", location.getAccuracy());
            event.put("venueId", location.getVenueId());
            event.put("buildingId", location.getBuildingId());

            String floorCode = null;
            if (location.getMapxusFloor() != null) {
                floorCode = location.getMapxusFloor().getCode();
            }
            event.put("floor", floorCode);
        }

        event.put("timestamp", System.currentTimeMillis());
        return event;
    }

    /**
     * Convert Orientation data to a Map<String, Object> for EventChannel
     */
    public static Map<String, Object> orientationChangeEvent(float orientation, int accuracy) {
        Map<String, Object> event = new HashMap<>();
        event.put("type", "onOrientationChange");
        event.put("orientation", orientation);
        event.put("accuracy", accuracy);
        return event;
    }

    /**
     * Helper to send location event to EventSink
     */
    public static void sendLocationEvent(EventChannel.EventSink events, MapxusLocation location) {
        if (events != null && location != null) {
            Map<String, Object> event = mapLocationEvent(location);
            events.success(event);
        }
    }

    /**
     * Helper to send orientation event to EventSink
     */
    public static void sendOrientationEvent(EventChannel.EventSink events, float orientation, int accuracy) {
        if (events != null) {
            Map<String, Object> event = orientationChangeEvent(orientation, accuracy);
            events.success(event);
        }
    }

    /**
     * Helper to send location error event to EventSink
     */
    public static void sendEventError(EventChannel.EventSink events, String error) {
        Map<String, Object> event = new HashMap<>();
        event.put("type", "error");
        event.put("message", error);
        if (events != null) {
            events.success(event);
        }
    }
}
