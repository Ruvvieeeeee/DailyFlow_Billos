import 'package:flutter/foundation.dart';

import '../models/task_item.dart';
import '../utils/date_helpers.dart';
import 'database_service.dart';
import 'reminder_service.dart';

enum TaskStatusFilter { all, today, upcoming, pending, completed }

enum TaskSortOrder {
  newestFirst,
  oldestFirst,
  highPriorityFirst,
  lowPriorityFirst,
  earliestScheduled,
}

class TaskStatistics {
  const TaskStatistics({
    required this.total,
    required this.completed,
    required this.pending,
    required this.todayTasks,
    required this.todayCompleted,
    required this.todayPending,
    required this.dailyCompletion,
  });

  final int total;
  final int completed;
  final int pending;
  final List<TaskItem> todayTasks;
  final int todayCompleted;
  final int todayPending;
  final double dailyCompletion;
}

List<TaskItem> filterAndSortTasks(
  Iterable<TaskItem> tasks, {
  String query = '',
  TaskStatusFilter status = TaskStatusFilter.all,
  TaskCategory? category,
  TaskPriority? priority,
  TaskSortOrder sortOrder = TaskSortOrder.earliestScheduled,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final normalizedQuery = query.trim().toLowerCase();
  final results = tasks.where((task) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        task.title.toLowerCase().contains(normalizedQuery) ||
        task.description.toLowerCase().contains(normalizedQuery);
    final matchesCategory = category == null || task.category == category;
    final matchesPriority = priority == null || task.priority == priority;
    final matchesStatus = switch (status) {
      TaskStatusFilter.all => true,
      TaskStatusFilter.today => isSameDay(task.scheduledAt, today),
      TaskStatusFilter.upcoming => DateTime(
        task.scheduledAt.year,
        task.scheduledAt.month,
        task.scheduledAt.day,
      ).isAfter(DateTime(today.year, today.month, today.day)),
      TaskStatusFilter.pending => !task.isCompleted,
      TaskStatusFilter.completed => task.isCompleted,
    };
    return matchesQuery && matchesCategory && matchesPriority && matchesStatus;
  }).toList();

  int comparePriority(TaskItem first, TaskItem second) =>
      first.priority.index.compareTo(second.priority.index);

  results.sort((first, second) {
    final comparison = switch (sortOrder) {
      TaskSortOrder.newestFirst =>
        (second.createdAt ?? second.scheduledAt).compareTo(
          first.createdAt ?? first.scheduledAt,
        ),
      TaskSortOrder.oldestFirst =>
        (first.createdAt ?? first.scheduledAt).compareTo(
          second.createdAt ?? second.scheduledAt,
        ),
      TaskSortOrder.highPriorityFirst => comparePriority(second, first),
      TaskSortOrder.lowPriorityFirst => comparePriority(first, second),
      TaskSortOrder.earliestScheduled => first.scheduledAt.compareTo(
        second.scheduledAt,
      ),
    };
    return comparison == 0 ? first.id.compareTo(second.id) : comparison;
  });

  return results;
}

class TaskStore extends ChangeNotifier {
  TaskStore({required this.databaseService, this.reminders});

  final DatabaseService databaseService;
  final ReminderService? reminders;
  List<TaskItem> _tasks = [];
  Future<void>? _initialization;
  bool _isLoading = true;
  bool _isInitialized = false;
  Object? _loadError;
  String? _reminderError;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Object? get loadError => _loadError;
  String? get reminderError => _reminderError;
  String? takeReminderError() {
    final error = _reminderError;
    _reminderError = null;
    return error;
  }

  Future<void> initialize({
    void Function(String taskId)? onNotificationTaskTap,
  }) {
    if (_isInitialized) return Future.value();
    return _initialization ??= _loadTasks(onNotificationTaskTap);
  }

  Future<void> retryInitialization() {
    _initialization = null;
    _isInitialized = false;
    _loadError = null;
    _isLoading = true;
    notifyListeners();
    return initialize();
  }

