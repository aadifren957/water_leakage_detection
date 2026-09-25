import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/incident_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/worker_provider.dart';
import '../../providers/incident_provider.dart';

class AssignWorkerDialog extends ConsumerStatefulWidget {
  final IncidentModel incident;

  const AssignWorkerDialog({
    super.key,
    required this.incident,
  });

  static Future<bool?> show(BuildContext context, IncidentModel incident) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignWorkerDialog(incident: incident),
    );
  }

  @override
  ConsumerState<AssignWorkerDialog> createState() => _AssignWorkerDialogState();
}

class _AssignWorkerDialogState extends ConsumerState<AssignWorkerDialog> {
  String? _selectedWorkerId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-select first available worker if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workers = ref.read(workersListProvider);
      final firstAvailable = workers.where((w) => w.canAcceptTasks).firstOrNull;
      if (firstAvailable != null && mounted) {
        setState(() {
          _selectedWorkerId = firstAvailable.id;
        });
      }
    });
  }

  Future<void> _handleAssign() async {
    if (_selectedWorkerId == null) {
      setState(() {
        _errorMessage = 'Please select a field worker to assign.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(allIncidentsProvider.notifier).assignWorker(
            incidentId: widget.incident.id,
            workerId: _selectedWorkerId!,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Field worker assigned to ${widget.incident.id} successfully!'),
            backgroundColor: AppColors.statusAssigned,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(workersListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Incident Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Field Worker',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${widget.incident.id} • ${widget.incident.zone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.priorityCritical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.priorityCritical.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.priorityCritical,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Text(
                'Available Field Personnel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Workers list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    final isAvailable = worker.canAcceptTasks;
                    final isSelected = _selectedWorkerId == worker.id;

                    return InkWell(
                      onTap: isAvailable
                          ? () {
                              setState(() {
                                _selectedWorkerId = worker.id;
                                _errorMessage = null;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.statusAssignedBg
                              : (isAvailable ? Colors.white : AppColors.background),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.statusAssigned
                                : (isAvailable ? AppColors.border : AppColors.borderLight),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Radio indicator
                            Radio<String>(
                              value: worker.id,
                              groupValue: _selectedWorkerId,
                              activeColor: AppColors.statusAssigned,
                              onChanged: isAvailable
                                  ? (val) {
                                      setState(() {
                                        _selectedWorkerId = val;
                                        _errorMessage = null;
                                      });
                                    }
                                  : null,
                            ),

                            // Avatar
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isAvailable
                                  ? AppColors.primaryNavy.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.2),
                              child: Text(
                                worker.name[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isAvailable ? AppColors.primaryNavy : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Worker details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        worker.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isAvailable ? AppColors.textPrimary : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${worker.id})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Zone: ${worker.zone}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Workload badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isAvailable ? AppColors.statusResolved : AppColors.priorityCritical)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isAvailable ? 'Available' : 'Busy',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isAvailable
                                          ? AppColors.statusResolved
                                          : AppColors.priorityCritical,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${worker.activeTaskCount}/${worker.maxCapacity} tasks',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleAssign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAssigned,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Assignment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
