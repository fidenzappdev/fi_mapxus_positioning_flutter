import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';
import 'package:mapxus_positioning_flutter/models/mapxus_event_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final mapxus = MapxusPositioningFlutter.instance;
  MapxusLocationEvent? latestLocation;
  String? lastError;
  String serviceState = "UNKNOWN";
  double orientation = 0.0;
  int sensorAccuracy = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startListener();
  }

  void startListener() {
    mapxus.events.listen((MapxusEvent event) {
      switch(event.type) {
        case 'location':
          MapxusLocationEvent locationEvent = event as MapxusLocationEvent;
          debugPrint("Location updated > Longitude: ${locationEvent.longitude} | Latitude: ${locationEvent.latitude}");
          setState(() {
            latestLocation = locationEvent;
          });
          break;
        case 'state':
          MapxusStateEvent stateEvent = event as MapxusStateEvent;
          setState(() {
            serviceState = stateEvent.state.toUpperCase();
          });
          break;
        case 'error':
          MapxusErrorEvent stateEvent = event as MapxusErrorEvent;
          setState(() {
            lastError = stateEvent.message.toUpperCase();
          });
          break;
        case 'orientation':
          PositioningOrientationEvent stateEvent = event as PositioningOrientationEvent;
          setState(() {
            orientation = event.orientation!;
            sensorAccuracy = event.accuracy!;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("App came to foreground");
        resume();
        break;
      case AppLifecycleState.paused:
        pause();
        debugPrint("App went to background");
        break;
      default:
        break;
    }
  }

  void pause() async {
    var result = await mapxus.pause();
    debugPrint("Pause result > ${result.message}");
  }

  void resume() async {
    await mapxus.resume();
  }

  void init() async {
    await mapxus.init(
      "6f772bc659464f988cbe8ecb7faa4a5b",
      "47ae5790d3024f83a81c12e78966427a"
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                serviceState,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Orientation: ${orientation.toString()}  |  Accuracy: ${sensorAccuracy.toString()}",
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              SizedBox(height: 15),
              Text(
                "Latitude: ${getCoordinates(latestLocation, "lat")}",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              SizedBox(height: 5),
              Text(
                "Longitude: ${getCoordinates(latestLocation, "lan")}",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              SizedBox(height: 40),
              OutlinedButton(
                child: Text('Initialize'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                onPressed: () async {
                  var result = await mapxus.init(
                      "6f772bc659464f988cbe8ecb7faa4a5b",
                      "47ae5790d3024f83a81c12e78966427a"
                  );
                  if(result.success) {
                    setState(() {
                      serviceState = "INITIALIZED";
                    });
                  } else {
                    setState(() {
                      lastError = result.message;
                    });
                  }
                }
              ),
              SizedBox(height: 20,),
              OutlinedButton(
                  child: Text('Start'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await mapxus.start();
                  }
              ),
              SizedBox(height: 20,),
              OutlinedButton(
                  child: Text('Pause'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    pause();
                  }
              ),
              SizedBox(height: 20,),
              OutlinedButton(
                  child: Text('Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await mapxus.resume();
                  }
              ),
              SizedBox(height: 20,),
              OutlinedButton(
                  child: Text('Check Initialized'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await mapxus.isInitialized();
                  }
              ),
              SizedBox(height: 20,),
              OutlinedButton(
                  child: Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await mapxus.stop();
                  }
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  "Last Error: ${lastError ?? "No error"}",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  String getCoordinates(MapxusLocationEvent? location, String dataType) {
    if(location != null) {
      if(dataType == "lat") {
        return location.latitude.toString();
      } else {
        return location.longitude.toString();
      }
    } else {
      return "0";
    }
  }
}
