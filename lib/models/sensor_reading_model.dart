class HourlyReading {
  final String timeLabel;
  final double flowRate;
  final double pressure;

  const HourlyReading({
    required this.timeLabel,
    required this.flowRate,
    this.pressure = 2.4,
  });

  Map<String, dynamic> toJson() => {
        'timeLabel': timeLabel,
        'flowRate': flowRate,
        'pressure': pressure,
      };

  factory HourlyReading.fromJson(Map<String, dynamic> json) => HourlyReading(
        timeLabel: json['timeLabel'] as String,
        flowRate: (json['flowRate'] as num).toDouble(),
        pressure: (json['pressure'] as num?)?.toDouble() ?? 2.4,
      );
}

class SensorReadingModel {
  final String deviceId;
  final String deviceName;
  final String location;
  final double flowRate; // L/min
  final double totalVolume; // L
  final double normalBaselineFlowRate; // L/min (normal is ~3.5)
  final bool isLeakageDetected;
  final bool isPumpOn; // Read-only telemetry
  final bool isOnline;
  final DateTime lastUpdated;
  final List<HourlyReading> hourlyHistory;

  const SensorReadingModel({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.flowRate,
    required this.totalVolume,
    this.normalBaselineFlowRate = 3.5,
    required this.isLeakageDetected,
    required this.isPumpOn,
    this.isOnline = true,
    required this.lastUpdated,
    required this.hourlyHistory,
  });

  SensorReadingModel copyWith({
    String? deviceId,
    String? deviceName,
    String? location,
    double? flowRate,
    double? totalVolume,
    double? normalBaselineFlowRate,
    bool? isLeakageDetected,
    bool? isPumpOn,
    bool? isOnline,
    DateTime? lastUpdated,
    List<HourlyReading>? hourlyHistory,
  }) {
    return SensorReadingModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      location: location ?? this.location,
      flowRate: flowRate ?? this.flowRate,
      totalVolume: totalVolume ?? this.totalVolume,
      normalBaselineFlowRate:
          normalBaselineFlowRate ?? this.normalBaselineFlowRate,
      isLeakageDetected: isLeakageDetected ?? this.isLeakageDetected,
      isPumpOn: isPumpOn ?? this.isPumpOn,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hourlyHistory: hourlyHistory ?? this.hourlyHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'location': location,
      'flowRate': flowRate,
      'totalVolume': totalVolume,
      'normalBaselineFlowRate': normalBaselineFlowRate,
      'isLeakageDetected': isLeakageDetected,
      'isPumpOn': isPumpOn,
      'isOnline': isOnline,
      'lastUpdated': lastUpdated.toIso8601String(),
      'hourlyHistory': hourlyHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      location: json['location'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      normalBaselineFlowRate:
          (json['normalBaselineFlowRate'] as num?)?.toDouble() ?? 3.5,
      isLeakageDetected: json['isLeakageDetected'] as bool? ?? false,
      isPumpOn: json['isPumpOn'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      hourlyHistory: (json['hourlyHistory'] as List<dynamic>?)
              ?.map((e) => HourlyReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
