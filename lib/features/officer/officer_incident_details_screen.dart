import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/timeline_widget.dart';
import 'assign_worker_dialog.dart';

class OfficerIncidentDetailsScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const OfficerIncidentDetailsScreen({
    super.key,
    required this.incidentId,
  });

  @override
  ConsumerState<OfficerIncidentDetailsScreen> createState() =>
      _OfficerIncidentDetailsScreenState();
}

class _OfficerIncidentDetailsScreenState
    extends ConsumerState<OfficerIncidentDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _handleAcknowledge(IncidentModel incident) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(allIncidentsProvider.notifier).acknowledge(incident.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident ${incident.id} acknowledged successfully!'),
            backgroundColor: AppColors.statusAcknowledged,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.priorityCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleOpenAssign(IncidentModel incident) {
    AssignWorkerDialog.show(context, incident);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(allIncidentsProvider);
    final incident = incidents.firstWhere(
      (i) => i.id == widget.incidentId,
      orElse: () => incidents.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Incident: ${incident.id}'),
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
            // Top Overview Card
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
                          const Icon(Icons.location_city_rounded,
                              size: 18, color: AppColors.primaryNavy),
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
                            _buildMetricItem(
                              label: 'Sensor Node',
                              value: incident.deviceId,
                              icon: Icons.sensors,
                              valueColor: AppColors.primaryNavy,
                            ),
                            _buildMetricItem(
                              label: 'Flow Rate',
                              value: '${incident.flowRate.toStringAsFixed(2)} L/min',
                              icon: Icons.water_drop,
                              valueColor: incident.status.isResolved
                                  ? AppColors.statusResolved
                                  : AppColors.priorityCritical,
                            ),
                            _buildMetricItem(
                              label: 'Total Volume',
                              value: '${incident.totalVolume.toStringAsFixed(1)} L',
                              icon: Icons.speed,
                              valueColor: AppColors.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.power_settings_new_rounded,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Pump State: ${incident.isPumpOn ? "ON (Active)" : "OFF (Auto-Shutoff)"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: incident.isPumpOn
                                        ? AppColors.pumpOn
                                        : AppColors.priorityCritical,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Detected: ${DateFormatter.formatShortDateTime(incident.detectedAt)}',
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
            ),
            const SizedBox(height: 16),

            // Assigned Field Worker Card (if assigned or resolved)
            if (incident.assignedWorkerName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.statusAssigned.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.person_pin_rounded,
                                size: 18, color: AppColors.statusAssigned),
                            SizedBox(width: 6),
                            Text(
                              'Assigned Field Technician',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusAssignedBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            incident.assignedWorkerId ?? 'WRK',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusAssigned,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.statusAssignedBg,
                          child: Text(
                            incident.assignedWorkerName![0],
                            style: const TextStyle(
                              color: AppColors.statusAssigned,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.assignedWorkerName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Assigned: ${DateFormatter.formatShortDateTime(incident.assignedAt)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.statusResolved),
                        SizedBox(width: 6),
                        Text(
                          'Resolution Report & Repair Notes',
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
                          'Resolved by: ${incident.resolvedBy ?? "Technician"}',
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

            // Full Lifecycle Audit Timeline
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
                        'Incident Lifecycle Timeline',
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

            // Dynamic Action Button based on Lifecycle Stage
            if (incident.status == IncidentStatus.identified) ...[
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _handleAcknowledge(incident),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAcknowledged,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Acknowledge Incident',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ] else if (incident.status == IncidentStatus.acknowledged) ...[
              ElevatedButton(
                onPressed: () => _handleOpenAssign(incident),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAssigned,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_add_alt_1_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Assign Field Worker',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ] else if (incident.status == IncidentStatus.assigned) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.statusAssignedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusAssignedBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.statusAssigned, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Assigned to ${incident.assignedWorkerName}. Awaiting technician repair & resolution.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusAssigned,
                        ),
                      ),
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
                    Icon(Icons.task_alt_rounded, color: AppColors.statusResolved, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Incident Resolved & Verified. Pipeline normal operation restored.',
                        style: TextStyle(
                          fontSize: 12.5,
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

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
