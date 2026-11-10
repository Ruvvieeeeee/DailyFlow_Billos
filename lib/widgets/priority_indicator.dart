import 'package:flutter/material.dart';

import '../models/task_item.dart';

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 14, color: priority.color),
        const SizedBox(width: 3),
        Text(
          priority.label,
          style: TextStyle(
            color: priority.color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
