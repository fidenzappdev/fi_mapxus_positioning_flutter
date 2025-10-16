class MapxusLocationEvent {
  final String type;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? venueId;
  final String? buildingId;
  final String? floor;
  final int timestamp;

  MapxusLocationEvent({
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.venueId,
    this.buildingId,
    this.floor,
    required this.timestamp,
  });

  /// Factory constructor to parse from Map received from EventChannel
  factory MapxusLocationEvent.fromMap(Map<dynamic, dynamic> map) {
    return MapxusLocationEvent(
      type: map['type'] ?? 'location',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble() ?? 0.0,
      venueId: map['venueId'],
      buildingId: map['buildingId'],
      floor: map['floor'],
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Convert back to Map if needed
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
    return 'MapxusLocationEvent(type: $type, latitude: $latitude, longitude: $longitude, accuracy: $accuracy, venueId: $venueId, buildingId: $buildingId, floor: $floor, timestamp: $timestamp)';
  }
}
