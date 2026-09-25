import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final IncidentStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    IconData icon;

    switch (status) {
      case IncidentStatus.identified:
        bg = AppColors.statusIdentifiedBg;
        text = AppColors.statusIdentified;
        border = AppColors.statusIdentifiedBorder;
        icon = Icons.warning_amber_rounded;
        break;
      case IncidentStatus.acknowledged:
        bg = AppColors.statusAcknowledgedBg;
        text = AppColors.statusAcknowledged;
        border = AppColors.statusAcknowledgedBorder;
        icon = Icons.visibility_outlined;
        break;
      case IncidentStatus.assigned:
        bg = AppColors.statusAssignedBg;
        text = AppColors.statusAssigned;
        border = AppColors.statusAssignedBorder;
        icon = Icons.person_outline_rounded;
        break;
      case IncidentStatus.resolved:
        bg = AppColors.statusResolvedBg;
        text = AppColors.statusResolved;
        border = AppColors.statusResolvedBorder;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: text),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: text,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
