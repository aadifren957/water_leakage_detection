import 'package:flutter/material.dart';
import '../models/timeline_event_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineEventModel> events;

  const TimelineWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text('No timeline activity recorded.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        Color nodeColor;
        IconData nodeIcon;

        switch (event.type) {
          case TimelineEventType.detected:
            nodeColor = AppColors.statusIdentified;
            nodeIcon = Icons.warning_amber_rounded;
            break;
          case TimelineEventType.acknowledged:
            nodeColor = AppColors.statusAcknowledged;
            nodeIcon = Icons.check_rounded;
            break;
          case TimelineEventType.assigned:
            nodeColor = AppColors.statusAssigned;
            nodeIcon = Icons.person_rounded;
            break;
          case TimelineEventType.resolved:
            nodeColor = AppColors.statusResolved;
            nodeIcon = Icons.task_alt_rounded;
            break;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node & Vertical Line
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: nodeColor, width: 2),
                    ),
                    child: Icon(nodeIcon, size: 14, color: nodeColor),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Event Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormatter.formatTime(event.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      if (event.actorName != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.account_circle_outlined,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${event.actorName} (${event.actorRole ?? "Staff"})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
