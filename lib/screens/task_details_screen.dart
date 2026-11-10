import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/app_colors.dart';
import '../utils/date_helpers.dart';
import '../widgets/category_chip.dart';
import '../widgets/priority_indicator.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    required this.task,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final TaskItem task;
  final Future<TaskItem?> Function(TaskItem task) onEdit;
  final Future<void> Function(TaskItem task) onToggle;
  final Future<void> Function(String id) onDelete;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TaskItem _task = widget.task;

  Future<void> _editTask() async {
    final updated = await widget.onEdit(_task);
    if (updated != null && mounted) {
      setState(() => _task = updated);
    }
  }

  Future<void> _deleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        title: const Text('Delete task?'),
        content: Text('"${_task.title}" will be removed from DailyFlow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    try {
      await widget.onDelete(_task.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError('Could not delete task: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            key: const ValueKey('edit-task-button'),
            tooltip: 'Edit task',
            onPressed: _editTask,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const ValueKey('delete-task-button'),
            tooltip: 'Delete task',
            onPressed: _deleteTask,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _task.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: _task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _task.description.isEmpty
                        ? 'No description provided.'
                        : _task.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CategoryChip(category: _task.category),
                      PriorityIndicator(priority: _task.priority),
                    ],
                  ),
                  const Divider(height: 30),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: formatDate(_task.scheduledAt),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: formatTime(_task.scheduledAt),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    value: _task.priority.label,
                    valueColor: _task.priority.color,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: _task.isCompleted
                        ? Icons.task_alt_rounded
                        : Icons.pending_actions_rounded,
                    label: 'Status',
                    value: _task.isCompleted ? 'Completed' : 'Pending',
                    valueColor: _task.isCompleted
                        ? AppColors.success
                        : AppColors.secondaryText,
                  ),
                  if (_task.reminderEnabled && _task.reminderAt != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.notifications_active_outlined,
                      label: 'Reminder',
                      value:
                          '${formatDate(_task.reminderAt!)}, '
                          '${formatTime(_task.reminderAt!)}',
                      valueColor: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _toggleCompletion();
              },
              icon: Icon(
                _task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                _task.isCompleted ? 'Mark as pending' : 'Mark as completed',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCompletion() async {
    final updated = _task.copyWith(isCompleted: !_task.isCompleted);
    try {
      await widget.onToggle(updated);
      if (mounted) setState(() => _task = updated);
    } catch (error) {
      if (mounted) _showError('Could not update task: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.secondaryText),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
