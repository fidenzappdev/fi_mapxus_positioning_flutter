class MapxusSensorResultModel {
  final int statusCode;
  final String message;

  MapxusSensorResultModel({
    required this.statusCode,
    required this.message,
  });

  /// Factory constructor to create from Map (from platform channel)
  factory MapxusSensorResultModel.fromMap(Map<dynamic, dynamic> map) {
    return MapxusSensorResultModel(
      statusCode: map['statusCode'] ?? 202,
      message: map['message'] ?? '',
    );
  }

  /// Convert to Map (useful if you send it back to native)
  Map<String, dynamic> toMap() {
    return {
      'statusCode': statusCode,
      'message': message,
    };
  }

  @override
  String toString() => 'MapxusMethodResponse(statusCode: $statusCode, message: $message)';
}
