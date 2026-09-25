import 'package:flutter/material.dart';
import '../models/sensor_reading_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';

class SensorCard extends StatelessWidget {
  final SensorReadingModel sensor;
  final List<SensorReadingModel> availableSensors;
  final ValueChanged<String>? onSensorSelected;

  const SensorCard({
    super.key,
    required this.sensor,
    this.availableSensors = const [],
    this.onSensorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Device Selector & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Device dropdown or ID badge
                if (availableSensors.isNotEmpty && onSensorSelected != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sensor.deviceId,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryNavy, size: 18),
                        items: availableSensors.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.deviceId,
                            child: Row(
                              children: [
                                const Icon(Icons.sensors, size: 16, color: AppColors.primaryBlue),
                                const SizedBox(width: 6),
                                Text(
                                  s.deviceId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onSensorSelected!(val);
                        },
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.sensors, size: 18, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        sensor.deviceId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),

                // Online indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (sensor.isOnline ? AppColors.sensorOnline : AppColors.sensorOffline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: sensor.isOnline ? AppColors.sensorOnline : AppColors.sensorOffline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        sensor.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sensor.isOnline
                              ? AppColors.sensorOnline
                              : AppColors.sensorOffline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sensor.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Key Telemetry Readings Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flow Rate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.water_drop_outlined, size: 15, color: AppColors.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Flow Rate',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              sensor.flowRate.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: sensor.isLeakageDetected
                                    ? AppColors.priorityCritical
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'L/min',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Total Water Volume
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.speed_outlined, size: 15, color: AppColors.secondaryCyan),
                            SizedBox(width: 4),
                            Text(
                              'Total Volume',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              sensor.totalVolume.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'L',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status & Pump State Bar (Read-only Telemetry)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sensor.isLeakageDetected
                  ? AppColors.statusIdentifiedBg
                  : AppColors.statusResolvedBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Leakage Status
                Row(
                  children: [
                    Icon(
                      sensor.isLeakageDetected
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: sensor.isLeakageDetected
                          ? AppColors.priorityCritical
                          : AppColors.statusResolved,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sensor.isLeakageDetected ? 'Leakage Detected' : 'Normal Flow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sensor.isLeakageDetected
                            ? AppColors.priorityCritical
                            : AppColors.statusResolved,
                      ),
                    ),
                  ],
                ),

                // Read-only Pump Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (sensor.isPumpOn ? AppColors.pumpOn : AppColors.pumpOff)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.power_settings_new_rounded,
                            size: 12,
                            color: sensor.isPumpOn ? AppColors.pumpOn : AppColors.pumpOff,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PUMP: ${sensor.isPumpOn ? "ON" : "OFF"}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: sensor.isPumpOn ? AppColors.pumpOn : AppColors.pumpOff,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.timeAgo(sensor.lastUpdated),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
