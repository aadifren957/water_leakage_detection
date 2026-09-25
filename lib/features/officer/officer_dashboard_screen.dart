import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/flow_chart.dart';
import '../../widgets/incident_card.dart';

class OfficerDashboardScreen extends ConsumerWidget {
  const OfficerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final stats = ref.watch(incidentStatsProvider);
    final incidents = ref.watch(allIncidentsProvider);
    final sensors = ref.watch(sensorsListProvider);
    final selectedSensor = ref.watch(selectedSensorProvider);

    // Get recent 4 active incidents
    final recentIncidents = incidents.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Header
          SliverToBoxAdapter(
            child: AppHeader(user: user),
          ),

          // Main Dashboard Body
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Demo Tool: Simulate Live Leak Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLightBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Test Demo Flow: Trigger simulated IoT leak alert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(allIncidentsProvider.notifier).simulateNewLeak();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New high-priority leakage detected & dispatched to dashboard!'),
                                backgroundColor: AppColors.statusIdentified,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Simulate Leak', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Metrics Grid (2 columns)
                const Text(
                  'Incident Overview',
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
                        title: 'Total Active Leaks',
                        value: '${stats.totalActive}',
                        icon: Icons.water_drop_outlined,
                        accentColor: AppColors.priorityCritical,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'Identified',
                        value: '${stats.identifiedCount}',
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppColors.statusIdentified,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Acknowledged',
                        value: '${stats.acknowledgedCount}',
                        icon: Icons.visibility_outlined,
                        accentColor: AppColors.statusAcknowledged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'Assigned',
                        value: '${stats.assignedCount}',
                        icon: Icons.person_outline_rounded,
                        accentColor: AppColors.statusAssigned,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'Resolved',
                        value: '${stats.resolvedTodayCount}',
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: AppColors.statusResolved,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Live Sensor Telemetry Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Live IoT Telemetry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ESP8266 Nodes',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (selectedSensor != null) ...[
                  SensorCard(
                    sensor: selectedSensor,
                    availableSensors: sensors,
                    onSensorSelected: (deviceId) {
                      ref.read(selectedSensorIdProvider.notifier).state = deviceId;
                    },
                  ),
                  const SizedBox(height: 12),
                  FlowChart(sensor: selectedSensor),
                ],
                const SizedBox(height: 22),

                // Recent Incidents Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Incidents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/officer/incidents');
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Incident cards
                if (recentIncidents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No active incidents reported.'),
                    ),
                  )
                else
                  ...recentIncidents.map(
                    (incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IncidentCard(
                        incident: incident,
                        onTap: () {
                          context.push('/officer/incidents/${incident.id}');
                        },
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
