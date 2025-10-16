class MapxusMethodResponse {
  final bool success;
  final String message;

  MapxusMethodResponse({
    required this.success,
    required this.message,
  });

  /// Factory constructor to create from Map (from platform channel)
  factory MapxusMethodResponse.fromMap(Map<dynamic, dynamic> map) {
    return MapxusMethodResponse(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
    );
  }

  /// Convert to Map (useful if you send it back to native)
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
    };
  }

  @override
  String toString() => 'MapxusMethodResponse(success: $success, message: $message)';
}
