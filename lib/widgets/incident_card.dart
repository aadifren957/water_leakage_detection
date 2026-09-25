import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;
  final bool showAssignee;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showAssignee = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Incident ID, Priority & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        incident.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: incident.priority),
                    ],
                  ),
                  StatusBadge(status: incident.status, isCompact: true),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      incident.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sensor Telemetry Pills
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Device ID
                    Row(
                      children: [
                        const Icon(Icons.sensors, size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          incident.deviceId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Flow Rate
                    Row(
                      children: [
                        const Icon(Icons.water_drop, size: 14, color: AppColors.priorityCritical),
                        const SizedBox(width: 4),
                        Text(
                          '${incident.flowRate.toStringAsFixed(2)} L/min',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.priorityCritical,
                          ),
                        ),
                      ],
                    ),

                    // Time Detected
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.timeAgo(incident.detectedAt),
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

              // Assigned Worker row if applicable
              if (showAssignee && incident.assignedWorkerName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined, size: 15, color: AppColors.statusAssigned),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      incident.assignedWorkerName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusAssigned,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zone: ${incident.zone}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Row(
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryBlue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
