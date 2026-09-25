import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../core/constants/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case IncidentPriority.low:
        color = AppColors.priorityLow;
        break;
      case IncidentPriority.medium:
        color = AppColors.priorityMedium;
        break;
      case IncidentPriority.high:
        color = AppColors.priorityHigh;
        break;
      case IncidentPriority.critical:
        color = AppColors.priorityCritical;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              priority.displayName,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
