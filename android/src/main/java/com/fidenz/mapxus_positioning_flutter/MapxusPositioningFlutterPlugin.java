package com.fidenz.mapxus_positioning_flutter;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.LifecycleRegistry;

import com.mapxus.positioning.positioning.api.ErrorInfo;
import com.mapxus.positioning.positioning.api.MapxusLocation;
import com.mapxus.positioning.positioning.api.MapxusPositioningClient;
import com.mapxus.positioning.positioning.api.MapxusPositioningListener;
import com.mapxus.positioning.positioning.api.PositioningState;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.json.JSONObject;
import org.json.JSONException;

public class MapxusPositioningFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private MethodChannel channel;
    private EventChannel eventChannel;
    private Context context;
    private Activity activity;
    private MapxusPositioningClient positioningClient;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "mapxus_positioning");
        channel.setMethodCallHandler(this);

        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "mapxus_positioning_stream");
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "init":
                String appId = call.argument("appId");
                String secret = call.argument("secret");
                positioningClient = MapxusPositioningClient.getInstance((LifecycleOwner) activity, context, appId, secret);
                eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, EventChannel.EventSink events) {
                        positioningClient.addPositioningListener(new MapxusPositioningListener() {
                            @Override
                            public void onStateChange(PositioningState state) {
                                try {
                                    JSONObject stateEvent = new JSONObject();
                                    stateEvent.put("type", "state");
                                    stateEvent.put("state", state.name());
                                    events.success(stateEvent.toString());
                                } catch (JSONException e) {
                                    events.error("JSON_ERROR", "Failed to create state JSON", e.getMessage());
                                }
                            }

                            @Override
                            public void onError(ErrorInfo errorInfo) {
                                try {
                                    JSONObject errorEvent = new JSONObject();
                                    errorEvent.put("type", "error");
                                    errorEvent.put("code", errorInfo.getErrorCode());
                                    errorEvent.put("message", errorInfo.getErrorMessage());
                                    events.success(errorEvent.toString());
                                } catch (JSONException e) {
                                    events.error("JSON_ERROR", "Failed to create error JSON", e.getMessage());
                                }
                            }

                            @Override
                            public void onOrientationChange(float orientation, int accuracy) {
                                try {
                                    JSONObject orientationEvent = new JSONObject();
                                    orientationEvent.put("type", "orientation");
                                    orientationEvent.put("orientation", orientation);
                                    orientationEvent.put("accuracy", accuracy);
                                    events.success(orientationEvent.toString());
                                } catch (JSONException e) {
                                    events.error("JSON_ERROR", "Failed to create orientation JSON", e.getMessage());
                                }
                            }

                            @Override
                            public void onLocationChange(MapxusLocation location) {
                                try {
                                    JSONObject locationEvent = new JSONObject();
                                    locationEvent.put("type", "location");
                                    locationEvent.put("latitude", location.getLatitude());
                                    locationEvent.put("longitude", location.getLongitude());
                                    locationEvent.put("accuracy", location.getAccuracy());
                                    locationEvent.put("venueId", location.getVenueId());
                                    locationEvent.put("buildingId", location.getBuildingId());
                                    
                                    // Handle potential null floor information
                                    String floorCode = null;
                                    if (location.getMapxusFloor() != null) {
                                        floorCode = location.getMapxusFloor().getCode();
                                    }
                                    locationEvent.put("floor", floorCode);
                                    
                                    locationEvent.put("timestamp", System.currentTimeMillis());
                                    events.success(locationEvent.toString());
                                } catch (JSONException e) {
                                    events.error("JSON_ERROR", "Failed to create location JSON", e.getMessage());
                                }
                            }
                        });
                    }

                    @Override
                    public void onCancel(Object args) {}
                });
                result.success(true);
                break;

            case "start":
                positioningClient.start();
                result.success(true);
                break;

            case "pause":
                positioningClient.pause();
                result.success(true);
                break;

            case "resume":
                positioningClient.resume();
                result.success(true);
                break;

            case "stop":
                positioningClient.stop();
                result.success(true);
                break;

            default:
                result.notImplemented();
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override public void onDetachedFromActivityForConfigChanges() {}
    @Override public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {}
    @Override public void onDetachedFromActivity() {}
    @Override public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
