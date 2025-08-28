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
                                events.success("STATE:" + state.name());
                            }

                            @Override
                            public void onError(ErrorInfo errorInfo) {
                                events.error("POSITIONING_ERROR", errorInfo.getErrorMessage(), null);
                            }

                            @Override
                            public void onOrientationChange(float orientation, int accuracy) {
                                // optional: send orientation
                            }

                            @Override
                            public void onLocationChange(MapxusLocation location) {
                                // send location data back to Flutter
                                events.success("LOCATION:" +
                                        location.getLatitude() + "," +
                                        location.getLongitude() + "," +
                                        location.getAccuracy());
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
