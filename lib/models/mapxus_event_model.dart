abstract class MapxusEvent {
  final String type;
  MapxusEvent(this.type);

  factory MapxusEvent.fromMap(Map<dynamic, dynamic> map) {
    switch (map['type']) {
      case 'locationChange':
        return MapxusLocationEvent.fromMap(map);
      case 'stateChange':
        return MapxusStateEvent.fromMap(map);
      case 'error':
        return MapxusErrorEvent.fromMap(map);
      case 'onOrientationChange':
        return PositioningOrientationEvent.fromMap(map);
      default:
        return MapxusUnknownEvent(map);
    }
  }
}

class MapxusLocationEvent extends MapxusEvent {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? venueId;
  final String? buildingId;
  final String? floor;
  final int timestamp;

  MapxusLocationEvent({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.venueId,
    this.buildingId,
    this.floor,
    required this.timestamp,
  }) : super('location');

  factory MapxusLocationEvent.fromMap(Map<dynamic, dynamic> map) {
    return MapxusLocationEvent(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      accuracy: (map['accuracy'] ?? 0).toDouble(),
      venueId: map['venueId'],
      buildingId: map['buildingId'],
      floor: map['floor'],
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class MapxusStateEvent extends MapxusEvent {
  final String state;

  MapxusStateEvent({required this.state}) : super('state');

  factory MapxusStateEvent.fromMap(Map<dynamic, dynamic> map) {
    return MapxusStateEvent(state: map['state'] ?? '');
  }
}

class PositioningOrientationEvent extends MapxusEvent {
  final double? orientation;
  final int? accuracy;

  PositioningOrientationEvent({
    this.orientation,
    this.accuracy
  }) : super('orientation');

  factory PositioningOrientationEvent.fromMap(Map<dynamic, dynamic> map) {
    return PositioningOrientationEvent(
        orientation: map['orientation'] ?? '',
        accuracy: map['accuracy'] ?? ''
    );
  }
}

class MapxusErrorEvent extends MapxusEvent {
  final String message;

  MapxusErrorEvent({required this.message}) : super('error');

  factory MapxusErrorEvent.fromMap(Map<dynamic, dynamic> map) {
    return MapxusErrorEvent(message: map['message'] ?? '');
  }
}

class MapxusUnknownEvent extends MapxusEvent {
  final Map<dynamic, dynamic> data;

  MapxusUnknownEvent(this.data) : super('unknown');
}
