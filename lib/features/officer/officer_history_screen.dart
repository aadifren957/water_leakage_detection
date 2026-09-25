import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/empty_state.dart';

class OfficerHistoryScreen extends ConsumerStatefulWidget {
  const OfficerHistoryScreen({super.key});

  @override
  ConsumerState<OfficerHistoryScreen> createState() => _OfficerHistoryScreenState();
}

class _OfficerHistoryScreenState extends ConsumerState<OfficerHistoryScreen> {
  final _searchController = TextEditingController();
  IncidentStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(allIncidentsProvider);
    final resolvedIncidents = incidents.where((i) => i.status == IncidentStatus.resolved).toList();

    // Calculate Average MTTR (Mean Time to Resolution)
    String avgMttr = 'N/A';
    if (resolvedIncidents.isNotEmpty) {
      final totalMinutes = resolvedIncidents.fold<int>(0, (sum, item) {
        if (item.durationToResolution != null) {
          return sum + item.durationToResolution!.inMinutes;
        }
        return sum;
      });
      final avgMinutes = (totalMinutes / resolvedIncidents.length).round();
      avgMttr = DateFormatter.formatDuration(Duration(minutes: avgMinutes));
    }

    // Filtered incidents
    final filtered = incidents.where((inc) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matches = inc.id.toLowerCase().contains(q) ||
            inc.deviceId.toLowerCase().contains(q) ||
            inc.location.toLowerCase().contains(q) ||
            inc.zone.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_selectedStatus != null && inc.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incident Logs & History'),
      ),
      body: Column(
        children: [
          // MTTR Summary Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusResolvedBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppColors.statusResolved, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg. Resolution Time (MTTR)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        avgMttr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Resolved',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      '${resolvedIncidents.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusResolved,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search history by ID, location, sensor...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${incidents.length})', _selectedStatus == null, () {
                    setState(() => _selectedStatus = null);
                  }),
                  const SizedBox(width: 8),
                  ...IncidentStatus.values.map((s) {
                    final c = incidents.where((i) => i.status == s).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip('${s.displayName} ($c)', _selectedStatus == s, () {
                        setState(() => _selectedStatus = _selectedStatus == s ? null : s);
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No historical records found',
                    message: 'Try adjusting your search criteria.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final inc = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncidentCard(
                          incident: inc,
                          onTap: () {
                            context.push('/officer/incidents/${inc.id}');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryNavy : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
