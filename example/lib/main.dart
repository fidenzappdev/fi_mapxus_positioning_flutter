import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mapxus_positioning_flutter/mapxus_positioning_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _isPositioning = false;
  List<String> _positionEvents = [];
  List<String> _typedEvents = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeMapxus() async {
    try {
      // Replace with your actual Mapxus credentials
      // Get these from https://developer.mapxus.com/
      final bool? result = await MapxusPositioning.init(
        'YOUR_MAPXUS_APP_ID',
        'YOUR_MAPXUS_SECRET',
      );

      if (mounted) {
        setState(() {
          _isInitialized = result!;
        });
      }
    } catch (e) {
      print('Initialization failed: $e');
    }
  }

  Future<void> _startPositioning() async {
    if (!_isInitialized) {
      await _initializeMapxus();
    }

    try {
      final bool? result = await MapxusPositioning.start();

      if (mounted) {
        setState(() {
          _isPositioning = result!;
        });
      }

      // Listen to position stream (legacy format)
      MapxusPositioning.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _positionEvents.add('Legacy: $position');
            // Keep only last 5 events for display
            if (_positionEvents.length > 5) {
              _positionEvents.removeAt(0);
            }
          });
        }
      });

      // Listen to typed event stream (new format)
      MapxusPositioning.eventStream.listen((event) {
        if (mounted) {
          setState(() {
            if (event is PositioningLocationEvent) {
              _typedEvents.add(
                'Location: ${event.latitude.toStringAsFixed(6)}, ${event.longitude.toStringAsFixed(6)} (±${event.accuracy.toStringAsFixed(1)}m, floorId: ${event.floor} venueId: ${event.venueId}, buildingId: ${event.buildingId})',
              );
            } else if (event is PositioningStateEvent) {
              _typedEvents.add('State: ${event.state}');
            } else if (event is PositioningErrorEvent) {
              _typedEvents.add('Error: ${event.message} (${event.code})');
            } else if (event is PositioningOrientationEvent) {
              _typedEvents.add(
                'Orientation: ${event.orientation.toStringAsFixed(1)}° (accuracy: ${event.accuracy})',
              );
            }
            // Keep only last 5 events for display
            if (_typedEvents.length > 5) {
              _typedEvents.removeAt(0);
            }
          });
        }
      });
    } catch (e) {
      print('Start positioning failed: $e');
    }
  }

  Future<void> _stopPositioning() async {
    try {
      final bool? result = await MapxusPositioning.stop();

      if (mounted) {
        setState(() {
          _isPositioning = !result!;
        });
      }
    } catch (e) {
      print('Stop positioning failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mapxus Positioning Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Initialization status
              Text('Initialized: $_isInitialized'),

              // Positioning status
              Text('Positioning active: $_isPositioning'),

              const SizedBox(height: 20),

              // Control buttons
              Wrap(
                children: [
                  ElevatedButton(
                    onPressed: _initializeMapxus,
                    child: const Text('Initialize'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isInitialized ? _startPositioning : null,
                    child: const Text('Start Positioning'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isPositioning ? _stopPositioning : null,
                    child: const Text('Stop Positioning'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Position events (legacy format)
              const Text(
                'Legacy String Events:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _positionEvents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        _positionEvents[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              // Typed events (new format)
              const Text(
                'Typed Object Events:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _typedEvents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        _typedEvents[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