  Future<void> _loadTasks(
    void Function(String taskId)? onNotificationTaskTap,
  ) async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _tasks = await databaseService.getTasks();
      _isInitialized = true;
      final reminderService = reminders;
      if (reminderService != null) {
        try {
          await reminderService.initialize(onTaskTap: onNotificationTaskTap);
          if (reminderService.notificationsEnabled &&
              reminderService.permissionGranted) {
            _tasks = await _synchronizeAllReminders(_tasks);
          }
        } on Object catch (error) {
          _reminderError = error.toString();
        }
      }
    } on Object catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
      _initialization = null;
    }
  }

  TaskItem? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<TaskItem> addTask(TaskItem task) async {
    _ensureInitialized();
    final databaseId = await databaseService.insertTask(task);
    final inserted = await databaseService.getTaskById('$databaseId');
    if (inserted == null) {
      throw StateError('The newly inserted task could not be retrieved.');
    }
    final savedTask = await _synchronizeReminder(inserted);
    _tasks = [..._tasks, savedTask];
    _notifyChanged();
    return savedTask;
  }

  Future<bool> updateTask(TaskItem task) async {
    _ensureInitialized();
    final updatedRows = await databaseService.updateTask(task);
    if (updatedRows == 0) return false;
    final updatedTask = await databaseService.getTaskById(task.id);
    if (updatedTask == null) {
      throw StateError('The updated task could not be retrieved.');
    }
    _replaceTask(await _synchronizeReminder(updatedTask));
    return true;
  }

  Future<bool> setCompletion(String id, bool isCompleted) async {
    _ensureInitialized();
    final existing = taskById(id);
    if (existing == null || existing.isCompleted == isCompleted) return false;
    final updatedRows = await databaseService.updateCompletion(id, isCompleted);
    if (updatedRows == 0) return false;
    final updatedTask = existing.copyWith(isCompleted: isCompleted);
    _replaceTask(await _synchronizeReminder(updatedTask));
    return true;
  }

  Future<bool> toggleCompletion(String id) async {
    final task = taskById(id);
    if (task == null) return false;
    return setCompletion(id, !task.isCompleted);
  }

  Future<bool> deleteTask(String id) async {
    _ensureInitialized();
    final task = taskById(id);
    if (task != null && reminders != null) {
      try {
        await reminders!.cancelTask(task);
      } on Object catch (error) {
        _reminderError =
            'Task deleted, but its reminder could not be canceled: $error';
      }
    }
    final deletedRows = await databaseService.deleteTask(id);
    if (deletedRows == 0) return false;
    _tasks = _tasks.where((task) => task.id != id).toList();
    _notifyChanged();
    return true;
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    _ensureInitialized();
    final reminderService = reminders;
    if (reminderService == null) return false;
    try {
      if (enabled) {
        final granted = await reminderService.enableNotifications();
        if (!granted) {
          _tasks = await _synchronizeAllReminders(_tasks);
          await reminderService.refreshPermissionStatus();
          _notifyChanged();
          return false;
        }
      } else {
        await reminderService.disableNotifications();
      }
      _tasks = await _synchronizeAllReminders(_tasks);
      await reminderService.refreshPermissionStatus();
      _reminderError = null;
      _notifyChanged();
      return true;
    } on Object catch (error) {
      _reminderError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rescheduleReminders() async {
    _ensureInitialized();
    final reminderService = reminders;
    if (reminderService == null) return;
    try {
      await reminderService.refreshPermissionStatus();
      await reminderService.refreshLocalTimezone();
      _tasks = await _synchronizeAllReminders(_tasks);
      await reminderService.refreshPermissionStatus();
      _notifyChanged();
    } on Object catch (error) {
      _reminderError = error.toString();
      notifyListeners();
    }
  }

  Future<void> clearAllTasks() async {
    _ensureInitialized();
    for (final task in _tasks) {
      if (reminders == null) break;
      try {
        await reminders!.cancelTask(task);
      } on Object catch (error) {
        _reminderError =
            'Local data was cleared, but a reminder could not be canceled: $error';
      }
    }
    await databaseService.deleteAllTasks();
    _tasks = [];
    _notifyChanged();
  }

  TaskStatistics statistics({DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayTasks =
        _tasks.where((task) => isSameDay(task.scheduledAt, today)).toList()
          ..sort(
            (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
          );
    final completed = _tasks.where((task) => task.isCompleted).length;
    final todayCompleted = todayTasks.where((task) => task.isCompleted).length;

    return TaskStatistics(
      total: _tasks.length,
      completed: completed,
      pending: _tasks.length - completed,
      todayTasks: List.unmodifiable(todayTasks),
      todayCompleted: todayCompleted,
      todayPending: todayTasks.length - todayCompleted,
      dailyCompletion: todayTasks.isEmpty
          ? 0
          : todayCompleted / todayTasks.length,
    );
  }

  void _replaceTask(TaskItem updatedTask) {
    _tasks = [
      for (final task in _tasks)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    _notifyChanged();
  }

  Future<TaskItem> _synchronizeReminder(TaskItem task) async {
    final reminderService = reminders;
    if (reminderService == null) return task;
    try {
      final updated = await reminderService.synchronize(task);
      if (updated.notificationId != task.notificationId) {
        await databaseService.updateNotificationId(
          task.id,
          updated.notificationId,
        );
      }

      _reminderError = null;
      return updated;
    } on Object catch (error) {
      _reminderError = error.toString();
      try {
        await databaseService.updateNotificationId(task.id, null);
      } on Object catch (databaseError) {
        _reminderError =
            'Reminder error: $error. Could not update reminder '
            'state in storage: $databaseError';
      }
      return task.copyWith(clearNotificationId: true);
    }
  }

  Future<List<TaskItem>> _synchronizeAllReminders(
    Iterable<TaskItem> tasks,
  ) async {
    final synchronized = <TaskItem>[];
    for (final task in tasks) {
      synchronized.add(await _synchronizeReminder(task));
    }
    return synchronized;
  }

  void _notifyChanged() {
    notifyListeners();
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Tasks cannot be changed before the database is loaded.',
      );
    }
  }
}
