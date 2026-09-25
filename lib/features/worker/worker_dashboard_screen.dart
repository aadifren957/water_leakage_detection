import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/incident_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/sensor_card.dart';
import 'resolve_task_dialog.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final workerStats = ref.watch(workerStatsProvider);
    final tasks = ref.watch(workerTasksProvider);
    final selectedSensor = ref.watch(selectedSensorProvider);

    final activeTasks = tasks.where((t) => t.status == IncidentStatus.assigned).toList();
    final primaryTask = activeTasks.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: AppHeader(user: user),
          ),

          // Main Body
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary Metrics
                const Text(
                  'My Task Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'New Assigned',
                        value: '${workerStats.newAssignments}',
                        icon: Icons.assignment_outlined,
                        accentColor: AppColors.statusAssigned,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'In Progress',
                        value: '${workerStats.inProgress}',
                        icon: Icons.pending_actions_rounded,
                        accentColor: AppColors.statusIdentified,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'Completed',
                        value: '${workerStats.completed}',
                        icon: Icons.task_alt_rounded,
                        accentColor: AppColors.statusResolved,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Task Spotlight Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Assignment Spotlight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (activeTasks.isNotEmpty)
                      Text(
                        '${activeTasks.length} Active',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusAssigned,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (primaryTask != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.statusAssigned.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusAssigned.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                                Text(
                                  primaryTask.id,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PriorityBadge(priority: primaryTask.priority),
                              ],
                            ),
                            StatusBadge(status: primaryTask.status, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          primaryTask.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Telemetry Row
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sensor: ${primaryTask.deviceId}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Flow: ${primaryTask.flowRate.toStringAsFixed(2)} L/min',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.priorityCritical,
                                ),
                              ),
                              Text(
                                'Assigned: ${DateFormatter.timeAgo(primaryTask.assignedAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  context.push('/worker/tasks/${primaryTask.id}');
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('View Details', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await ResolveTaskDialog.show(context, primaryTask);
                                  if (result == true) {
                                    ref.read(allIncidentsProvider.notifier).refresh();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusResolved,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_circle_outline_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Mark Resolved', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.task_alt_rounded, size: 40, color: AppColors.statusResolved),
                        const SizedBox(height: 10),
                        const Text(
                          'All caught up!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You have no active pending leakage repair assignments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // Live Telemetry for Sector
                const Text(
                  'Assigned Sector Sensor Telemetry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                if (selectedSensor != null)
                  SensorCard(sensor: selectedSensor),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
