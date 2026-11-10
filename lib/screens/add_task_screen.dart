import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/app_colors.dart';
import '../utils/date_helpers.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({this.task, this.onEnableReminders, super.key});

  final TaskItem? task;
  final Future<bool> Function()? onEnableReminders;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _scheduledAt;
  late TaskCategory _category;
  late TaskPriority _priority;
  late DateTime _reminderAt;
  late bool _reminderEnabled;
  String? _reminderError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _scheduledAt = task?.scheduledAt ?? DateTime.now();
    _category = task?.category ?? TaskCategory.personal;
    _priority = task?.priority ?? TaskPriority.medium;
    _reminderAt = task?.reminderAt ?? _defaultReminderTime(_scheduledAt);
    _reminderEnabled = task?.reminderEnabled ?? false;
  }

  DateTime _defaultReminderTime(DateTime scheduledAt) {
    final suggested = scheduledAt.subtract(const Duration(minutes: 10));
    return suggested.isAfter(DateTime.now())
        ? suggested
        : DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() {
        _scheduledAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _scheduledAt.hour,
          _scheduledAt.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (selected != null && mounted) {
      setState(() {
        _scheduledAt = DateTime(
          _scheduledAt.year,
          _scheduledAt.month,
          _scheduledAt.day,
          selected.hour,
          selected.minute,
        );
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _reminderAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() {
        _reminderAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _reminderAt.hour,
          _reminderAt.minute,
        );
        _reminderError = null;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt),
    );
    if (selected != null && mounted) {
      setState(() {
        _reminderAt = DateTime(
          _reminderAt.year,
          _reminderAt.month,
          _reminderAt.day,
          selected.hour,
          selected.minute,
        );
        _reminderError = null;
      });
    }
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    setState(() {
      _reminderEnabled = enabled;
      _reminderError = null;
    });
    if (enabled && widget.onEnableReminders != null) {
      try {
        final granted = await widget.onEnableReminders!();
        if (!granted && mounted) {
          setState(() {
            _reminderError =
                'Notifications are blocked. You can still save the reminder, '
                'but enable notifications in Settings to receive it.';
          });
        }
      } on Object catch (error) {
        if (mounted) setState(() => _reminderError = error.toString());
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderEnabled && !_reminderAt.isAfter(DateTime.now())) {
      setState(() => _reminderError = 'Choose a reminder time in the future.');
      return;
    }

    final task = widget.task;
    Navigator.pop(
      context,
      TaskItem(
        id: task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        scheduledAt: _scheduledAt,
        priority: _priority,
        isCompleted: task?.isCompleted ?? false,
        createdAt: task?.createdAt,
        reminderEnabled: _reminderEnabled,
        reminderAt: _reminderEnabled ? _reminderAt : null,
        notificationId: task?.notificationId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to do?',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('task-title-field'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'e.g. Complete programming assignment',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add a few details (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Category',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final category in TaskCategory.values)
                      ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 17,
                          color: category.color,
                        ),
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: AppColors.secondary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Date and time',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(formatDate(_scheduledAt)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(formatTime(_scheduledAt)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Priority',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final priority in TaskPriority.values)
                      ChoiceChip(
                        avatar: Icon(
                          Icons.flag_rounded,
                          size: 16,
                          color: priority.color,
                        ),
                        label: Text(priority.label),
                        selected: _priority == priority,
                        onSelected: (_) => setState(() => _priority = priority),
                        selectedColor: priority.color.withValues(alpha: 0.14),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  key: const ValueKey('task-reminder-toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable reminder'),
                  subtitle: const Text(
                    'Receive a local notification before this task.',
                  ),
                  value: _reminderEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: _setReminderEnabled,
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reminder date and time',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectReminderDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(formatDate(_reminderAt)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectReminderTime,
                          icon: const Icon(Icons.access_time_rounded),
                          label: Text(formatTime(_reminderAt)),
                        ),
                      ),
                    ],
                  ),
                  if (_reminderError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _reminderError!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('save-task-button'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isEditing ? 'Save changes' : 'Save task'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
