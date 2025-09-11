import 'dart:convert';

/// Base class for all positioning events
abstract class PositioningEvent {
  final String type;

  const PositioningEvent({required this.type});

  /// Factory constructor to create the appropriate event type from JSON string
  factory PositioningEvent.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final String type = json['type'];

    switch (type) {
      case 'state':
        return PositioningStateEvent.fromMap(json);
      case 'location':
        return PositioningLocationEvent.fromMap(json);
      case 'error':
        return PositioningErrorEvent.fromMap(json);
      case 'orientation':
        return PositioningOrientationEvent.fromMap(json);
      default:
        throw ArgumentError('Unknown event type: $type');
    }
  }

  Map<String, dynamic> toMap();

  String toJson() => jsonEncode(toMap());
}

/// Event representing a positioning state change
class PositioningStateEvent extends PositioningEvent {
  final String state;

  const PositioningStateEvent({required this.state}) : super(type: 'state');

  factory PositioningStateEvent.fromMap(Map<String, dynamic> map) {
    return PositioningStateEvent(state: map['state'] ?? '');
  }

  @override
  Map<String, dynamic> toMap() {
    return {'type': type, 'state': state};
  }

  @override
  String toString() => 'PositioningStateEvent(state: $state)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositioningStateEvent && other.state == state;
  }

  @override
  int get hashCode => state.hashCode;
}

/// Event representing a location update
class PositioningLocationEvent extends PositioningEvent {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? venueId;
  final String? buildingId;
  final String? floor;
  final int timestamp;

  const PositioningLocationEvent({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.venueId,
    this.buildingId,
    this.floor,
    required this.timestamp,
  }) : super(type: 'location');

  factory PositioningLocationEvent.fromMap(Map<String, dynamic> map) {
    return PositioningLocationEvent(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      venueId: map['venueId'],
      buildingId: map['buildingId'],
      floor: map['floor'],
      timestamp: map['timestamp'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'venueId': venueId,
      'buildingId': buildingId,
      'floor': floor,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'PositioningLocationEvent(latitude: $latitude, longitude: $longitude, accuracy: $accuracy, venueId: $venueId, buildingId: $buildingId, floor: $floor, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositioningLocationEvent &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.venueId == venueId &&
        other.buildingId == buildingId &&
        other.floor == floor &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        accuracy.hashCode ^
        venueId.hashCode ^
        buildingId.hashCode ^
        floor.hashCode ^
        timestamp.hashCode;
  }
}

/// Event representing an error
class PositioningErrorEvent extends PositioningEvent {
  final int code;
  final String message;

  const PositioningErrorEvent({required this.code, required this.message})
    : super(type: 'error');

  factory PositioningErrorEvent.fromMap(Map<String, dynamic> map) {
    return PositioningErrorEvent(
      code: map['code'] ?? 0,
      message: map['message'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {'type': type, 'code': code, 'message': message};
  }

  @override
  String toString() => 'PositioningErrorEvent(code: $code, message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositioningErrorEvent &&
        other.code == code &&
        other.message == message;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode;
}

/// Event representing orientation change
class PositioningOrientationEvent extends PositioningEvent {
  final double orientation;
  final int accuracy;

  const PositioningOrientationEvent({
    required this.orientation,
    required this.accuracy,
  }) : super(type: 'orientation');

  factory PositioningOrientationEvent.fromMap(Map<String, dynamic> map) {
    return PositioningOrientationEvent(
      orientation: (map['orientation'] ?? 0.0).toDouble(),
      accuracy: map['accuracy'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {'type': type, 'orientation': orientation, 'accuracy': accuracy};
  }

  @override
  String toString() =>
      'PositioningOrientationEvent(orientation: $orientation, accuracy: $accuracy)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositioningOrientationEvent &&
        other.orientation == orientation &&
        other.accuracy == accuracy;
  }

  @override
  int get hashCode => orientation.hashCode ^ accuracy.hashCode;
}
