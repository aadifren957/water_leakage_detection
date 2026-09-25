import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/empty_state.dart';

class OfficerIncidentsScreen extends ConsumerStatefulWidget {
  const OfficerIncidentsScreen({super.key});

  @override
  ConsumerState<OfficerIncidentsScreen> createState() => _OfficerIncidentsScreenState();
}

class _OfficerIncidentsScreenState extends ConsumerState<OfficerIncidentsScreen> {
  final _searchController = TextEditingController();
  IncidentStatus? _selectedStatus;
  IncidentPriority? _selectedPriority;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(allIncidentsProvider);

    // Apply search and filters
    final filteredIncidents = incidents.where((inc) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesId = inc.id.toLowerCase().contains(query);
        final matchesDevice = inc.deviceId.toLowerCase().contains(query);
        final matchesLoc = inc.location.toLowerCase().contains(query);
        final matchesZone = inc.zone.toLowerCase().contains(query);
        if (!matchesId && !matchesDevice && !matchesLoc && !matchesZone) {
          return false;
        }
      }

      if (_selectedStatus != null && inc.status != _selectedStatus) {
        return false;
      }

      if (_selectedPriority != null && inc.priority != _selectedPriority) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Water Leakage Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(allIncidentsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, Sensor Node, Location...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${incidents.length})',
                        isSelected: _selectedStatus == null,
                        onSelected: () => setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      ...IncidentStatus.values.map((status) {
                        final count = incidents.where((i) => i.status == status).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: '${status.displayName} ($count)',
                            isSelected: _selectedStatus == status,
                            onSelected: () => setState(() {
                              _selectedStatus = _selectedStatus == status ? null : status;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Incidents List
          Expanded(
            child: filteredIncidents.isEmpty
                ? EmptyStateView(
                    icon: Icons.water_drop_outlined,
                    title: 'No incidents match your criteria',
                    message: 'Try clearing your search query or selecting a different status filter.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      setState(() {
                        _searchController.clear();
                        _selectedStatus = null;
                        _selectedPriority = null;
                      });
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncidentCard(
                          incident: incident,
                          onTap: () {
                            context.push('/officer/incidents/${incident.id}');
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
          ),
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
