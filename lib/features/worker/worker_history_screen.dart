import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/empty_state.dart';

class WorkerHistoryScreen extends ConsumerStatefulWidget {
  const WorkerHistoryScreen({super.key});

  @override
  ConsumerState<WorkerHistoryScreen> createState() => _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends ConsumerState<WorkerHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(workerTasksProvider);
    final completedTasks = tasks.where((t) => t.status == IncidentStatus.resolved).toList();

    final filtered = completedTasks.where((task) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matches = task.id.toLowerCase().contains(q) ||
            task.location.toLowerCase().contains(q) ||
            task.deviceId.toLowerCase().contains(q) ||
            (task.repairNotes?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Completed History'),
      ),
      body: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search completed tasks & repair logs...',
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
          const Divider(),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No completed tasks found',
                    message: 'When you resolve and close assigned tasks, your resolution logs will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncidentCard(
                          incident: task,
                          showAssignee: false,
                          onTap: () {
                            context.push('/worker/tasks/${task.id}');
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
}
