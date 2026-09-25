import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/empty_state.dart';

class WorkerTasksScreen extends ConsumerStatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  ConsumerState<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends ConsumerState<WorkerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(workerTasksProvider);
    final activeTasks = tasks.where((t) => t.status == IncidentStatus.assigned).toList();
    final completedTasks = tasks.where((t) => t.status == IncidentStatus.resolved).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Assigned Tasks'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryCyan,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${activeTasks.length})'),
            Tab(text: 'Completed (${completedTasks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Tasks
          activeTasks.isEmpty
              ? const EmptyStateView(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'No pending assigned tasks',
                  message: 'When a municipal officer assigns an incident to you, it will appear here immediately.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeTasks.length,
                  itemBuilder: (context, index) {
                    final task = activeTasks[index];
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

          // Completed Tasks
          completedTasks.isEmpty
              ? const EmptyStateView(
                  icon: Icons.history_rounded,
                  title: 'No completed tasks yet',
                  message: 'Tasks you mark as resolved will be archived in this section.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
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
        ],
      ),
    );
  }
}
