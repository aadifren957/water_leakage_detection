import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/incident_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/timeline_widget.dart';
import 'resolve_task_dialog.dart';

class WorkerTaskDetailsScreen extends ConsumerWidget {
  final String incidentId;

  const WorkerTaskDetailsScreen({
    super.key,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(allIncidentsProvider);
    final user = ref.watch(authStateProvider.select((s) => s.user));

    final incident = incidents.firstWhere(
      (i) => i.id == incidentId,
      orElse: () => incidents.first,
    );

    final isAssignedToMe = incident.assignedWorkerId == user?.workerId ||
        incident.assignedWorkerUserId == user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Task: ${incident.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StatusBadge(status: incident.status, isCompact: true),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primaryNavy),
                          const SizedBox(width: 6),
                          Text(
                            incident.zone,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      PriorityBadge(priority: incident.priority),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    incident.location,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sensor Telemetry Snapshot
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoCol('Sensor Node', incident.deviceId, Icons.sensors),
                            _buildInfoCol(
                              'Flow Rate',
                              '${incident.flowRate.toStringAsFixed(2)} L/min',
                              Icons.water_drop,
                              color: incident.status.isResolved
                                  ? AppColors.statusResolved
                                  : AppColors.priorityCritical,
                            ),
                            _buildInfoCol(
                              'Total Volume',
                              '${incident.totalVolume.toStringAsFixed(1)} L',
                              Icons.speed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detected: ${DateFormatter.formatShortDateTime(incident.detectedAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Text(
                              'Assigned: ${DateFormatter.formatShortDateTime(incident.assignedAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusAssigned,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Resolution Notes (if resolved)
            if (incident.status.isResolved && incident.repairNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusResolvedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.statusResolvedBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.statusResolved),
                        SizedBox(width: 6),
                        Text(
                          'Repair Report & Resolution Log',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusResolved,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      incident.repairNotes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resolved by: ${incident.resolvedBy ?? "You"}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (incident.durationToResolution != null)
                          Text(
                            'Duration: ${DateFormatter.formatDuration(incident.durationToResolution!)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.statusResolved,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.timeline_rounded, size: 18, color: AppColors.primaryNavy),
                      SizedBox(width: 6),
                      Text(
                        'Incident History Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TimelineWidget(events: incident.timeline),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            if (incident.status == IncidentStatus.assigned && isAssignedToMe) ...[
              ElevatedButton(
                onPressed: () async {
                  final result = await ResolveTaskDialog.show(context, incident);
                  if (result == true) {
                    ref.read(allIncidentsProvider.notifier).refresh();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusResolved,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.task_alt_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mark as Resolved',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ] else if (incident.status == IncidentStatus.resolved) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.statusResolvedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusResolvedBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.statusResolved, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Task Completed & Logged. Great work!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusResolved,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
